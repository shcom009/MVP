import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const sql = readFileSync(new URL('../supabase/migrations/20260923010000_add_aku_aiteru_learning_material.sql', import.meta.url), 'utf8');
const readingFix = readFileSync(new URL('../supabase/migrations/20260923013000_distinguish_aku_and_suku_readings.sql', import.meta.url), 'utf8');

test('아쿠 기본형과 아이테루 활용·예문을 함께 추가한다', () => {
  for (const text of ['空く', '空いている', '空いてる', '明日の夜、空いてる？', 'この席、空いてる？', '明日の午後、空いてる？', '明日の夜、会える？']) {
    assert.ok(sql.includes(text));
  }
});

test('잘못 들은 발음과 자연스러운 표현을 모두 검색 별칭으로 보존한다', () => {
  assert.ok(sql.includes('아시타 요루니 아이테루'));
  assert.ok(sql.includes('아시타노 요루 아이테루'));
  assert.ok(sql.includes('SOURCE_VARIANT'));
});

test('활용·사용 상황·만남 제안을 서로 다른 관계로 연결한다', () => {
  assert.equal((sql.match(/"group_key":"STUDY_CHAT:/g) ?? []).length, 3);
  assert.ok(sql.includes('아쿠·아이테루'));
  assert.ok(sql.includes('시간·자리 비다'));
  assert.ok(sql.includes('시간 확인·만남 제안'));
});

test('아이테루와 스이테루의 같은 표기·다른 읽기를 분리한다', () => {
  assert.ok(readingFix.includes('아쿠·스쿠 구분'));
  assert.ok(readingFix.includes('한산하다는 뜻은 스이테루로 읽는다'));
  assert.ok(readingFix.includes('"pronunciation":"스쿠"'));
  assert.ok(readingFix.includes('"pronunciation":"스이테이루"'));
});
