import assert from 'node:assert/strict';
import { readFileSync, statSync } from 'node:fs';
import { test } from 'node:test';
import vm from 'node:vm';

const html = readFileSync(new URL('../nihongo.html', import.meta.url), 'utf8');
const referenceImage = new URL('../mockup-hero-exact.png', import.meta.url);
const script = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];
assert.ok(script, 'inline application script exists');
new vm.Script(script);

test('확정 시안 이미지를 그대로 사용하며 문구와 학습 동작을 유지한다', () => {
  assert.ok(statSync(referenceImage).size > 100000, '원본 시안에서 손실 없이 분리한 PNG가 포함되어 있다');
  assert.ok(statSync(new URL('../mockup-wordmark-exact.png', import.meta.url)).size > 10000);
  assert.ok(statSync(new URL('../mockup-detail-rabbit.png', import.meta.url)).size > 10000);
  assert.match(html, /class="reference-art" src="\.\/mockup-hero-exact\.png"/);
  assert.match(html, /\.app:has\(\.status:not\(\[hidden\]\)\) \.welcome-art\{display:none\}/);
  assert.match(html, /한번 오면 빠져나갈 수 없다/);
  assert.match(html, /내 맘대로<br \/>일본어/);
  assert.match(html, /환영<br class="sticker-mobile-break" \/>해요!/);
  assert.doesNotMatch(html, /일본 여행의 든든한 일본어 친구/);
  assert.match(html, /data-home-action="recent"/);
  assert.match(html, /data-home-action="review"/);
  assert.match(html, /data-home-action="favorite"/);
  assert.doesNotMatch(html, /data-home-action="(?:search|category|story)"/);
  assert.match(html, /id="categoryMoreBtn"[^>]*aria-controls="categoryStrip"/);
  assert.match(html, /categoryStrip\.classList\.toggle\("expanded"\)/);
  assert.match(html, /id="detailReviewBtn"/);
  assert.match(html, /id="detailFavoriteBtn"/);
  assert.match(html, /data-quick-kind="\$\{kind\}"/);
});

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
const backupDeclarations = script.match(/function createLearningBackup\(\)[\s\S]*?(?=    function formSubtypeLabel\()/)?.[0];
assert.ok(backupDeclarations, 'backup functions exist');

const weather = { expression_id: 1, meaning_text: '날씨', display_pronunciation: '텐키' };
const sunny = { expression_id: 2, meaning_text: '맑음', display_pronunciation: '하레' };

function setup({ review = [], favorite = [] } = {}) {
  const saved = new Map();
  const homeCounts = Object.fromEntries(['homeRecentCount', 'homeReviewCount', 'homeFavoriteCount'].map(id => [id, { textContent: '' }]));
  const context = vm.createContext({
    document: { getElementById: id => homeCounts[id] ?? null },
    localStorage: {
      getItem: key => saved.get(key) ?? null,
      setItem: (key, value) => saved.set(key, value),
      removeItem: key => saved.delete(key)
    },
    REVIEW_STORAGE_KEY: 'review', FAVORITE_STORAGE_KEY: 'favorite',
    BACKUP_KIND: 'kimtokki-learning-backup', BACKUP_VERSION: 1, BACKUP_MAX_ROWS: 5000,
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
    paintResults() {}, setFavoriteButton() {}, setReviewButton() {}
  });
  vm.runInContext(`${declarations}\n${backupDeclarations}`, context);
  return { context, saved, homeCounts };
}

test('첫 화면의 학습 건수가 기존 학습 목록과 함께 갱신된다', () => {
  const { context, homeCounts } = setup({ review: [weather], favorite: [sunny] });
  context.recentRows = [weather, sunny];
  context.updateLearningCounts();
  assert.deepEqual(Object.values(homeCounts).map(badge => badge.textContent), ['2', '1', '1']);
  context.toggleReview(weather);
  assert.equal(homeCounts.homeReviewCount.textContent, '0');
});

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

test('복습 체크와 즐겨찾기는 충분한 터치 영역을 갖고 작은 화면에서 본문과 분리된다', () => {
  const mobile = html.split('\n').find(line => line.includes('@media(max-width:430px)'));
  assert.ok(html.includes('width:44px;height:44px'), '44px buttons');
  assert.ok(html.includes('.review-toggle::before{content:"+"'), 'unselected review icon');
  assert.ok(html.includes('.review-toggle.active::before{content:"✓"'), 'selected review icon');
  assert.ok(mobile?.includes('.result{padding-bottom:56px}'), 'separate action area');
  assert.ok(mobile?.includes('.result>.review-toggle,.result>.favorite-toggle{top:auto;bottom:8px}'));
  assert.ok(mobile?.includes('.detail-main>.review-toggle,.detail-main>.favorite-toggle{top:auto;bottom:10px}'));
});

test('Story 탭은 주제별·엣지·기타 순서이고 주제별이 처음 열린다', () => {
  const tabs = html.match(/<div id="storyTabs" class="story-tabs">([\s\S]*?)<\/div>/)?.[1];
  assert.ok(tabs);
  const buttons = [...tabs.matchAll(/<button class="story-tab( active)?"[^>]*data-story-group="([^"]+)">([^<]+)<\/button>/g)]
    .map(([, active, group, label]) => ({ active: Boolean(active), group, label }));
  assert.deepEqual(buttons, [
    { active: true, group: 'dialogue', label: '주제별' },
    { active: false, group: 'edge', label: '엣지' },
    { active: false, group: 'other', label: '기타' }
  ]);
  assert.match(script, /storyGroup="dialogue"/);
  assert.match(script, /if\(story\.story_only\)return "edge"/);
});

test('Story를 읽고 돌아오면 목록 위치를 복원하고 새 목록에서는 맨 위에서 시작한다', async () => {
  const source = ['showStoryList', 'showStory'].map(name => {
    const prefix = name === 'showStory' ? 'async function ' : 'function ';
    const line = script.split('\n').find(value => value.trimStart().startsWith(`${prefix}${name}(`));
    assert.ok(line, `${name} exists`);
    return line;
  }).join('\n');
  const storySheet = { scrollTop: 420 };
  const storyList = { _hidden: false, get hidden() { return this._hidden; }, set hidden(value) {
    this._hidden = value;
    if (value) storySheet.scrollTop = 0; // 짧은 주제별 본문은 목록을 숨기는 즉시 스크롤이 0으로 제한된다.
  } };
  const context = vm.createContext({
    storyBackBtn: { hidden: true, focus() {} },
    storyHeading: { textContent: '' }, storyTabs: { hidden: false },
    storyReader: { hidden: true, textContent: '' }, storyList,
    storySheet, storyLoaded: true, paintStories() {},
    stories: [{ id: 1, title: '(주제-친구관계)', story_text: '짧은 본문' }]
  });
  vm.runInContext(`let storyListScrollTop=0,storyHistoryActive=false;\n${source}`, context);
  await context.showStory(1);
  assert.equal(context.storySheet.scrollTop, 0);
  context.showStoryList();
  assert.equal(context.storySheet.scrollTop, 420);
  context.showStoryList();
  assert.equal(context.storySheet.scrollTop, 0);
});

test('기기 뒤로가기는 Story 본문→목록→닫기 순서로 이동하고 닫기는 기록을 남기지 않는다', async () => {
  const names = ['showStoryList', 'showStory', 'openStoryBrowser', 'closeStoryBrowser', 'requestStoryList', 'requestCloseStory', 'handleStoryPopState'];
  const source = names.map(name => {
    const prefix = name === 'showStory' ? 'async function ' : 'function ';
    const line = script.split('\n').find(value => value.trimStart().startsWith(`${prefix}${name}(`));
    assert.ok(line, `${name} exists`);
    return line;
  }).join('\n');
  const states = [{ kimtokkiStory: 'stale-from-reload' }];
  let index = 0;
  let context;
  const history = {
    state: states[index],
    pushState(state) { states.splice(++index); states[index] = state; this.state = state; },
    back() { this.go(-1); },
    go(delta) { index += delta; this.state = states[index]; context.handleStoryPopState(); }
  };
  const storySheet = { scrollTop: 420 };
  const storyList = { _hidden: false, get hidden() { return this._hidden; }, set hidden(value) {
    this._hidden = value;
    if (value) storySheet.scrollTop = 0;
  } };
  const storyBackdrop = { hidden: true };
  context = vm.createContext({
    history, storyBackdrop, storySheet, storyList,
    storyReader: { hidden: true, textContent: '' }, storyBackBtn: { hidden: true, focus() {} },
    storyHeading: { textContent: '' }, storyTabs: { hidden: false }, storyCloseBtn: { focus() {} },
    storyLoaded: true, paintStories() {}, dismissQuickPopover() {}, app: { inert: false },
    document: { activeElement: null, body: { style: {} } },
    stories: [{ id: 1, title: '(주제-친구관계)', story_text: '짧은 본문' }]
  });
  vm.runInContext(`let storyListScrollTop=0,storyHistoryActive=false,storyTrigger=null,storyHistoryToken=null;\n${source}`, context);
  context.openStoryBrowser();
  storySheet.scrollTop = 420;
  await context.showStory(1);
  assert.equal(history.state.kimtokkiStoryReader, 1);
  history.back();
  assert.equal(storySheet.scrollTop, 420);
  assert.equal(storyBackdrop.hidden, false);
  await context.showStory(1);
  context.requestStoryList();
  assert.equal(storySheet.scrollTop, 420);
  assert.equal(history.state.kimtokkiStoryReader, null);
  await context.showStory(1);
  context.requestCloseStory();
  assert.equal(storyBackdrop.hidden, true);
  assert.equal(index, 0);
  assert.match(script, /storyBackBtn\.addEventListener\("click",requestStoryList\)/);
});

test('백업에는 복습·즐겨찾기만 들어가고 최근 본 표현은 제외된다', () => {
  const { context } = setup({ review: [weather], favorite: [sunny] });
  context.recentRows = [weather];
  const backup = JSON.parse(JSON.stringify(context.createLearningBackup()));
  assert.equal(backup.kind, 'kimtokki-learning-backup');
  assert.equal(backup.version, 1);
  assert.deepEqual(backup.review, [weather]);
  assert.deepEqual(backup.favorite, [sunny]);
  assert.equal('recent' in backup, false);
});

test('가져오기는 기존 목록을 유지하고 중복 표현은 추가하지 않는다', () => {
  const { context, saved } = setup({ review: [weather], favorite: [sunny] });
  const backup = { kind: 'kimtokki-learning-backup', version: 1, review: [weather, sunny, sunny], favorite: [sunny, weather] };
  const result = context.restoreLearningBackup(JSON.stringify(backup));
  assert.equal(result.reviewAdded, 1);
  assert.equal(result.favoriteAdded, 1);
  assert.deepEqual(JSON.parse(saved.get('review')), [weather, sunny]);
  assert.deepEqual(JSON.parse(saved.get('favorite')), [sunny, weather]);
  assert.equal(context.reviewCount.textContent, '2');
  assert.equal(context.favoriteCount.textContent, '2');
});

test('형식이 다르거나 표현이 잘못된 파일은 목록을 수정하지 않는다', () => {
  const { context, saved } = setup({ review: [weather] });
  assert.throws(() => context.restoreLearningBackup('{}'), /백업 파일이 아닙니다/);
  assert.throws(() => context.restoreLearningBackup('{broken'), /읽을 수 없습니다/);
  assert.throws(() => context.restoreLearningBackup(JSON.stringify({
    kind: 'kimtokki-learning-backup', version: 1, review: [{ ...sunny, expression_id: -2 }], favorite: []
  })), /잘못된 표현/);
  assert.equal(context.reviewRows.length, 1);
  assert.equal(saved.size, 0);
});

test('저장 실패 시 메모리 목록과 이전 복습 저장값을 유지한다', () => {
  const { context, saved } = setup({ review: [weather] });
  saved.set('review', JSON.stringify([weather]));
  const setItem = context.localStorage.setItem;
  context.localStorage.setItem = (key, value) => {
    if (key === 'favorite') throw new Error('quota');
    setItem(key, value);
  };
  assert.throws(() => context.restoreLearningBackup(JSON.stringify({
    kind: 'kimtokki-learning-backup', version: 1, review: [sunny], favorite: [sunny]
  })), /저장하지 못했습니다/);
  assert.deepEqual(JSON.parse(saved.get('review')), [weather]);
  assert.equal(context.reviewRows.length, 1);
  assert.equal(context.favoriteRows.length, 0);
});

test('메뉴에 내보내기·가져오기 동작과 파일 선택창이 있다', () => {
  assert.match(html, /id="exportBackupBtn"/);
  assert.match(html, /id="importBackupBtn"/);
  assert.match(html, /id="backupFileInput"[^>]*type="file"/);
  assert.match(html, /복습·즐겨찾기만 백업합니다/);
});
