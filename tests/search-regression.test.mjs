import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { validateCase, validateContract } from '../scripts/run-search-regression.mjs';

const contract = JSON.parse(readFileSync(new URL('./search-regression-cases.json', import.meta.url), 'utf8'));

test('대표 검색어 8개와 운영 한계값이 완전하다', () => {
  assert.deepEqual(validateContract(contract), []);
  assert.deepEqual(contract.cases.map(item => item.query), ['오바상', '괴물', '오니', '지칸', '아이쇼', '토모다치', '히로우', '키쿠']);
});

test('신규 데이터가 늘어도 핵심 검색 결과와 연관 관계를 유지하면 통과한다', () => {
  const definition = contract.cases.find(item => item.query === '히로우');
  const results = [
    { expression_id: 1, meaning_text: '줍다', display_pronunciation: '히로우', match_type: 'PRON_EXACT' },
    { expression_id: 2, meaning_text: '넓다', display_pronunciation: '히로이', match_type: 'FUZZY' },
    { expression_id: 3, meaning_text: '줍고 가다', display_pronunciation: '히롯테 이쿠', match_type: 'PRON_PARTIAL' }
  ];
  const associations = [{ anchor_expression_id: 1, group_label: '줍다·버리다', meaning_text: '버리다', display_pronunciation: '스테루', association_level: 1 }];
  assert.deepEqual(validateCase(definition, results, associations, contract.forbiddenAssociationLabels), []);
});

test('최상위 결과 변경과 필수 연관 누락은 실패한다', () => {
  const definition = contract.cases.find(item => item.query === '히로우');
  const failures = validateCase(definition, [{ expression_id: 2, meaning_text: '넓다', display_pronunciation: '히로이', match_type: 'PRON_EXACT' }], [], contract.forbiddenAssociationLabels);
  assert.ok(failures.some(message => message.includes('최상위 결과')));
  assert.ok(failures.some(message => message.includes('연관 기준 표현')));
});

test('같은 발음과 뜻의 중복은 실패하지만 긴 표현 우선 노출만으로는 실패하지 않는다', () => {
  const definition = contract.cases.find(item => item.query === '히로우');
  const results = [{ expression_id: 1, meaning_text: '줍다', display_pronunciation: '히로우', match_type: 'PRON_EXACT' }];
  const associations = [
    { anchor_expression_id: 1, group_label: '줍다·버리다', meaning_text: '버리는 중이에요', display_pronunciation: '스테테 이루 토코로데스', association_level: 1, display_order: 1 },
    { anchor_expression_id: 1, group_label: '줍다·버리다', meaning_text: '버리다', display_pronunciation: '스테루', association_level: 1, display_order: 2 },
    { anchor_expression_id: 1, group_label: '줍다·버리다', meaning_text: '버리다', display_pronunciation: '스테루', association_level: 1, display_order: 2 }
  ];
  const failures = validateCase(definition, results, associations, contract.forbiddenAssociationLabels);
  assert.ok(failures.some(message => message.includes('중복')));
  assert.ok(!failures.some(message => message.includes('긴 표현')));
  assert.ok(!failures.some(message => message.includes('표시 순서')));
});

test('명시 순서를 우선하고, 명시 순서가 없을 때 연관 단계를 검사한다', () => {
  const definition = contract.cases.find(item => item.query === '히로우');
  const results = [{ expression_id: 1, meaning_text: '줍다', display_pronunciation: '히로우', match_type: 'PRON_EXACT' }];
  const levelFailures = validateCase(definition, results, [
    { anchor_expression_id: 1, group_label: '줍다·버리다', meaning_text: '버리다', display_pronunciation: '스테루', association_level: 2 },
    { anchor_expression_id: 1, group_label: '줍다·버리다', meaning_text: '버리는 중이에요', display_pronunciation: '스테테 이루 토코로데스', association_level: 1 }
  ], contract.forbiddenAssociationLabels);
  assert.ok(levelFailures.some(message => message.includes('연관 단계')));

  const explicitOrderWins = validateCase(definition, results, [
    { anchor_expression_id: 1, group_label: '줍다·버리다', meaning_text: '버리다', display_pronunciation: '스테루', association_level: 2, display_order: 1 },
    { anchor_expression_id: 1, group_label: '줍다·버리다', meaning_text: '버리는 중이에요', display_pronunciation: '스테테 이루 토코로데스', association_level: 1, display_order: 2 }
  ], contract.forbiddenAssociationLabels);
  assert.ok(!explicitOrderWins.some(message => message.includes('연관 단계')));

  const orderFailures = validateCase(definition, results, [
    { anchor_expression_id: 1, group_label: '줍다·버리다', meaning_text: '버리다', display_pronunciation: '스테루', association_level: 1, display_order: 2 },
    { anchor_expression_id: 1, group_label: '줍다·버리다', meaning_text: '버리는 중이에요', display_pronunciation: '스테테 이루 토코로데스', association_level: 1, display_order: 1 }
  ], contract.forbiddenAssociationLabels);
  assert.ok(orderFailures.some(message => message.includes('표시 순서')));
});
