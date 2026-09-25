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
console.log(`SUMMARY ${cases.length - failed}/${cases.length} passed`);
if (failed) process.exitCode = 1;
