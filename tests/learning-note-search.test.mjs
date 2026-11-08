import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const migration = readFileSync(
  new URL('../supabase/migrations/20261108100000_extend_learning_note_search.sql', import.meta.url),
  'utf8'
);
const aliasSearchMigration = readFileSync(
  new URL('../supabase/migrations/20261108101000_normalize_alias_search.sql', import.meta.url),
  'utf8'
);

test('학습노트 검색은 연결 표현의 뜻과 검색 별칭까지 찾는다', () => {
  assert.match(migration, /learning_note_expression lne/);
  assert.match(migration, /expression_meaning em/);
  assert.match(migration, /search_alias sa/);
  assert.match(migration, /em\.meaning_text/);
  assert.match(migration, /sa\.alias_text/);
});

test('잘못 들은 쿄오카 발음을 고도 표현의 검색 별칭으로 보존한다', () => {
  assert.match(migration, /코코 쿄오카 다카이/);
  assert.match(migration, /코코, 효오코오가 타카이/);
  assert.match(migration, /'PRONUNCIATION'/);
  assert.match(migration, /'RAW_NOTE'/);
});

test('검색 별칭은 공백과 문장부호를 제거한 발음도 정확 일치로 비교한다', () => {
  assert.match(aliasSearchMigration, /q_compact/);
  assert.match(aliasSearchMigration, /regexp_replace\(lower\(sa\.alias_norm\)/);
  assert.match(aliasSearchMigration, /when alias_exact then 'PRON_EXACT'/);
});
