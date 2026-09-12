import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import vm from 'node:vm';

const html = readFileSync(new URL('../nihongo.html', import.meta.url), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
assert.ok(script, 'inline application script exists');
new vm.Script(script);

const declarations = [
  'compactRow', 'readStoredRows', 'writeStoredRows', 'escapeHtml',
  'isReviewed', 'isFavorite', 'updateLearningCounts',
  'setFavoriteButton', 'toggleFavorite', 'toggleReview',
  'shuffleRows', 'renderLearningList', 'startReview',
  'renderReviewCard', 'rateReview'
].map(name => {
  const line = script.split('\n').find(value => value.trimStart().startsWith(`function ${name}(`));
  assert.ok(line, `${name} exists`);
  return line;
}).join('\n');

const weather = { expression_id: 1, meaning_text: '날씨', display_pronunciation: '텐키' };
const sunny = { expression_id: 2, meaning_text: '맑음', display_pronunciation: '하레' };

function setup({ review = [], favorite = [] } = {}) {
  const saved = new Map();
  const context = vm.createContext({
    localStorage: {
      getItem: key => saved.get(key) ?? null,
      setItem: (key, value) => saved.set(key, value)
    },
    REVIEW_STORAGE_KEY: 'review', FAVORITE_STORAGE_KEY: 'favorite',
    reviewRows: review.map(row => ({ ...row })),
    favoriteRows: favorite.map(row => ({ ...row })),
    recentRows: [], currentRows: [], currentDetailRow: null,
    learningBackdrop: { hidden: true },
    learningBackBtn: { hidden: false },
    learningHeading: { textContent: '' },
    learningContent: { innerHTML: '' },
    recentCount: { textContent: '' },
    reviewCount: { textContent: '' },
    favoriteCount: { textContent: '' },
    drawerReviewStart: { disabled: false },
    paintResults() {}, setFavoriteButton() {}
  });
  vm.runInContext(declarations, context);
  return { context, saved };
}

test('기억함은 복습 목록에서만 제거하고 즐겨찾기는 남긴다', () => {
  const { context, saved } = setup({ review: [weather], favorite: [weather] });
  context.startReview();
  context.rateReview('remember');
  assert.equal(context.reviewRows.length, 0);
  assert.equal(context.favoriteRows.length, 1);
  assert.equal(JSON.parse(saved.get('review')).length, 0);
  assert.equal(context.reviewCount.textContent, '0');
  assert.equal(context.favoriteCount.textContent, '1');
  assert.equal(context.drawerReviewStart.disabled, true);
  assert.match(context.learningContent.innerHTML, /복습 완료/);
});

test('다시 보기는 남고 다음 회차에서 기억함을 누르면 제거된다', () => {
  const { context, saved } = setup({ review: [weather] });
  context.startReview();
  context.rateReview('again');
  assert.equal(context.reviewRows.length, 1);
  assert.equal(context.reviewSession.round, 2);
  assert.match(context.learningContent.innerHTML, /2회차/);
  context.rateReview('remember');
  assert.equal(context.reviewRows.length, 0);
  assert.deepEqual(JSON.parse(saved.get('review')), []);
});

test('중간에 기억한 표현은 제외하고 다시 보기 표현만 재출제한다', () => {
  const { context } = setup({ review: [weather, sunny] });
  context.startReview();
  const firstId = context.reviewSession.deck[0].expression_id;
  context.rateReview('remember');
  assert.equal(context.reviewRows.length, 1);
  assert.notEqual(context.reviewRows[0].expression_id, firstId);
  context.rateReview('again');
  assert.equal(context.reviewSession.round, 2);
  assert.equal(context.reviewSession.deck.length, 1);
  assert.notEqual(context.reviewSession.deck[0].expression_id, firstId);
});

test('즐겨찾기는 추가와 제거가 복습 목록에 영향을 주지 않는다', () => {
  const { context, saved } = setup({ review: [weather] });
  context.toggleFavorite(weather);
  assert.equal(context.favoriteRows.length, 1);
  assert.equal(context.reviewRows.length, 1);
  assert.equal(context.isFavorite(weather.expression_id), true);
  context.renderLearningList('favorite');
  assert.match(context.learningContent.innerHTML, /즐겨찾기에서 제외/);
  context.toggleFavorite(weather);
  assert.equal(context.favoriteRows.length, 0);
  assert.equal(context.reviewRows.length, 1);
  assert.deepEqual(JSON.parse(saved.get('favorite')), []);
});

test('기존 복습 저장값은 유지하고 즐겨찾기 저장값은 별도로 읽는다', () => {
  const { context, saved } = setup();
  saved.set('review', JSON.stringify([weather]));
  saved.set('favorite', JSON.stringify([sunny]));
  assert.equal(context.readStoredRows('review')[0].expression_id, 1);
  assert.equal(context.readStoredRows('favorite')[0].expression_id, 2);
});

test('화면에 즐겨찾기 버튼과 메뉴가 존재한다', () => {
  assert.match(html, /id="detailFavoriteBtn"/);
  assert.match(html, /id="favoriteCount"/);
  assert.match(html, /data-library="favorite"/);
  assert.match(html, /favoriteButton\)\{toggleFavorite\(currentRows\[index\]\)/);
});
