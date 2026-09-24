import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

const html=readFileSync(new URL('../nihongo-hub.html',import.meta.url),'utf8');
const current=readFileSync(new URL('../nihongo.html',import.meta.url),'utf8');

test('기존 화면과 분리된 실제 데이터 탐색 허브를 제공한다',()=>{
  assert.match(html,/김토끼니혼고 · 탐색 허브/);
  assert.match(html,/search_expressions_expanded/);
  assert.match(html,/get_learning_associations/);
  assert.match(html,/search_source_memos/);
  assert.match(html,/href="\.\/nihongo\.html"/);
});

test('카드별 복습·즐겨찾기 없이 연결 방향과 중심 이동을 제공한다',()=>{
  for(const label of ['검색·활용','뜻으로','상황으로','발음으로','원문'])assert.ok(html.includes(label));
  assert.match(html,/function focusExpression\(/);
  assert.match(html,/data-expression-id/);
  assert.doesNotMatch(html,/favorite-toggle|review-toggle/);
});

test('같은 원문 그룹은 학습 연결에서 분리한다',()=>{
  assert.match(html,/String\(item\.group_type\)==="SOURCE_MEMO"/);
  assert.match(html,/학습 관계로 섞지 않고 원문 근거로만 구분/);
});

test('정규 표현이 없어도 원본 메모 결과를 직접 보여 준다',()=>{
  assert.match(html,/function renderSourceOnly\(/);
  assert.match(html,/if\(sources\.length\)renderSourceOnly\(q,sources\)/);
});

test('카테고리에서 불러온 표현도 새 중심으로 이동할 수 있다',()=>{
  assert.match(html,/const knownRows=new Map\(\)/);
  assert.match(html,/knownRows\.set\(saved\.expression_id,saved\)/);
});

test('기존 화면 파일은 기존 기능을 유지한다',()=>{
  assert.match(current,/id="detailReviewBtn"/);
  assert.match(current,/id="detailFavoriteBtn"/);
  assert.match(current,/search_expressions_expanded/);
});
