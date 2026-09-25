const URL = process.env.SUPABASE_URL ?? 'https://pwwrvwtgrtegmrjulxji.supabase.co';
const KEY = process.env.SUPABASE_PUBLISHABLE_KEY ?? 'sb_publishable_mWZUenksN6A1A-sgyC_dqQ_PaNzQZf6';
const TIMEOUT_MS = 20000;

const cases = [
  { query: '야스이', senses: ['S_YASUI_PRICE', 'S_YASUI_EASY'], counts: [12, 1] },
  { query: '야스쿠', senses: ['S_YASUI_PRICE', 'S_YASUI_EASY'] },
  { query: '야스캇타', senses: ['S_YASUI_PRICE', 'S_YASUI_EASY'] },
  { query: '싸다', senses: ['S_YASUI_PRICE'], relation: ['ANTONYM', '타카이'] },
  { query: '쉽다', senses: ['S_YASUI_EASY'] },
  { query: '~야스이', senses: ['S_YASUI_SUFFIX_EASY'], counts: [17] },
  { query: '타베야스이', senses: ['S_YASUI_SUFFIX_EASY'] },
  { query: '타야스이', senses: ['S_TAYASUI_EASY'], counts: [1] },
  { query: '타카이', senses: ['S_TAKAI_PRICE', 'S_TAKAI_HEIGHT', 'S_TAKAI_DEGREE'], counts: [7, 3, 3] },
  { query: '다카이', senses: ['S_TAKAI_PRICE', 'S_TAKAI_HEIGHT', 'S_TAKAI_DEGREE'] },
  { query: '높다', senses: ['S_TAKAI_HEIGHT', 'S_TAKAI_DEGREE'] },
  { query: '비싸다', senses: ['S_TAKAI_PRICE'], relation: ['ANTONYM', '야스이'] }
];

async function search(query) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetch(`${URL}/rest/v1/rpc/search_expression_sense_hub`, {
      method: 'POST',
      headers: { apikey: KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify({ p_query: query, p_limit: 12 }),
      signal: controller.signal
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}: ${await response.text()}`);
    return response.json();
  } finally {
    clearTimeout(timeout);
  }
}

async function associations(expressionIds) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetch(`${URL}/rest/v1/rpc/get_learning_associations`, {
      method: 'POST',
      headers: { apikey: KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify({ p_expression_ids: expressionIds, p_limit_per_group: 24 }),
      signal: controller.signal
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}: ${await response.text()}`);
    return response.json();
  } finally {
    clearTimeout(timeout);
  }
}

const results = await Promise.all(cases.map(async definition => ({ definition, rows: await search(definition.query) })));
let failed = 0;
for (const { definition, rows } of results) {
  const failures = [];
  const actualSenses = rows.map(row => row.sense_key);
  if (JSON.stringify(actualSenses) !== JSON.stringify(definition.senses)) failures.push(`뜻 ${actualSenses.join(', ') || '없음'}`);
  if (definition.counts) {
    const counts = rows.map(row => Array.isArray(row.examples) ? row.examples.length : -1);
    if (JSON.stringify(counts) !== JSON.stringify(definition.counts)) failures.push(`예문 수 ${counts.join(', ')}`);
  }
  if (definition.relation) {
    const [type, pronunciation] = definition.relation;
    if (!rows.some(row => (row.relations ?? []).some(relation => relation.relation_type === type && relation.display_pronunciation === pronunciation))) failures.push(`관계 ${type} ${pronunciation} 없음`);
  }
  if (rows.some(row => (row.examples ?? []).some(example => ['타타카이', '아타타카이'].includes(example.display_pronunciation)))) failures.push('부분 발음 오탐 포함');
  if (failures.length) failed += 1;
  console.log(`${failures.length ? 'FAIL' : 'PASS'} ${definition.query}${failures.length ? ` · ${failures.join(' · ')}` : ` · ${rows.length}개 뜻`}`);
}

const associationCases = [
  { expressionId: 7030, forbidden: ['오스·밀다'] },
  { expressionId: 1580, forbidden: ['하나시 야스이·말하기 편해'] },
  { expressionId: 1582, forbidden: ['하나시 야스이·말하기 편해'] },
  { expressionId: 1583, forbidden: ['하나시 야스이·말하기 편해'] },
  { expressionId: 1584, forbidden: ['하나시 야스이·말하기 편해'] },
  { expressionId: 6159, forbidden: ['이쿠시카 나이·가야지', '요리 음식 맛표현'] }
];
const associationRows = await associations(associationCases.map(item => item.expressionId));
for (const definition of associationCases) {
  const labels = new Set(associationRows
    .filter(row => Number(row.anchor_expression_id) === definition.expressionId)
    .map(row => row.group_label));
  const exposed = definition.forbidden.filter(label => labels.has(label));
  if (exposed.length) failed += 1;
  console.log(`${exposed.length ? 'FAIL' : 'PASS'} 연결 ${definition.expressionId}${exposed.length ? ` · 노출 ${exposed.join(', ')}` : ' · 혼합 그룹 제외'}`);
}

console.log(`SUMMARY ${cases.length + associationCases.length - failed}/${cases.length + associationCases.length} passed`);
if (failed) process.exitCode = 1;
