import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const DEFAULT_URL = 'https://pwwrvwtgrtegmrjulxji.supabase.co';
const DEFAULT_KEY = 'sb_publishable_mWZUenksN6A1A-sgyC_dqQ_PaNzQZf6';
const CONTRACT_URL = new URL('../tests/search-regression-cases.json', import.meta.url);

export function normalize(value) {
  return String(value ?? '').toLowerCase().replace(/[^0-9a-z가-힣ぁ-んァ-ヶ一-龠]/gu, '');
}

function matchesExpected(row, expected) {
  return (!expected.meaning || row.meaning_text === expected.meaning)
    && (!expected.pronunciation || row.display_pronunciation === expected.pronunciation)
    && (!expected.matchType || row.match_type === expected.matchType);
}

export function validateContract(contract) {
  const failures = [];
  if (contract.version !== 1) failures.push('계약 version은 1이어야 합니다.');
  if (!Number.isInteger(contract.queryLimit) || contract.queryLimit < 1 || contract.queryLimit > 50) failures.push('queryLimit 범위가 잘못되었습니다.');
  if (!Number.isInteger(contract.associationLimit) || contract.associationLimit < 1 || contract.associationLimit > 50) failures.push('associationLimit 범위가 잘못되었습니다.');
  if (!Number.isFinite(contract.warnRequestMs) || contract.warnRequestMs < 1000 || contract.warnRequestMs >= contract.maxRequestMs) failures.push('warnRequestMs 범위가 잘못되었습니다.');
  if (!Number.isFinite(contract.maxRequestMs) || contract.maxRequestMs < 1000) failures.push('maxRequestMs가 너무 작습니다.');
  const queries = (contract.cases ?? []).map(item => item.query);
  if (new Set(queries).size !== queries.length) failures.push('대표 검색어가 중복되었습니다.');
  const required = ['오바상', '괴물', '오니', '지칸', '아이쇼', '토모다치', '히로우', '키쿠'];
  if (required.some(query => !queries.includes(query)) || queries.length !== required.length) failures.push('대표 검색어 8개 구성이 달라졌습니다.');
  for (const item of contract.cases ?? []) {
    if (!item.top?.meaning || !item.top?.pronunciation || !item.top?.matchType) failures.push(`${item.query}: 최상위 기준이 불완전합니다.`);
    if (!Number.isInteger(item.minResults) || !Number.isInteger(item.maxResults) || item.minResults < 1 || item.minResults > item.maxResults) failures.push(`${item.query}: 결과 건수 범위가 잘못되었습니다.`);
    for (const relation of item.associations ?? []) {
      if (!relation.anchor?.meaning || !relation.anchor?.pronunciation || !relation.label || !(relation.requiredMembers?.length > 0)) failures.push(`${item.query}: 연관 기준이 불완전합니다.`);
      if ((contract.forbiddenAssociationLabels ?? []).includes(relation.label)) failures.push(`${item.query}: 금지된 일반 연관 라벨을 기대값으로 사용할 수 없습니다.`);
    }
  }
  return failures;
}

export function validateCase(definition, results, associations, forbiddenLabels = []) {
  const failures = [];
  if (results.length < definition.minResults || results.length > definition.maxResults) failures.push(`결과 ${results.length}개가 허용 범위 ${definition.minResults}~${definition.maxResults}개를 벗어났습니다.`);
  if (!results[0] || !matchesExpected(results[0], definition.top)) failures.push(`최상위 결과가 ${definition.top.meaning} · ${definition.top.pronunciation}이 아닙니다.`);
  for (const expected of definition.requiredResults ?? []) if (!results.some(row => matchesExpected(row, expected))) failures.push(`필수 검색 결과 ${expected.meaning ?? ''} · ${expected.pronunciation ?? ''}가 없습니다.`);
  const resultKeys = results.map(row => `${normalize(row.display_pronunciation)}|${normalize(row.meaning_text)}`);
  if (new Set(resultKeys).size !== resultKeys.length) failures.push('같은 발음과 뜻의 검색 결과가 중복되었습니다.');

  for (const expected of definition.associations ?? []) {
    const anchor = results.find(row => matchesExpected(row, expected.anchor));
    if (!anchor) {
      failures.push(`연관 기준 표현 ${expected.anchor.meaning} · ${expected.anchor.pronunciation}이 검색 결과에 없습니다.`);
      continue;
    }
    const rows = associations.filter(row => Number(row.anchor_expression_id) === Number(anchor.expression_id) && row.group_label === expected.label);
    if (!rows.length) {
      failures.push(`연관 그룹 ${expected.label}이 없습니다.`);
      continue;
    }
    if (forbiddenLabels.includes(expected.label)) failures.push(`일반 라벨 ${expected.label}은 사용할 수 없습니다.`);
    for (const member of expected.requiredMembers) if (!rows.some(row => matchesExpected(row, member))) failures.push(`${expected.label}: 필수 구성원 ${member.meaning ?? ''} · ${member.pronunciation ?? ''}가 없습니다.`);
    const memberKeys = rows.map(row => `${normalize(row.display_pronunciation)}|${normalize(row.meaning_text)}`);
    if (new Set(memberKeys).size !== memberKeys.length) failures.push(`${expected.label}: 같은 발음과 뜻의 구성원이 중복되었습니다.`);
    const hasExplicitOrder = rows.every(row => Number.isFinite(Number(row.display_order)));
    for (let index = 1; index < rows.length; index += 1) {
      const previous = rows[index - 1];
      const current = rows[index];
      const previousLevel = Number(previous.association_level);
      const currentLevel = Number(current.association_level);
      const previousOrder = Number(previous.display_order);
      const currentOrder = Number(current.display_order);
      if (!hasExplicitOrder
          && Number.isFinite(previousLevel) && Number.isFinite(currentLevel)
          && previousLevel > currentLevel) {
        failures.push(`${expected.label}: 연관 단계 우선순위가 뒤바뀌었습니다.`);
        break;
      }
      if (hasExplicitOrder && previousOrder > currentOrder) {
        failures.push(`${expected.label}: 명시된 표시 순서가 뒤바뀌었습니다.`);
        break;
      }
    }
  }
  return failures;
}

