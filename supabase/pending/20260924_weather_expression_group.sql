-- Curated weather hub. Reuses the existing learning association model so
-- searches for 날씨/텐키 can reach weather sentences that omit those words.

select pg_advisory_xact_lock(hashtext('kimtokki_weather_expression_group_v1'));

insert into public.learning_association_group
  (group_key,label,group_type,status,display_order,created_at,updated_at)
values
  ('SEMANTIC:WEATHER_EXPRESSIONS','날씨 표현','SEMANTIC','ACTIVE',36,now(),now())
on conflict (group_key) do update
set label=excluded.label,
    group_type=excluded.group_type,
    status=excluded.status,
    display_order=excluded.display_order,
    updated_at=now();

with selected(expression_id,member_role,association_level,display_order) as (
  values
    (45::bigint,'CORE',1::smallint,1),    -- 텐키 / 날씨
    (51,'CORE',1,2),                      -- 날씨 어때?
    (53,'CORE',1,3),                      -- 좋은 날씨
    (69,'CORE',1,4),                      -- 하레 / 맑음
    (80,'CORE',1,5),                      -- 흐림
    (93,'CORE',1,6),                      -- 흐리고 가끔 비
    (46,'RELATED',2,10),                  -- 태풍
    (78,'RELATED',2,11),                  -- 구름
    (94,'RELATED',2,12),                  -- 안개
    (5542,'RELATED',2,13),                -- 바람
    (58,'RELATED',2,14),                  -- 히요리
    (70,'RELATED',2,15),                  -- 날씨 맑음
    (7047,'RELATED',2,16),                -- 맑아지다
    (71,'RELATED',2,17),                  -- 맑아질 거야
    (73,'RELATED',2,18),                  -- 맑은 하늘
    (74,'RELATED',2,19),                  -- 구름 한 점 없다
    (81,'RELATED',2,20),                  -- 날씨가 흐려
    (92,'RELATED',2,21),                  -- 잔뜩 흐려졌다
    (96,'RELATED',2,22),                  -- 안개 끼다
    (3043,'RELATED',2,23),                -- 비가 안 와
    (4245,'RELATED',2,24),                -- 비가 그쳤다
    (5266,'RELATED',2,25),                -- 비 오는 것 같아
    (5271,'RELATED',2,26),                -- 비가 올 것 같아요
    (952,'RELATED',2,27),                 -- 갑자기 비가 오네요
    (3670,'RELATED',2,28),                -- 내일 비가 온다고 합니다
    (5034,'RELATED',2,29),                -- 눈이 올 예정입니다
    (3811,'RELATED',2,30),                -- 태풍이 다가오고 있어
    (5550,'RELATED',2,31),                -- 방금 바람이 불었어요
    (394,'RELATED',2,40),                 -- 더워서
    (395,'RELATED',2,41),                 -- 추워서
    (125,'RELATED',2,42),                 -- 더워졌어요
    (126,'RELATED',2,43),                 -- 추워졌어요
    (6853,'RELATED',2,44),                -- 너무 덥네요
    (1843,'RELATED',2,45),                -- 생각보다 춥네요
    (6688,'RELATED',2,46),                -- 습하다
    (6689,'RELATED',2,47),                -- 습하네
    (9232,'RELATED',2,48)                 -- 테루테루보오즈
), active_selected as (
  select s.*
  from selected s
  join public.expression e on e.id=s.expression_id and e.status='ACTIVE'
)
insert into public.learning_association_member
  (group_id,expression_id,member_role,association_level,display_order,created_at)
select g.id,s.expression_id,s.member_role,s.association_level,s.display_order,now()
from active_selected s
join public.learning_association_group g
  on g.group_key='SEMANTIC:WEATHER_EXPRESSIONS'
on conflict (group_id,expression_id) do update
set member_role=excluded.member_role,
    association_level=excluded.association_level,
    display_order=excluded.display_order;
