import assert from 'node:assert/strict';
import { readFile, writeFile } from 'node:fs/promises';
import '../learning-note-utils.js';

const { normalize } = globalThis.KimtokkiLearningNotes;
const url = process.env.SUPABASE_URL || 'https://pwwrvwtgrtegmrjulxji.supabase.co';
const key = process.env.SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_mWZUenksN6A1A-sgyC_dqQ_PaNzQZf6';
assert.match(key, /^sb_publishable_/, '검증은 publishable key를 사용해야 합니다.');
const headers = { apikey: key, 'Content-Type': 'application/json' };
async function api(path, body) {
  const response = await fetch(`${url}/rest/v1/${path}`, { headers, ...(body ? { method: 'POST', body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(30000) });
  assert.equal(response.status, 200, `${path}: ${await (response.ok ? Promise.resolve('') : response.text())}`);
  return response.json();
}

const { cases } = JSON.parse(await readFile(new URL('../tests/study-chat03-search-cases.json', import.meta.url), 'utf8'));
const report = [];
for (const definition of cases) {
  const started = performance.now();
  const notes = await api('rpc/search_learning_notes', { p_query: definition.query, p_limit: 100 });
  const noteRank = notes.findIndex(n => n.title.includes(definition.noteTitle));
  assert.ok(noteRank >= 0 && noteRank < 3, `${definition.query}: 기대 학습노트가 상위 3개에 없습니다.`);
  assert.ok(notes.length <= definition.maxNotes, `${definition.query}: 학습노트 과다 검색 ${notes.length}`);
  let expressionRank = null;
  if (definition.pronunciation) {
    const rows = await api('rpc/search_expressions_expanded', { p_query: definition.query, p_limit: 10 });
    expressionRank = rows.findIndex(r => normalize(r.display_pronunciation) === normalize(definition.pronunciation));
    assert.ok(expressionRank >= 0 && expressionRank < (definition.maxRank || 3), `${definition.query}: 기대 표현이 상위에 없습니다. ${JSON.stringify(rows)}`);
    const expression = rows[expressionRank];
    const links = await api(`learning_note_expression?select=learning_note_id&expression_id=eq.${expression.expression_id}`);
    assert.ok(links.some(l => Number(l.learning_note_id) === Number(notes[noteRank].id)), `${definition.query}: 상세→학습노트 연결 누락`);
    const detail = await api(`learning_note?select=id,source_key,content_text&id=eq.${notes[noteRank].id}`);
    assert.ok(detail[0]?.content_text.length > 50, '공개 본문 열기 실패');
  }
  const item = { query: definition.query, type: definition.type, expressionRank: expressionRank === null ? null : expressionRank + 1, noteRank: noteRank + 1, noteCount: notes.length, elapsedMs: Math.round(performance.now() - started) };
  report.push(item);
  console.log(`PASS ${JSON.stringify(item)}`);
}

const imported = await api('learning_note?select=id,source_key,content_text,status&source_key=like.study-chat-03:*');
assert.equal(imported.length, 15);
assert.equal(new Set(imported.map(n => n.source_key)).size, imported.length);
assert.equal(imported.filter(n => n.content_text.includes('자료 구분: 재구성 보완')).length, 3);
assert.equal(imported.filter(n => n.content_text.includes('자료 구분: 원문 보존')).length, 12);
const linked = await api(`learning_note_expression?select=learning_note_id,expression_id&learning_note_id=in.(${imported.map(n => n.id).join(',')})`);
assert.equal(linked.length, 88);
assert.equal(new Set(linked.map(l => l.learning_note_id)).size, 15);
const expressions = await api(`expression?select=id,display_pronunciation&id=in.(${[...new Set(linked.map(l => l.expression_id))].join(',')})`);
assert.equal(expressions.length, 88);
assert.ok(expressions.every(e => /[가-힣]/.test(e.display_pronunciation)), '한글 발음 누락');
assert.ok(expressions.every(e => !['데카이스루', '쿄오다이세에부츠'].includes(normalize(e.display_pronunciation))), '미확정 청취 표현이 확정 데이터에 등록됨');
console.log(`SUMMARY ${cases.length}/${cases.length} search cases; 15 notes / 88 links / 88 expressions; public API PASS`);
if (process.env.STUDY_CHAT03_REPORT) await writeFile(process.env.STUDY_CHAT03_REPORT, JSON.stringify({ report, notes: imported.length, links: linked.length, expressions: expressions.length }, null, 2));
