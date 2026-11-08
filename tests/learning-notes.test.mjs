import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const root = new URL('../', import.meta.url);
const html = readFileSync(new URL('nihongo.html', root), 'utf8');
const schema = readFileSync(new URL('supabase/migrations/20261108090000_add_learning_notes.sql', root), 'utf8');
const indexMigration = readFileSync(new URL('supabase/migrations/20261108093000_index_learning_note_source.sql', root), 'utf8');
const associationOptimization = readFileSync(new URL('supabase/migrations/20261108094000_prefilter_dynamic_learning_associations.sql', root), 'utf8');
const noteSearchExtension = readFileSync(new URL('supabase/migrations/20261108100000_extend_learning_note_search.sql', root), 'utf8');
const report = readFileSync(new URL('김토끼니혼고_학습노트원문도입_V1.0.md', root), 'utf8');
const supplementReport = readFileSync(new URL('김토끼니혼고_학습노트원문보완_V1.1.md', root), 'utf8');

test('긴 원문은 기존 짧은 note와 분리된 읽기 전용 학습노트로 제공한다', () => {
  assert.match(schema, /create table if not exists public\.learning_note \(/);
  assert.match(schema, /create table if not exists public\.learning_note_expression \(/);
  assert.match(schema, /alter table public\.learning_note enable row level security/);
  assert.match(schema, /to anon, authenticated\s+using \(status = 'ACTIVE'\)/);
  assert.match(schema, /search_learning_notes/);
});

test('원문 적재 결과는 공개 저장소에 원문을 복제하지 않고 건수로 기록한다', () => {
  assert.match(report, /원문 28건, 핵심 표현 30건, 연결 37건/);
  assert.match(report, /CHATGPT_STUDY_CHAT/);
  assert.match(indexMigration, /learning_note_source_memo_idx/);
  assert.match(associationOptimization, /display_pronunciation % a\.display_pronunciation/);
});

test('앱에서 학습노트를 검색하고 표현 상세에서 원문으로 이동한다', () => {
  assert.match(html, /data-story-group="notes">학습노트/);
  assert.match(html, /id="noteSearchForm"/);
  assert.match(html, /learning_note\?select=id,title,summary,topic,source_order,content_text/);
  assert.match(html, /learning_note_expression\?select=learning_note_id,relation_type,display_order/);
  assert.match(html, /data-learning-notes="1"/);
  assert.match(html, /function openLinkedLearningNote\(noteId\)/);
});

test('학습노트 검색은 본문뿐 아니라 연결된 표현의 뜻도 사용한다', () => {
  assert.match(noteSearchExtension, /learning_note_expression lne/);
  assert.match(noteSearchExtension, /expression_meaning em/);
  assert.match(noteSearchExtension, /search_alias sa/);
});

test('일어수집02 보완 범위와 기존 데이터 재사용을 기록한다', () => {
  assert.match(supplementReport, /학습노트 9건, 신규 표현 15건, 기존 표현 재사용 3건, 연결 20건/);
  assert.match(supplementReport, /활성 학습노트 37건/);
  assert.match(supplementReport, /현재 대화 컨텍스트/);
  assert.match(supplementReport, /완전 복원되었다고 간주하지 않는다/);
});
