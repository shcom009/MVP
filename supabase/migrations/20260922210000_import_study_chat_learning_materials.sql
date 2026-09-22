-- Import approved learning material from the ChatGPT project conversation "일어수집".
-- The source remains separate from NAVER_MEMO through legacy_folder_id/source snapshots.
-- Generated examples and weakly related suggestions are intentionally excluded.

select pg_advisory_xact_lock(hashtext('kimtokki_study_chat_import_v1'));

create temporary table _study_source on commit drop as
select * from jsonb_to_recordset($json$[
  {
    "pair": 1,
    "memo_seq": -20260905153041,
    "source_ref": "conversation:2026-09-05T15:30:41.531Z",
    "user_input": "히토츠 이이카이, 하나 물어봐도 돼?",
    "summary": "一ついいかい？ (히토츠 이이카이?) = 하나 물어봐도 돼?, 한 가지 괜찮을까?"
  },
  {
    "pair": 2,
    "memo_seq": -20260905155613,
    "source_ref": "conversation:2026-09-05T15:56:13.294Z",
    "user_input": "소노 초시데 (その調子で)  뜻: \"그 상태로 (계속 해)\", \"그 기세로\"\n\n1. 이게 일상·애니메이션에서 훨씬 더 자주 나오는 표현이에요. 응원할 때 정말 많이 씁니다.\n2. 예: その調子で頑張って (소노 초시데 간밧테) = \"그 기세로 힘내\"\n\n소노 이키데 (その息で)  뜻: \"그 기세로\", \"그 리듬으로 (계속 해)\"\n\n1. 상대방이 잘하고 있을 때 응원하거나 격려하는 말이에요. 운동 경기나 전투 장면에서 \"그 페이스 유지해!\", \"그대로 밀어붙여!\"",
    "summary": "その調子で (소노 초-시데) = 그 페이스로 계속해\nその意気で (소노 이키데) = 그 기세로, 바로 그 정신으로"
  },
  {
    "pair": 3,
    "memo_seq": -20260905165650,
    "source_ref": "conversation:2026-09-05T16:56:50.006Z",
    "user_input": "쿠치노 헤라나이야츠다",
    "summary": "口の減らないやつだ (쿠치노 헤라나이 야츠다) = 한마디도 안 지는 녀석이네"
  },
  {
    "pair": 4,
    "memo_seq": -20260905172908,
    "source_ref": "conversation:2026-09-05T17:29:08.751Z",
    "user_input": "**1. 나니고토니모 호도가 아루 (何事にも程がある)**\n\n- 뜻: \"무슨 일이든 정도가 있다\"\n- 가장 기본적이고 널리 쓰이는 표현\n\n**2. 소레니모 호도가 아루 (それにも程がある)**\n\n- 뜻: \"그것도 정도가 있다\" / \"그건 너무 심하다\"\n- 상대방의 특정 행동을 지적할 때 씀\n\n**3. 후자케루노모 호도가 아루 (ふざけるのも程がある)**\n\n- 뜻: \"장난치는 것도 정도가 있다\"\n- 상대가 장난이 지나칠 때 쓰는 표현 (애니메이션에서 자주 등장)\n\n**4. 호도호도니 시로 (程々にしろ / 程々にして)**\n\n- 뜻: \"적당히 해\", \"정도껏 해\"\n- 명령형으로 직접적으로 \"그만 좀 해\"라는 뉘앙스\n\n**5. 호도가 아루데쇼 (程があるでしょう)**\n\n- 뜻: \"정도가 있잖아\", \"적당히 좀 해야지\"\n- 어이없어하며 타이르는 느낌, 구어체에서 매우 자주 사용",
    "summary": "何事にも程がある (나니고토니모 호도가 아루) = 무슨 일이든 정도가 있다\nそれにも程がある (소레니모 호도가 아루) = 그것도 정도가 있다, 그건 너무 심하다\nふざけるのも程がある (후자케루노모 호도가 아루) = 장난도 정도껏 해야지\n程々にしろ (호도호도니 시로) = 정도껏 해\n程々にして (호도호도니 시테) = 적당히 좀 해"
  },
  {
    "pair": 5,
    "memo_seq": -20260905175632,
    "source_ref": "conversation:2026-09-05T17:56:32.392Z",
    "user_input": "라시쿠나이",
    "summary": "らしくない (라시쿠나이) = 답지 않다, 평소답지 않다"
  },
  {
    "pair": 6,
    "memo_seq": -20260906085418,
    "source_ref": "conversation:2026-09-06T08:54:18.280Z",
    "user_input": "와타시노 키와 키와라나이요",
    "summary": "私の気は変わらないよ (와타시노 키와 카와라나이요) = 내 마음은 변하지 않아, 내 생각은 바뀌지 않아"
  },
  {
    "pair": 7,
    "memo_seq": -20260906091032,
    "source_ref": "conversation:2026-09-06T09:10:32.525Z",
    "user_input": "멘고, 미안",
    "summary": "めんご (멘고) = 미안, 미안미안"
  },
  {
    "pair": 8,
    "memo_seq": -20260906095555,
    "source_ref": "conversation:2026-09-06T09:55:55.388Z",
    "user_input": "보코보코니 스룬다",
    "summary": "ボコボコにするんだ (보코보코니 스룬다) = 흠씬 패버리는 거야, 완전히 박살내는 거야"
  },
  {
    "pair": 9,
    "memo_seq": -20260913133257,
    "source_ref": "conversation:2026-09-13T13:32:57.142Z",
    "user_input": "혼마즈이",
    "summary": "혼마즈이는 문맥 없이는 확정할 수 없어 보류. ほんま、むずい / ほんま、まずい 등 재검토 필요."
  },
  {
    "pair": 10,
    "memo_seq": -20260913133350,
    "source_ref": "conversation:2026-09-13T13:33:50.137Z",
    "user_input": "혼마즈이(ほんまずい / 本気ヤバい 또는 本気でマズい)는 일본의 젊은 층(MZ세대, 갸루 등)이나 인터넷에서 쓰이는 은어(신조어)",
    "summary": "혼마즈이는 문맥 없이는 확정할 수 없어 보류. ほんま、むずい / ほんま、まずい 등 재검토 필요."
  },
  {
    "pair": 11,
    "memo_seq": -20260913133509,
    "source_ref": "conversation:2026-09-13T13:35:09.242Z",
    "user_input": "정말 심심하네, 정말 재미없네 라는 의미로도 쓰이나",
    "summary": "혼마즈이는 문맥 없이는 확정할 수 없어 보류. ほんま、むずい / ほんま、まずい 등 재검토 필요."
  },
  {
    "pair": 12,
    "memo_seq": -20260918152342,
    "source_ref": "conversation:2026-09-18T15:23:42.110Z",
    "user_input": "나기사,물가",
    "summary": "渚 (나기사) = 물가, 해변"
  },
  {
    "pair": 13,
    "memo_seq": -20260919053745,
    "source_ref": "conversation:2026-09-19T05:37:45.256Z",
    "user_input": "애지중지한 이유가 있었네요 일본어로",
    "summary": "大事にしてた理由があったんですね (다이지니 시테타 리유-가 앗탄데스네) = 애지중지한 이유가 있었네요\n可愛がってた理由があったんですね (카와이갓테타 리유-가 앗탄데스네) = 예뻐하고 아낀 이유가 있었네요"
  },
  {
    "pair": 14,
    "memo_seq": -20260919053818,
    "source_ref": "conversation:2026-09-19T05:38:18.346Z",
    "user_input": "예뻐한 이유를 알겠네요",
    "summary": "可愛がってた理由がわかりました (카와이갓테타 리유-가 와카리마시타) = 예뻐한 이유를 알겠네요"
  },
  {
    "pair": 15,
    "memo_seq": -20260919084437,
    "source_ref": "conversation:2026-09-19T08:44:37.403Z",
    "user_input": "취미를 바꾸세요",
    "summary": "趣味を変えてください (슈미오 카에테 쿠다사이) = 취미를 바꾸세요\n趣味変えたら？ (슈미 카에타라?) = 취미 바꾸는 게 어때?"
  },
  {
    "pair": 16,
    "memo_seq": -20260919140332,
    "source_ref": "conversation:2026-09-19T14:03:32.256Z",
    "user_input": "なんて少しだけ夢をみてしまっただけ",
    "summary": "なんて少しだけ夢を見てしまっただけ (난테 스코시다케 유메오 미테시맛타다케) = 그런 꿈을 잠깐 꾸었을 뿐이야"
  },
  {
    "pair": 17,
    "memo_seq": -20260919140605,
    "source_ref": "conversation:2026-09-19T14:06:05.821Z",
    "user_input": "약간 기대를 품었을 뿐이야, 잠깐 꿈을 꿨을 뿐이야, 라는 의미로 평소에 쓰는 말은?",
    "summary": "ちょっと期待しただけ (춋토 키타이시타 다케) = 조금 기대했을 뿐이야\nちょっと夢見てただけ (춋토 유메 미테타 다케) = 잠깐 꿈꿨을 뿐이야"
  },
  {
    "pair": 18,
    "memo_seq": -20260919140859,
    "source_ref": "conversation:2026-09-19T14:08:59.069Z",
    "user_input": "つま先",
    "summary": "つま先 (츠마사키) = 발끝, 발가락 끝부분"
  },
  {
    "pair": 19,
    "memo_seq": -20260919141045,
    "source_ref": "conversation:2026-09-19T14:10:45.916Z",
    "user_input": "裸足",
    "summary": "裸足 (하다시) = 맨발, 맨발로"
  },
  {
    "pair": 21,
    "memo_seq": -20260919141843,
    "source_ref": "conversation:2026-09-19T14:18:43.903Z",
    "user_input": "足跡を辿って",
    "summary": "足跡を辿って (아시아토오 타돗테) = 발자국·흔적을 따라가며"
  },
  {
    "pair": 22,
    "memo_seq": -20260919151055,
    "source_ref": "conversation:2026-09-19T15:10:55.663Z",
    "user_input": "쿠치쿠세, 말버릇",
    "summary": "口癖 (쿠치구세) = 말버릇, 입버릇, 자주 하는 말"
  },
  {
    "pair": 23,
    "memo_seq": -20260919151328,
    "source_ref": "conversation:2026-09-19T15:13:28.166Z",
    "user_input": "오레니와 와카라나이요",
    "summary": "俺には分からないよ (오레니와 와카라나이요) = 나로서는 모르겠어"
  },
  {
    "pair": 24,
    "memo_seq": -20260919151525,
    "source_ref": "conversation:2026-09-19T15:15:25.478Z",
    "user_input": "몸에 익을 때까지 한다",
    "summary": "身につくまでやる (미니 츠쿠마데 야루) = 몸에 익을 때까지 한다\n体が覚えるまでやる (카라다가 오보에루마데 야루) = 몸이 기억할 때까지 한다"
  },
  {
    "pair": 25,
    "memo_seq": -20260919152011,
    "source_ref": "conversation:2026-09-19T15:20:11.503Z",
    "user_input": "나니모나이난테 신지라레루카",
    "summary": "何もないなんて信じられるか (나니모 나이 난테 신지라레루카) = 아무것도 없다니 믿을 수 있겠어?"
  },
  {
    "pair": 26,
    "memo_seq": -20260919152332,
    "source_ref": "conversation:2026-09-19T15:23:32.181Z",
    "user_input": "예정을 바꾸자, 서두르는게 좋겠어",
    "summary": "予定を変えよう (요테이오 카에요-) = 예정을 바꾸자\n急いだほうがいい (이소이다 호-가 이이) = 서두르는 게 좋겠어"
  },
  {
    "pair": 27,
    "memo_seq": -20260919153832,
    "source_ref": "conversation:2026-09-19T15:38:32.877Z",
    "user_input": "미에스기다요",
    "summary": "見えすぎだよ (미에스기다요) = 너무 잘 보여, 너무 많이 보여"
  },
  {
    "pair": 28,
    "memo_seq": -20260919161314,
    "source_ref": "conversation:2026-09-19T16:13:14.713Z",
    "user_input": "하트가 많은 모양이네, 하트가 많은가 보네",
    "summary": "ハートが多いみたいだね (하-토가 오오이 미타이다네) = 하트가 많은가 보네"
  },
  {
    "pair": 29,
    "memo_seq": -20260919163121,
    "source_ref": "conversation:2026-09-19T16:31:21.347Z",
    "user_input": "아까는 왜 웃었어요?",
    "summary": "さっきはなんで笑ったんですか？ (삿키와 난데 와랏탄데스카?) = 아까는 왜 웃었어요?"
  },
  {
    "pair": 30,
    "memo_seq": -20260919163152,
    "source_ref": "conversation:2026-09-19T16:31:52.968Z",
    "user_input": "반말표현. 삿키와 난데 와랏탄다이? 아까는 왜 웃었어?",
    "summary": "さっき、なんで笑ったの？ (삿키, 난데 와랏타노?) = 아까 왜 웃었어?\nさっきはなんで笑ったんだい？ (삿키와 난데 와랏탄다이?) = 아까는 왜 웃었니?"
  },
  {
    "pair": 31,
    "memo_seq": -20260919163429,
    "source_ref": "conversation:2026-09-19T16:34:29.508Z",
    "user_input": "이런게 재미있는건가?",
    "summary": "こういうのが面白いのかな？ (코-이우노가 오모시로이노카나?) = 이런 게 재미있는 건가?"
  },
  {
    "pair": 32,
    "memo_seq": -20260919163457,
    "source_ref": "conversation:2026-09-19T16:34:57.556Z",
    "user_input": "타노시이를 사용하면?",
    "summary": "こういうのが楽しいの？ (코-이우노가 타노시이노?) = 이런 걸 하는 게 즐거워?"
  },
  {
    "pair": 33,
    "memo_seq": -20260919165307,
    "source_ref": "conversation:2026-09-19T16:53:07.344Z",
    "user_input": "내일 걱정은 내일,",
    "summary": "明日のことは明日考えよう (아시타노 코토와 아시타 칸가에요-) = 내일 일은 내일 생각하자"
  },
  {
    "pair": 34,
    "memo_seq": -20260919165343,
    "source_ref": "conversation:2026-09-19T16:53:43.307Z",
    "user_input": "'아삿테노 코토'라고 하면 어떤 뉘앙스가 되나",
    "summary": "あさってのこと (아삿테노 코토) = 모레 일, 모레에 관한 것"
  },
  {
    "pair": 35,
    "memo_seq": -20260919165803,
    "source_ref": "conversation:2026-09-19T16:58:03.161Z",
    "user_input": "콘나 야리카타 타다시쿠 나이요, 이런 방식은 잘못됐어",
    "summary": "こんなやり方、正しくないよ (콘나 야리카타, 타다시쿠나이요) = 이런 방식은 잘못됐어"
  },
  {
    "pair": 36,
    "memo_seq": -20260919170725,
    "source_ref": "conversation:2026-09-19T17:07:25.675Z",
    "user_input": "키니이라나이네",
    "summary": "気に入らないね (키니 이라나이네) = 마음에 안 드네"
  },
  {
    "pair": 37,
    "memo_seq": -20260919172032,
    "source_ref": "conversation:2026-09-19T17:20:32.956Z",
    "user_input": "약속 시간이 될 때까지 잘게요. 약속 시간까지 잘게요.",
    "summary": "約束の時間になるまで寝ます (야쿠소쿠노 지칸니 나루마데 네마스) = 약속 시간이 될 때까지 잘게요\n約束の時間まで寝ます (야쿠소쿠노 지칸마데 네마스) = 약속 시간까지 잘게요"
  },
  {
    "pair": 38,
    "memo_seq": -20260920001041,
    "source_ref": "conversation:2026-09-20T00:10:41.304Z",
    "user_input": "오이테테이이",
    "summary": "置いてていい？ (오이테테 이이?) = 그대로 놔둬도 돼?"
  },
  {
    "pair": 39,
    "memo_seq": -20260920001247,
    "source_ref": "conversation:2026-09-20T00:12:47.616Z",
    "user_input": "물건, 음식, 상황에 따른 의미",
    "summary": "置いてていい？의 물건·음식·상태별 쓰임을 보충 설명한 후속 질문."
  },
  {
    "pair": 40,
    "memo_seq": -20260920001515,
    "source_ref": "conversation:2026-09-20T00:15:15.286Z",
    "user_input": "코노 아타리데 겟코데스, 이 근처에 세워주세요",
    "summary": "この辺りで結構です (코노 아타리데 켓코-데스) = 이 근처면 됩니다\nこの辺で結構です (코노 헨데 켓코-데스) = 여기쯤이면 됩니다"
  },
  {
    "pair": 41,
    "memo_seq": -20260920003627,
    "source_ref": "conversation:2026-09-20T00:36:27.430Z",
    "user_input": "인사도 없이 가는거야? 보면 미련만 남아",
    "summary": "挨拶もしないで行くの？ (아이사츠모 시나이데 이쿠노?) = 인사도 없이 가는 거야?\n会ったら未練が残るだけ (앗타라 미렌가 노코루다케) = 보면 미련만 남아"
  },
  {
    "pair": 42,
    "memo_seq": -20260920004235,
    "source_ref": "conversation:2026-09-20T00:42:35.436Z",
    "user_input": "고지츠키, 억지",
    "summary": "こじつけ (코지츠케) = 억지, 억지로 갖다 붙인 논리"
  },
  {
    "pair": 43,
    "memo_seq": -20260920004315,
    "source_ref": "conversation:2026-09-20T00:43:15.320Z",
    "user_input": "잇테 쿠레테 이이, 여기 머물러도 돼. 여기 있어도 돼",
    "summary": "ここにいていい (코코니 이테 이이) = 여기 있어도 돼, 여기 머물러도 돼"
  }
]$json$::jsonb) as x(
  pair integer, memo_seq bigint, source_ref text, user_input text, summary text
);