async function rpc(url, key, name, body, maxRequestMs) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), maxRequestMs);
  const started = performance.now();
  try {
    const response = await fetch(`${url}/rest/v1/rpc/${name}`, {
      method: 'POST',
      headers: { apikey: key, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: controller.signal
    });
    if (!response.ok) throw new Error(`${name} HTTP ${response.status}: ${await response.text()}`);
    return { rows: await response.json(), elapsedMs: Math.round(performance.now() - started) };
  } finally {
    clearTimeout(timeout);
  }
}

export async function runRegression(contract, options = {}) {
  const url = options.url ?? process.env.SUPABASE_URL ?? DEFAULT_URL;
  const key = options.key ?? process.env.SUPABASE_PUBLISHABLE_KEY ?? DEFAULT_KEY;
  const report = [];
  for (const definition of contract.cases) {
    let search;
    let association;
    try {
      search = await rpc(url, key, 'search_expressions', { p_query: definition.query, p_limit: contract.queryLimit }, contract.maxRequestMs);
    } catch (error) {
      throw new Error(`${definition.query}: 검색 요청 실패 - ${error.message}`, { cause: error });
    }
    const ids = [...new Set(search.rows.map(row => Number(row.expression_id)).filter(Number.isFinite))];
    try {
      association = ids.length
        ? await rpc(url, key, 'get_learning_associations', { p_expression_ids: ids, p_limit_per_group: contract.associationLimit }, contract.maxRequestMs)
        : { rows: [], elapsedMs: 0 };
    } catch (error) {
      throw new Error(`${definition.query}: 연관 요청 실패 - ${error.message}`, { cause: error });
    }
    const failures = validateCase(definition, search.rows, association.rows, contract.forbiddenAssociationLabels ?? []);
    const warnings = [];
    if (search.elapsedMs > contract.warnRequestMs) warnings.push(`검색 요청 ${search.elapsedMs}ms`);
    if (association.elapsedMs > contract.warnRequestMs) warnings.push(`연관 요청 ${association.elapsedMs}ms`);
    report.push({ query: definition.query, resultCount: search.rows.length, associationRowCount: association.rows.length, searchMs: search.elapsedMs, associationMs: association.elapsedMs, warnings, failures });
  }
  return report;
}

async function main() {
  const contract = JSON.parse(await readFile(CONTRACT_URL, 'utf8'));
  const contractFailures = validateContract(contract);
  if (contractFailures.length) throw new Error(contractFailures.join('\n'));
  if (process.argv.includes('--contract-only')) {
    console.log(`PASS contract ${contract.cases.length}/${contract.cases.length}`);
    return;
  }
  const report = await runRegression(contract);
  for (const item of report) console.log(`${item.failures.length ? 'FAIL' : 'PASS'} ${item.query} 결과 ${item.resultCount} · 연관 ${item.associationRowCount} · 검색 ${item.searchMs}ms · 연관 ${item.associationMs}ms${item.warnings.length ? ` · WARN ${item.warnings.join(', ')}` : ''}${item.failures.length ? `\n  - ${item.failures.join('\n  - ')}` : ''}`);
  const failed = report.filter(item => item.failures.length);
  console.log(`SUMMARY ${report.length - failed.length}/${report.length} passed`);
  if (failed.length) process.exitCode = 1;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === fileURLToPath(new URL(`file://${process.argv[1]}`))) main().catch(error => { console.error(error); process.exitCode = 1; });
