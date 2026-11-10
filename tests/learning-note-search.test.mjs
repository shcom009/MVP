import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const migration = readFileSync(
  new URL('../supabase/migrations/20261108102000_restrict_learning_note_search_dependencies.sql', import.meta.url),
  'utf8'
);
const correctionMigration = readFileSync(
  new URL('../supabase/migrations/20261108100000_extend_learning_note_search.sql', import.meta.url),
  'utf8'
);
const aliasSearchMigration = readFileSync(
  new URL('../supabase/migrations/20261108101000_normalize_alias_search.sql', import.meta.url),
  'utf8'
);

test('학습노트 검색은 연결 표현의 일본어·발음·뜻까지 찾는다', () => {
  assert.match(migration, /learning_note_expression lne/);
  assert.match(migration, /expression_meaning em/);
  assert.doesNotMatch(migration, /search_alias sa/);
  assert.match(migration, /e\.japanese_original/);
  assert.match(migration, /e\.display_pronunciation/);
  assert.match(migration, /em\.meaning_text/);
});

test('잘못 들은 쿄오카 발음을 고도 표현의 검색 별칭으로 보존한다', () => {
  assert.match(correctionMigration, /코코 쿄오카 다카이/);
  assert.match(correctionMigration, /코코, 효오코오가 타카이/);
  assert.match(correctionMigration, /'PRONUNCIATION'/);
  assert.match(correctionMigration, /'RAW_NOTE'/);
});

test('검색 별칭은 공백과 문장부호를 제거한 발음도 정확 일치로 비교한다', () => {
  assert.match(aliasSearchMigration, /q_compact/);
  assert.match(aliasSearchMigration, /regexp_replace\(lower\(sa\.alias_norm\)/);
  assert.match(aliasSearchMigration, /when alias_exact then 'PRON_EXACT'/);
});
