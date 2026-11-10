(function (root) {
  'use strict';
  const normalize = value => String(value ?? '').toLocaleLowerCase().replace(/[^0-9a-z가-힣ぁ-んァ-ヶ一-龯]/gu, '');
  function provenance(note) {
    const key = String(note.source_key || '');
    const chat = key.match(/^study-chat-(\d+)(?:[-:]|$)/)?.[1];
    const explicit = String(note.content_text || '').match(/^자료 구분: (.+)$/m)?.[1];
    const kind = explicit || (key.includes('-supplement-') ? '재구성 보완' : key.includes('-preserved-') ? '원문 보존' : '학습 정리');
    return `${chat ? `일어수집${chat} · ` : ''}${kind}`;
  }
  root.KimtokkiLearningNotes = { normalize, provenance };
})(globalThis);
