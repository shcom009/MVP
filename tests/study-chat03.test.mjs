import test from 'node:test';
import assert from 'node:assert/strict';
import '../learning-note-utils.js';
const { normalize, provenance } = globalThis.KimtokkiLearningNotes;

test('표기 차이는 공백·문장부호를 제거해 같은 검색어로 처리한다', () => {
  assert.equal(normalize('하나시가, 치가우다로오！'), normalize('하나시가치가우다로오'));
  assert.equal(normalize('야라나캬 이케나이'), normalize('야라나캬이케나이'));
  assert.equal(normalize(''), '');
});
test('일어수집03 재구성과 원문 발췌를 일어수집02 원문으로 오표시하지 않는다', () => {
  assert.equal(provenance({ source_key: 'study-chat-03:iru', content_text: '자료 구분: 재구성 보완(질문만 확보)' }), '일어수집03 · 재구성 보완(질문만 확보)');
  assert.equal(provenance({ source_key: 'study-chat-03:giant', content_text: '자료 구분: 원문 보존(답변 발췌)' }), '일어수집03 · 원문 보존(답변 발췌)');
  assert.equal(provenance({ source_key: 'study-chat-02-supplement-20261108:001' }), '일어수집02 · 재구성 보완');
  assert.equal(provenance({ source_key: 'study-chat-02-preserved-20261006:001' }), '일어수집02 · 원문 보존');
  assert.equal(provenance({}), '학습 정리');
});
