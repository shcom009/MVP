import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const sql = readFileSync(new URL('../supabase/migrations/20260922210000_import_study_chat_learning_materials.sql', import.meta.url), 'utf8');

test('일어수집 원문은 네이버 메모와 분리된 출처로 적재한다', () => {
  assert.match(sql, /'CHAT_일어수집'/);
  assert.match(sql, /'김토끼니혼고\/일어수집'/);
  assert.match(sql, /'ChatGPT 공유대화 일어수집'/);
  assert.match(sql, /'STUDY_CHAT_VERIFIED'/);
  assert.doesNotMatch(sql, /legacy_folder_id[^;]*'NAVER_MEMO'/s);
});

test('확정 후보 52건과 보류 후보 1건을 구분한다', () => {
  const active = [...sql.matchAll(/"state": "ACTIVE"/g)];
  const hold = [...sql.matchAll(/"state": "HOLD"/g)];
  assert.equal(active.length, 52);
  assert.equal(hold.length, 1);
  assert.match(sql, /"key": "HONMAZUI"/);
  assert.match(sql, /'STUDY_CHAT:HONMAZUI'.*'HOLD'/s);
  assert.match(sql, /operational_exposure='BLOCKED'/);
});

test('사용자가 잘못 들은 발음은 검색 별칭으로 보존한다', () => {
  for (const alias of [
    '와타시노 키와 키와라나이요',
    '코노 아타리데 겟코데스',
    '고지츠키',
    '잇테 쿠레테 이이'
  ]) assert.match(sql, new RegExp(alias));
  assert.match(sql, /SOURCE_VARIANT/);
});

test('직접 비교 가치가 있는 표현만 10개 연관 그룹으로 연결한다', () => {
  const groups = [...sql.matchAll(/"group_key": "STUDY_CHAT:/g)];
  assert.equal(groups.length, 10);
  assert.match(sql, /"label": "기세·페이스"/);
  assert.match(sql, /"label": "왜 웃었어"/);
  assert.doesNotMatch(sql, /STUDY_CHAT:FAREWELL_MIXED/);
});