create temporary table _study_candidate on commit drop as
select * from jsonb_to_recordset($json$[
  {
    "pair": 1,
    "key": "HITOTSU_IIKAI",
    "legacy_key": "CHAT-20260905-153041-HITOTSU-IIKAI",
    "jp": "一ついいかい？",
    "pronunciation": "히토츠 이이카이?",
    "meaning": "하나 물어봐도 돼?, 한 가지 괜찮을까?",
    "usage_note": "부드러운 남성 질문형이며, 일상에서는 다소 나이 든 말투나 캐릭터 말투로 들릴 수 있다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 2,
    "key": "SONO_CHOUSHIDE",
    "legacy_key": "CHAT-20260905-155613-SONO-CHOUSHIDE",
    "jp": "その調子で",
    "pronunciation": "소노 초-시데",
    "meaning": "그 페이스로 계속해",
    "usage_note": "현재의 상태나 페이스를 유지하라는 격려.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 2,
    "key": "SONO_IKIDE",
    "legacy_key": "CHAT-20260905-155613-SONO-IKIDE",
    "jp": "その意気で",
    "pronunciation": "소노 이키데",
    "meaning": "그 기세로, 바로 그 정신으로",
    "usage_note": "의욕·투지·마음가짐을 격려한다. その息で가 아니라 その意気で.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 3,
    "key": "KUCHINO_HERANAI",
    "legacy_key": "CHAT-20260905-165650-KUCHINO-HERANAI",
    "jp": "口の減らないやつだ",
    "pronunciation": "쿠치노 헤라나이 야츠다",
    "meaning": "한마디도 안 지는 녀석이네",
    "usage_note": "꾸중을 들어도 계속 말대꾸하거나 지지 않고 받아치는 사람에게 쓰는 핀잔.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 4,
    "key": "NANIGOTONIMO_HODO",
    "legacy_key": "CHAT-20260905-172908-NANIGOTONIMO-HODO",
    "jp": "何事にも程がある",
    "pronunciation": "나니고토니모 호도가 아루",
    "meaning": "무슨 일이든 정도가 있다",
    "usage_note": "자연스럽지만 격언·훈계조 느낌이 있다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 4,
    "key": "SORENIMO_HODO",
    "legacy_key": "CHAT-20260905-172908-SORENIMO-HODO",
    "jp": "それにも程がある",
    "pronunciation": "소레니모 호도가 아루",
    "meaning": "그것도 정도가 있다, 그건 너무 심하다",
    "usage_note": "문법적으로 가능하지만 실제 회화에서는 지나친 대상을 직접 넣는 형태가 더 자연스럽다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 4,
    "key": "FUZAKERUNOMO_HODO",
    "legacy_key": "CHAT-20260905-172908-FUZAKERUNOMO-HODO",
    "jp": "ふざけるのも程がある",
    "pronunciation": "후자케루노모 호도가 아루",
    "meaning": "장난도 정도껏 해야지",
    "usage_note": "상대의 장난이나 행동이 지나쳤다고 강하게 지적한다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 4,
    "key": "HODOHODONI_SHIRO",
    "legacy_key": "CHAT-20260905-172908-HODOHODONI-SHIRO",
    "jp": "程々にしろ",
    "pronunciation": "호도호도니 시로",
    "meaning": "정도껏 해",
    "usage_note": "직접적이고 강한 명령형.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 4,
    "key": "HODOHODONI_SHITE",
    "legacy_key": "CHAT-20260905-172908-HODOHODONI-SHITE",
    "jp": "程々にして",
    "pronunciation": "호도호도니 시테",
    "meaning": "적당히 좀 해",
    "usage_note": "程々にしろ보다 부드럽다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 5,
    "key": "RASHIKUNAI",
    "legacy_key": "CHAT-20260905-175632-RASHIKUNAI",
    "jp": "らしくない",
    "pronunciation": "라시쿠나이",
    "meaning": "답지 않다, 평소답지 않다",
    "usage_note": "평소의 성격·행동·이미지와 다르다는 뜻이며, 似合わない는 어울리지 않는다는 뜻.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 6,
    "key": "WATASHINO_KIWA_KAWARANAI",
    "legacy_key": "CHAT-20260906-085418-WATASHINO-KIWA-KAWARANAI",
    "jp": "私の気は変わらないよ",
    "pronunciation": "와타시노 키와 카와라나이요",
    "meaning": "내 마음은 변하지 않아, 내 생각은 바뀌지 않아",
    "usage_note": "감정을 분명히 말할 때는 私の気持ちは変わらないよ가 더 자연스러울 수 있다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 7,
    "key": "MENGO",
    "legacy_key": "CHAT-20260906-091032-MENGO",
    "jp": "めんご",
    "pronunciation": "멘고",
    "meaning": "미안, 미안미안",
    "usage_note": "ごめん을 장난스럽게 뒤집은 속어. 친한 사이의 가벼운 사과이며 다소 옛날 유행어처럼 들릴 수 있다.",
    "speaking": false,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 8,
    "key": "BOKOBOKONI_SURUNDA",
    "legacy_key": "CHAT-20260906-095555-BOKOBOKONI-SURUNDA",
    "jp": "ボコボコにするんだ",
    "pronunciation": "보코보코니 스룬다",
    "meaning": "흠씬 패버리는 거야, 완전히 박살내는 거야",
    "usage_note": "폭력적이고 거친 표현. 게임·스포츠에서는 압도적으로 이긴다는 비유로도 쓴다.",
    "speaking": false,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 9,
    "key": "HONMAZUI",
    "legacy_key": "CHAT-20260913-133257-HONMAZUI",
    "jp": "ほんまずい",
    "pronunciation": "혼마즈이",
    "meaning": "문맥 불명확한 비표준·슬랭 후보",
    "usage_note": "확립된 표준 표현으로 보기 어렵다. ほんま、むずい 또는 ほんま、まずい 등 문맥 확인이 필요하다.",
    "speaking": false,
    "listening": true,
    "state": "HOLD"
  },
  {
    "pair": 12,
    "key": "NAGISA",
    "legacy_key": "CHAT-20260918-152342-NAGISA",
    "jp": "渚",
    "pronunciation": "나기사",
    "meaning": "물가, 해변",
    "usage_note": "물과 육지가 맞닿은 곳을 나타내는 다소 서정적인 표현.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 13,
    "key": "DAIJINI_SHITETA_RIYUU",
    "legacy_key": "CHAT-20260919-053745-DAIJINI-SHITETA-RIYUU",
    "jp": "大事にしてた理由があったんですね",
    "pronunciation": "다이지니 시테타 리유-가 앗탄데스네",
    "meaning": "애지중지한 이유가 있었네요",
    "usage_note": "물건·사람 모두 소중히 여기고 아꼈다는 뜻.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 13,
    "key": "KAWAIGATTETA_RIYUU_ATTA",
    "legacy_key": "CHAT-20260919-053745-KAWAIGATTETA-RIYUU-ATTA",
    "jp": "可愛がってた理由があったんですね",
    "pronunciation": "카와이갓테타 리유-가 앗탄데스네",
    "meaning": "예뻐하고 아낀 이유가 있었네요",
    "usage_note": "사람이나 동물을 애정을 담아 예뻐하고 아꼈다는 뜻.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 14,
    "key": "KAWAIGATTETA_RIYUU_WAKARIMASHITA",
    "legacy_key": "CHAT-20260919-053818-KAWAIGATTETA-RIYUU-WAKARIMASHITA",
    "jp": "可愛がってた理由がわかりました",
    "pronunciation": "카와이갓테타 리유-가 와카리마시타",
    "meaning": "예뻐한 이유를 알겠네요",
    "usage_note": "상대가 왜 예뻐했는지 이해했다는 뜻.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 15,
    "key": "SHUMIO_KAETE_KUDASAI",
    "legacy_key": "CHAT-20260919-084437-SHUMIO-KAETE-KUDASAI",
    "jp": "趣味を変えてください",
    "pronunciation": "슈미오 카에테 쿠다사이",
    "meaning": "취미를 바꾸세요",
    "usage_note": "정중한 문법형이지만 상황에 따라 딱딱하거나 직설적으로 들릴 수 있다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 15,
    "key": "SHUMI_KAETARA",
    "legacy_key": "CHAT-20260919-084437-SHUMI-KAETARA",
    "jp": "趣味変えたら？",
    "pronunciation": "슈미 카에타라?",
    "meaning": "취미 바꾸는 게 어때?",
    "usage_note": "친한 사이의 가벼운 제안이나 장난스러운 말투.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 16,
    "key": "NANTE_SUKOSHIDAKE_YUME",
    "legacy_key": "CHAT-20260919-140332-NANTE-SUKOSHIDAKE-YUME",
    "jp": "なんて少しだけ夢を見てしまっただけ",
    "pronunciation": "난테 스코시다케 유메오 미테시맛타다케",
    "meaning": "그런 꿈을 잠깐 꾸었을 뿐이야",
    "usage_note": "앞 문맥을 받는 なんて로 시작하는 문장 조각. 후회·자조가 섞일 수 있다.",
    "speaking": false,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 17,
    "key": "CHOTTO_KITAISHITA_DAKE",
    "legacy_key": "CHAT-20260919-140605-CHOTTO-KITAISHITA-DAKE",
    "jp": "ちょっと期待しただけ",
    "pronunciation": "춋토 키타이시타 다케",
    "meaning": "조금 기대했을 뿐이야",
    "usage_note": "가장 일상적이고 직접적인 표현.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 17,
    "key": "CHOTTO_YUME_MITETA_DAKE",
    "legacy_key": "CHAT-20260919-140605-CHOTTO-YUME-MITETA-DAKE",
    "jp": "ちょっと夢見てただけ",
    "pronunciation": "춋토 유메 미테타 다케",
    "meaning": "잠깐 꿈꿨을 뿐이야",
    "usage_note": "희망·환상·기대를 잠깐 품었다는 감성적인 표현.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 18,
    "key": "TSUMASAKI",
    "legacy_key": "CHAT-20260919-140859-TSUMASAKI",
    "jp": "つま先",
    "pronunciation": "츠마사키",
    "meaning": "발끝, 발가락 끝부분",
    "usage_note": "발의 맨 앞쪽.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 19,
    "key": "HADASHI",
    "legacy_key": "CHAT-20260919-141045-HADASHI",
    "jp": "裸足",
    "pronunciation": "하다시",
    "meaning": "맨발, 맨발로",
    "usage_note": "신발을 신지 않은 맨발 상태.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 21,
    "key": "ASHIATOO_TADOTTE",
    "legacy_key": "CHAT-20260919-141843-ASHIATOO-TADOTTE",
    "jp": "足跡を辿って",
    "pronunciation": "아시아토오 타돗테",
    "meaning": "발자국·흔적을 따라가며",
    "usage_note": "실제 발자국이나 누군가의 흔적·행적을 더듬어 따라간다는 뜻.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 22,
    "key": "KUCHIGUSE",
    "legacy_key": "CHAT-20260919-151055-KUCHIGUSE",
    "jp": "口癖",
    "pronunciation": "쿠치구세",
    "meaning": "말버릇, 입버릇, 자주 하는 말",
    "usage_note": "반복해서 자주 하는 말. 口調는 말투·어조.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 23,
    "key": "ORENIWA_WAKARANAIYO",
    "legacy_key": "CHAT-20260919-151328-ORENIWA-WAKARANAIYO",
    "jp": "俺には分からないよ",
    "pronunciation": "오레니와 와카라나이요",
    "meaning": "나로서는 모르겠어",
    "usage_note": "俺는 남성적이고 캐주얼한 1인칭. 分からない는 이해·판단할 수 없다는 뜻.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 24,
    "key": "MINI_TSUKUMADE_YARU",
    "legacy_key": "CHAT-20260919-151525-MINI-TSUKUMADE-YARU",
    "jp": "身につくまでやる",
    "pronunciation": "미니 츠쿠마데 야루",
    "meaning": "몸에 익을 때까지 한다",
    "usage_note": "기술·지식·습관 전반을 자기 것으로 만들 때 쓰는 범용 표현.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 24,
    "key": "KARADAGA_OBOERUMADE_YARU",
    "legacy_key": "CHAT-20260919-151525-KARADAGA-OBOERUMADE-YARU",
    "jp": "体が覚えるまでやる",
    "pronunciation": "카라다가 오보에루마데 야루",
    "meaning": "몸이 기억할 때까지 한다",
    "usage_note": "운동·악기·작업 동작처럼 반복 연습으로 몸에 새기는 느낌.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 25,
    "key": "NANIMONAI_NANTE_SHINJIRARERUKA",
    "legacy_key": "CHAT-20260919-152011-NANIMONAI-NANTE-SHINJIRARERUKA",
    "jp": "何もないなんて信じられるか",
    "pronunciation": "나니모 나이 난테 신지라레루카",
    "meaning": "아무것도 없다니 믿을 수 있겠어?",
    "usage_note": "강한 불신을 나타내는 반문이며 남성적이고 거칠게 들릴 수 있다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 26,
    "key": "YOTEIO_KAEYOU",
    "legacy_key": "CHAT-20260919-152332-YOTEIO-KAEYOU",
    "jp": "予定を変えよう",
    "pronunciation": "요테이오 카에요-",
    "meaning": "예정을 바꾸자",
    "usage_note": "일정이나 계획을 바꾸자는 제안.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 26,
    "key": "ISOIDA_HOUGA_II",
    "legacy_key": "CHAT-20260919-152332-ISOIDA-HOUGA-II",
    "jp": "急いだほうがいい",
    "pronunciation": "이소이다 호-가 이이",
    "meaning": "서두르는 게 좋겠어",
    "usage_note": "서두르는 편이 좋다는 판단·조언.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 27,
    "key": "MIESUGIDAYO",
    "legacy_key": "CHAT-20260919-153832-MIESUGIDAYO",
    "jp": "見えすぎだよ",
    "pronunciation": "미에스기다요",
    "meaning": "너무 잘 보여, 너무 많이 보여",
    "usage_note": "옷·자세 등으로 너무 많이 보이는 상황에서 다 보인다는 뜻으로도 쓴다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 28,
    "key": "HAATOGA_OOI_MITAIDANE",
    "legacy_key": "CHAT-20260919-161314-HAATOGA-OOI-MITAIDANE",
    "jp": "ハートが多いみたいだね",
    "pronunciation": "하-토가 오오이 미타이다네",
    "meaning": "하트가 많은가 보네",
    "usage_note": "정황을 보고 하트가 많은 것 같다고 추측한다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 29,
    "key": "SAKKIWA_NANDE_WARATTANDESUKA",
    "legacy_key": "CHAT-20260919-163121-SAKKIWA-NANDE-WARATTANDESUKA",
    "jp": "さっきはなんで笑ったんですか？",
    "pronunciation": "삿키와 난데 와랏탄데스카?",
    "meaning": "아까는 왜 웃었어요?",
    "usage_note": "일상적인 정중 표현.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 30,
    "key": "SAKKI_NANDE_WARATTANO",
    "legacy_key": "CHAT-20260919-163152-SAKKI-NANDE-WARATTANO",
    "jp": "さっき、なんで笑ったの？",
    "pronunciation": "삿키, 난데 와랏타노?",
    "meaning": "아까 왜 웃었어?",
    "usage_note": "친한 사이에서 가장 일반적인 반말.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 30,
    "key": "SAKKIWA_NANDE_WARATTANDAI",
    "legacy_key": "CHAT-20260919-163152-SAKKIWA-NANDE-WARATTANDAI",
    "jp": "さっきはなんで笑ったんだい？",
    "pronunciation": "삿키와 난데 와랏탄다이?",
    "meaning": "아까는 왜 웃었니?",
    "usage_note": "부드러운 남성 말투지만 다소 옛스럽거나 캐릭터풍으로 들릴 수 있다.",
    "speaking": false,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 31,
    "key": "KOUIUNOGA_OMOSHIROINOKANA",
    "legacy_key": "CHAT-20260919-163429-KOUIUNOGA-OMOSHIROINOKANA",
    "jp": "こういうのが面白いのかな？",
    "pronunciation": "코-이우노가 오모시로이노카나?",
    "meaning": "이런 게 재미있는 건가?",
    "usage_note": "대상 자체가 흥미롭거나 웃긴지 혼잣말처럼 의문을 나타낸다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 32,
    "key": "KOUIUNOGA_TANOSHIINO",
    "legacy_key": "CHAT-20260919-163457-KOUIUNOGA-TANOSHIINO",
    "jp": "こういうのが楽しいの？",
    "pronunciation": "코-이우노가 타노시이노?",
    "meaning": "이런 걸 하는 게 즐거워?",
    "usage_note": "직접 행동하면서 즐거운지를 묻는다. 面白い는 대상 자체의 재미·흥미에 초점.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 33,
    "key": "ASHITANO_KOTOWA_ASHITA_KANGAEYOU",
    "legacy_key": "CHAT-20260919-165307-ASHITANO-KOTOWA-ASHITA-KANGAEYOU",
    "jp": "明日のことは明日考えよう",
    "pronunciation": "아시타노 코토와 아시타 칸가에요-",
    "meaning": "내일 일은 내일 생각하자",
    "usage_note": "지금 쓸데없이 걱정하지 말자는 자연스러운 표현.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 34,
    "key": "ASATTENO_KOTO",
    "legacy_key": "CHAT-20260919-165343-ASATTENO-KOTO",
    "jp": "あさってのこと",
    "pronunciation": "아삿테노 코토",
    "meaning": "모레 일, 모레에 관한 것",
    "usage_note": "아직 먼 모레의 일이라는 뜻. あさっての方向은 관용적으로 엉뚱한 방향.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 35,
    "key": "KONNA_YARIKATA_TADASHIKUNAI",
    "legacy_key": "CHAT-20260919-165803-KONNA-YARIKATA-TADASHIKUNAI",
    "jp": "こんなやり方、正しくないよ",
    "pronunciation": "콘나 야리카타, 타다시쿠나이요",
    "meaning": "이런 방식은 잘못됐어",
    "usage_note": "원칙상 옳지 않다는 판단. 회화에서는 間違ってるよ도 직접적으로 자주 쓴다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 36,
    "key": "KINI_IRANAINE",
    "legacy_key": "CHAT-20260919-170725-KINI-IRANAINE",
    "jp": "気に入らないね",
    "pronunciation": "키니 이라나이네",
    "meaning": "마음에 안 드네",
    "usage_note": "취향·기준에 맞지 않아 마음에 들지 않는다는 뜻.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 37,
    "key": "YAKUSOKUNO_JIKANNI_NARUMADE_NEMASU",
    "legacy_key": "CHAT-20260919-172032-YAKUSOKUNO-JIKANNI-NARUMADE-NEMASU",
    "jp": "約束の時間になるまで寝ます",
    "pronunciation": "야쿠소쿠노 지칸니 나루마데 네마스",
    "meaning": "약속 시간이 될 때까지 잘게요",
    "usage_note": "그 시간이 되는 시점까지 잔다는 도달점을 강조.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 37,
    "key": "YAKUSOKUNO_JIKANMADE_NEMASU",
    "legacy_key": "CHAT-20260919-172032-YAKUSOKUNO-JIKANMADE-NEMASU",
    "jp": "約束の時間まで寝ます",
    "pronunciation": "야쿠소쿠노 지칸마데 네마스",
    "meaning": "약속 시간까지 잘게요",
    "usage_note": "같은 뜻을 더 간결하게 말한다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 38,
    "key": "OITETE_II",
    "legacy_key": "CHAT-20260920-001041-OITETE-II",
    "jp": "置いてていい？",
    "pronunciation": "오이테테 이이?",
    "meaning": "그대로 놔둬도 돼?",
    "usage_note": "이미 놓인 상태를 유지해도 되는지 묻는다. 置いていい？는 지금 놓는 행위에 초점.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 40,
    "key": "KONO_ATARIDE_KEKKOUDESU",
    "legacy_key": "CHAT-20260920-001515-KONO-ATARIDE-KEKKOUDESU",
    "jp": "この辺りで結構です",
    "pronunciation": "코노 아타리데 켓코-데스",
    "meaning": "이 근처면 됩니다",
    "usage_note": "택시에서 이 부근에 내려 달라는 부드러운 표현.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 40,
    "key": "KONO_HENDE_KEKKOUDESU",
    "legacy_key": "CHAT-20260920-001515-KONO-HENDE-KEKKOUDESU",
    "jp": "この辺で結構です",
    "pronunciation": "코노 헨데 켓코-데스",
    "meaning": "여기쯤이면 됩니다",
    "usage_note": "택시 하차 때 짧고 자연스럽게 자주 쓰는 표현.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 41,
    "key": "AISATSUMO_SHINAIDE_IKUNO",
    "legacy_key": "CHAT-20260920-003627-AISATSUMO-SHINAIDE-IKUNO",
    "jp": "挨拶もしないで行くの？",
    "pronunciation": "아이사츠모 시나이데 이쿠노?",
    "meaning": "인사도 없이 가는 거야?",
    "usage_note": "상대가 인사도 하지 않고 떠나는지를 묻는다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 41,
    "key": "ATTARA_MIRENGA_NOKORUDAKE",
    "legacy_key": "CHAT-20260920-003627-ATTARA-MIRENGA-NOKORUDAKE",
    "jp": "会ったら未練が残るだけ",
    "pronunciation": "앗타라 미렌가 노코루다케",
    "meaning": "보면 미련만 남아",
    "usage_note": "만나면 미련이 남을 뿐이라는 이별 상황의 표현.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 42,
    "key": "KOJITSUKE",
    "legacy_key": "CHAT-20260920-004235-KOJITSUKE",
    "jp": "こじつけ",
    "pronunciation": "코지츠케",
    "meaning": "억지, 억지로 갖다 붙인 논리",
    "usage_note": "관계없는 것을 억지로 관련짓거나 해석을 끼워 맞추는 것.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  },
  {
    "pair": 43,
    "key": "KOKONI_ITEII",
    "legacy_key": "CHAT-20260920-004315-KOKONI-ITEII",
    "jp": "ここにいていい",
    "pronunciation": "코코니 이테 이이",
    "meaning": "여기 있어도 돼, 여기 머물러도 돼",
    "usage_note": "단순 허락에는 자연스럽다. いてくれていい는 있어주는 호의·감사 뉘앙스가 들어가 단순 허락으로는 어색할 수 있다.",
    "speaking": true,
    "listening": true,
    "state": "ACTIVE"
  }
]$json$::jsonb) as x(
  pair integer, key text, legacy_key text, jp text, pronunciation text, meaning text, usage_note text,
  speaking boolean, listening boolean, state text
);

insert into public.source_memo (memo_seq, original_text, legacy_folder_id)
select s.memo_seq,
       '[사용자]' || E'\n' || s.user_input || E'\n\n[검토 결과]\n' || s.summary,
       'CHAT_일어수집'
from _study_source s
where not exists (select 1 from public.source_memo sm where sm.memo_seq=s.memo_seq);

insert into public.source_memo_origin
  (source_memo_id, source_folder, source_file, occurrence_order)
select sm.id, '김토끼니혼고/일어수집', 'ChatGPT 공유대화 일어수집', s.pair
from _study_source s
join public.source_memo sm on sm.memo_seq=s.memo_seq
where not exists (
  select 1 from public.source_memo_origin o
  where o.source_memo_id=sm.id and o.source_folder='김토끼니혼고/일어수집'
);

insert into public.candidate_unit (
  source_memo_id, legacy_candidate_key, korean_meaning, display_pronunciation,
  japanese_original, personal_note, literal_translation, recovery_method,
  verification_status, source_record_ref, source_excerpt,
  source_folder_snapshot, source_file_snapshot
)
select sm.id,
       c.legacy_key,
       c.meaning, c.pronunciation, c.jp, c.usage_note, null,
       'STUDY_CHAT_VERIFIED', 'VERIFIED', s.source_ref, s.user_input,
       '김토끼니혼고/일어수집', 'ChatGPT 공유대화 일어수집'
from _study_candidate c
join _study_source s on s.pair=c.pair
join public.source_memo sm on sm.memo_seq=s.memo_seq
where c.state='ACTIVE'
  and not exists (
    select 1 from public.candidate_unit cu
    where cu.legacy_candidate_key=c.legacy_key
  );

insert into public.expression (
  display_pronunciation, japanese_original, status, verification_status,
  speaking_enabled, listening_enabled, edge_flag, created_at, updated_at
)
select c.pronunciation, c.jp, 'ACTIVE', 'VERIFIED', c.speaking, c.listening, false, now(), now()
from _study_candidate c
where c.state='ACTIVE'
  and not exists (
    select 1 from public.expression e
    where regexp_replace(lower(coalesce(e.japanese_original,'')), '[[:space:]、。！？!?「」『』（）()・]', '', 'g') =
          regexp_replace(lower(c.jp), '[[:space:]、。！？!?「」『』（）()・]', '', 'g')
      and e.status <> 'EXCLUDED'
  );

create temporary table _study_resolved on commit drop as
select distinct on (c.key)
       c.*, s.source_ref, s.user_input, sm.id source_memo_id,
       cu.id candidate_unit_id, e.id expression_id
from _study_candidate c
join _study_source s on s.pair=c.pair
join public.source_memo sm on sm.memo_seq=s.memo_seq
join public.candidate_unit cu
  on cu.legacy_candidate_key=c.legacy_key
join public.expression e
  on regexp_replace(lower(coalesce(e.japanese_original,'')), '[[:space:]、。！？!?「」『』（）()・]', '', 'g') =
     regexp_replace(lower(c.jp), '[[:space:]、。！？!?「」『』（）()・]', '', 'g')
 and e.status='ACTIVE'
where c.state='ACTIVE'
order by c.key, e.id;

insert into public.expression_meaning
  (expression_id, meaning_text, meaning_norm, meaning_order, is_primary, usage_note, created_at)
select r.expression_id, r.meaning, lower(btrim(r.meaning)), 1, true, r.usage_note, now()
from _study_resolved r
where not exists (
  select 1 from public.expression_meaning em
  where em.expression_id=r.expression_id and em.is_primary=true
);

insert into public.search_alias
  (expression_id, alias_text, alias_norm, alias_type, origin, created_at)
select r.expression_id, r.pronunciation,
       regexp_replace(regexp_replace(regexp_replace(lower(btrim(r.pronunciation)), '[↗↘~]', '', 'g'), '\s+', ' ', 'g'), '[?？!！。．.]+$', '', 'g'),
       'NORMALIZED', 'SOURCE', now()
from _study_resolved r
where not exists (
  select 1 from public.search_alias sa
  where sa.expression_id=r.expression_id and sa.alias_type='NORMALIZED'
    and sa.alias_norm=regexp_replace(regexp_replace(regexp_replace(lower(btrim(r.pronunciation)), '[↗↘~]', '', 'g'), '\s+', ' ', 'g'), '[?？!！。．.]+$', '', 'g')
);

create temporary table _study_alias on commit drop as
select * from jsonb_to_recordset($json$[
  {
    "key": "KUCHINO_HERANAI",
    "alias_text": "쿠치노 헤라나이야츠다"
  },
  {
    "key": "KUCHIGUSE",
    "alias_text": "쿠치쿠세"
  },
  {
    "key": "WATASHINO_KIWA_KAWARANAI",
    "alias_text": "와타시노 키와 키와라나이요"
  },
  {
    "key": "OITETE_II",
    "alias_text": "오이테테이이"
  },
  {
    "key": "KONO_ATARIDE_KEKKOUDESU",
    "alias_text": "코노 아타리데 겟코데스"
  },
  {
    "key": "KOJITSUKE",
    "alias_text": "고지츠키"
  },
  {
    "key": "KOKONI_ITEII",
    "alias_text": "잇테 쿠레테 이이"
  }
]$json$::jsonb) as x(key text, alias_text text);

insert into public.search_alias
  (expression_id, alias_text, alias_norm, alias_type, origin, created_at)
select r.expression_id, a.alias_text,
       regexp_replace(regexp_replace(regexp_replace(lower(btrim(a.alias_text)), '[↗↘~]', '', 'g'), '\s+', ' ', 'g'), '[?？!！。．.]+$', '', 'g'),
       'SOURCE_VARIANT', 'SOURCE', now()
from _study_alias a join _study_resolved r using (key)
where not exists (
  select 1 from public.search_alias sa
  where sa.expression_id=r.expression_id
    and sa.alias_norm=regexp_replace(regexp_replace(regexp_replace(lower(btrim(a.alias_text)), '[↗↘~]', '', 'g'), '\s+', ' ', 'g'), '[?？!！。．.]+$', '', 'g')
);

insert into public.expression_source (expression_id, candidate_unit_id, created_at)
select r.expression_id, r.candidate_unit_id, now()
from _study_resolved r
where not exists (
  select 1 from public.expression_source es where es.candidate_unit_id=r.candidate_unit_id
);

insert into public.note (
  source_memo_id, candidate_unit_id, expression_id, source_record_ref,
  note_type, note_text, source_excerpt, display_order, created_at
)
select r.source_memo_id, r.candidate_unit_id, r.expression_id, r.source_ref,
       'REFERENCE', r.usage_note, r.user_input, 1, now()
from _study_resolved r
where r.usage_note is not null
  and not exists (
    select 1 from public.note n
    where n.expression_id=r.expression_id and n.source_record_ref=r.source_ref
      and n.note_type='REFERENCE' and n.note_text=r.usage_note
  );

-- Preserve the follow-up about object/food/situation meanings without creating another expression.
insert into public.note (
  source_memo_id, candidate_unit_id, expression_id, source_record_ref,
  note_type, note_text, source_excerpt, display_order, created_at
)
select sm.id, r.candidate_unit_id, r.expression_id, s.source_ref, 'REFERENCE',
       '물건은 놓아둔 상태 유지, 음식은 보관 위치에 둠, 추상적 상황은 このままでいい？ 또는 放っておいていい？가 더 자연스러울 수 있다.',
       s.user_input, 2, now()
from _study_source s
join public.source_memo sm on sm.memo_seq=s.memo_seq
join _study_resolved r on r.key='OITETE_II'
where s.pair=39
  and not exists (
    select 1 from public.note n where n.expression_id=r.expression_id and n.source_record_ref=s.source_ref
  );

-- Ambiguous "혼마즈이" remains blocked from the public app until context is available.
insert into public.source_assertion (
  source_memo_id, source_record_ref, source_excerpt, assertion_type, assertion_text,
  origin, verification_status, confidence, review_status, operational_exposure,
  correction_status, temporal_scope, quality_note, assertion_key, created_at, updated_at
)
select sm.id, s.source_ref, s.user_input, 'STUDY_CHAT_AMBIGUOUS_EXPRESSION',
       'ほんまずい의 실제 원문과 뜻은 문맥 없이 확정할 수 없음', 'ORIGINAL',
       'POSSIBLE_ERROR', 'LOW', 'HOLD', 'BLOCKED', 'REQUIRED', 'CONTEXT_DEPENDENT',
       'ほんま、むずい / ほんま、まずい / 기타 표현 중 어느 것인지 앞뒤 대사 확인 필요',
       'STUDY_CHAT:HONMAZUI:' || s.pair, now(), now()
from _study_source s
join public.source_memo sm on sm.memo_seq=s.memo_seq
where s.pair in (9,10,11)
  and not exists (select 1 from public.source_assertion a where a.assertion_key='STUDY_CHAT:HONMAZUI:' || s.pair);

insert into public.provisional_expression (
  provisional_key, display_pronunciation, japanese_original, meaning_hint,
  status, verification_status, review_status, operational_exposure, created_at, updated_at
)
select 'STUDY_CHAT:HONMAZUI', '혼마즈이', 'ほんまずい',
       '문맥에 따라 진짜 어렵다·진짜 곤란하다 등으로 갈릴 수 있는 미확정 후보',
       'HOLD', 'UNVERIFIED', 'REVIEW_REQUIRED', 'BLOCKED', now(), now()
where not exists (select 1 from public.provisional_expression p where p.provisional_key='STUDY_CHAT:HONMAZUI');

insert into public.provisional_expression_evidence (provisional_expression_id, source_assertion_id)
select p.id, a.id
from public.provisional_expression p
join public.source_assertion a on a.assertion_key like 'STUDY_CHAT:HONMAZUI:%'
where p.provisional_key='STUDY_CHAT:HONMAZUI'
on conflict do nothing;

create temporary table _study_group on commit drop as
select * from jsonb_to_recordset($json$[
  {
    "group_key": "STUDY_CHAT:ENCOURAGEMENT_PACE",
    "label": "기세·페이스",
    "keys": [
      "SONO_CHOUSHIDE",
      "SONO_IKIDE"
    ]
  },
  {
    "group_key": "STUDY_CHAT:LIMIT_MODERATION",
    "label": "정도껏·지나침",
    "keys": [
      "NANIGOTONIMO_HODO",
      "SORENIMO_HODO",
      "FUZAKERUNOMO_HODO",
      "HODOHODONI_SHIRO",
      "HODOHODONI_SHITE"
    ]
  },
  {
    "group_key": "STUDY_CHAT:CHERISH_REASON",
    "label": "아끼고 예뻐한 이유",
    "keys": [
      "DAIJINI_SHITETA_RIYUU",
      "KAWAIGATTETA_RIYUU_ATTA",
      "KAWAIGATTETA_RIYUU_WAKARIMASHITA"
    ]
  },
  {
    "group_key": "STUDY_CHAT:HOBBY_CHANGE",
    "label": "취미 바꾸기",
    "keys": [
      "SHUMIO_KAETE_KUDASAI",
      "SHUMI_KAETARA"
    ]
  },
  {
    "group_key": "STUDY_CHAT:DREAM_EXPECTATION",
    "label": "꿈·기대",
    "keys": [
      "NANTE_SUKOSHIDAKE_YUME",
      "CHOTTO_KITAISHITA_DAKE",
      "CHOTTO_YUME_MITETA_DAKE"
    ]
  },
  {
    "group_key": "STUDY_CHAT:BODY_LEARNING",
    "label": "몸에 익히기",
    "keys": [
      "MINI_TSUKUMADE_YARU",
      "KARADAGA_OBOERUMADE_YARU"
    ]
  },
  {
    "group_key": "STUDY_CHAT:WHY_LAUGHED",
    "label": "왜 웃었어",
    "keys": [
      "SAKKIWA_NANDE_WARATTANDESUKA",
      "SAKKI_NANDE_WARATTANO",
      "SAKKIWA_NANDE_WARATTANDAI"
    ]
  },
  {
    "group_key": "STUDY_CHAT:FUN_NUANCE",
    "label": "재미·즐거움",
    "keys": [
      "KOUIUNOGA_OMOSHIROINOKANA",
      "KOUIUNOGA_TANOSHIINO"
    ]
  },
  {
    "group_key": "STUDY_CHAT:SLEEP_UNTIL_TIME",
    "label": "약속시간까지 자기",
    "keys": [
      "YAKUSOKUNO_JIKANNI_NARUMADE_NEMASU",
      "YAKUSOKUNO_JIKANMADE_NEMASU"
    ]
  },
  {
    "group_key": "STUDY_CHAT:TAXI_STOP",
    "label": "택시 하차",
    "keys": [
      "KONO_ATARIDE_KEKKOUDESU",
      "KONO_HENDE_KEKKOUDESU"
    ]
  }
]$json$::jsonb) as x(group_key text, label text, keys jsonb);

insert into public.learning_association_group
  (group_key, label, group_type, status, display_order, created_at, updated_at)
select g.group_key, g.label, 'SEMANTIC', 'ACTIVE', 35, now(), now()
from _study_group g
on conflict (group_key) do update set label=excluded.label, status='ACTIVE', updated_at=now();

insert into public.learning_association_member
  (group_id, expression_id, member_role, association_level, display_order, created_at)
select g.id, r.expression_id,
       case when k.ord=1 then 'CORE' else 'RELATED' end,
       case when k.ord=1 then 1 else 2 end,
       k.ord::integer, now()
from _study_group sg
join public.learning_association_group g on g.group_key=sg.group_key
cross join lateral jsonb_array_elements_text(sg.keys) with ordinality as k(key, ord)
join _study_resolved r on r.key=k.key
on conflict (group_id, expression_id) do update
set member_role=excluded.member_role,
    association_level=excluded.association_level,
    display_order=excluded.display_order;

do $$
declare
  v_sources integer;
  v_resolved integer;
  v_group_members integer;
begin
  select count(*) into v_sources
  from _study_source s join public.source_memo sm on sm.memo_seq=s.memo_seq;
  select count(*) into v_resolved from _study_resolved;
  select count(*) into v_group_members
  from _study_group sg
  cross join lateral jsonb_array_elements_text(sg.keys) k
  join _study_resolved r on r.key=k.value;

  if v_sources <> 42 then raise exception 'study chat source count mismatch: %', v_sources; end if;
  if v_resolved <> 52 then raise exception 'study chat resolved count mismatch: %', v_resolved; end if;
  if v_group_members <> 26 then raise exception 'study chat group member count mismatch: %', v_group_members; end if;
  if not exists (
    select 1 from public.provisional_expression
    where provisional_key='STUDY_CHAT:HONMAZUI' and status='HOLD' and operational_exposure='BLOCKED'
  ) then raise exception 'blocked HONMAZUI provisional record missing'; end if;
end $$;
