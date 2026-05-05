-- ============================================================
-- Miche-Let MVP 테스트 시드 데이터
-- 대상 DB: michelet_db (PostgreSQL)
-- 사전 조건: 모든 서비스를 최소 1회 기동하여 Hibernate DDL로 테이블 생성 완료
--
-- 실행 방법:
--   docker exec -i db psql -U admin -d michelet_db \
--     < http-mvp/sql/seed_mvp_data.sql
--
-- 이 시드 데이터는 owner.http를 실행하지 않고 user.http만 테스트할 때 사용합니다.
-- 고정 UUID를 사용하므로 멱등성 보장 (중복 실행 안전)
--
-- 고정 ID 목록 (http-client.env.json 의 값과 동일):
--   owneruser_mvp : aa000001-0000-0000-0000-000000000001
--   restaurant    : bb000001-0000-0000-0000-000000000001
--   course        : cc000001-0000-0000-0000-000000000001
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 1. 점주 계정 (user_service.p_users)
--    loginId: owneruser_mvp / password: Test123!@#
--    ※ owner.http의 owner_mvp 계정과는 별개의 시드 전용 계정
-- ============================================================
INSERT INTO user_service.p_users (
    id,
    login_id,
    password,
    name,
    email,
    phone,
    role,
    status,
    last_login_at,
    created_at,
    created_by,
    updated_at,
    updated_by,
    deleted_at,
    deleted_by
) VALUES (
    'aa000001-0000-0000-0000-000000000001',
    'owneruser_mvp',
    crypt('Test123!@#', gen_salt('bf', 10)),
    'MVP 점주 (시드)',
    'owneruser_mvp@example.com',
    '010-9900-0010',
    'OWNER',
    'ACTIVE',
    NULL,
    NOW(),
    'aa000001-0000-0000-0000-000000000001',
    NOW(),
    NULL,
    NULL,
    NULL
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 2. 식당 (restaurant_service.p_restaurant)
-- ============================================================
INSERT INTO restaurant_service.p_restaurant (
    restaurant_id,
    owner_id,
    name,
    address,
    phone,
    description,
    reservation_open_at,
    avg_meal_duration_min,
    status,
    business_hours,
    created_at,
    created_by,
    updated_at,
    updated_by,
    deleted_at,
    deleted_by
) VALUES (
    'bb000001-0000-0000-0000-000000000001',
    'aa000001-0000-0000-0000-000000000001',
    'MicheLet Dining',
    '서울특별시 강남구 테헤란로 123',
    '02-1234-5678',
    '파인다이닝 레스토랑입니다.',
    '10:00',
    90,
    'OPEN',
    '화-일 18:00-22:00 (월요일 정기 휴무)',
    NOW(),
    'aa000001-0000-0000-0000-000000000001',
    NOW(),
    NULL,
    NULL,
    NULL
)
ON CONFLICT (restaurant_id) DO NOTHING;

-- ============================================================
-- 3. 코스 (restaurant_service.p_restaurant_course)
-- ============================================================
INSERT INTO restaurant_service.p_restaurant_course (
    course_id,
    restaurant_id,
    name,
    price,
    menu_composition,
    session_type,
    status,
    created_at,
    created_by,
    updated_at,
    updated_by,
    deleted_at,
    deleted_by
) VALUES (
    'cc000001-0000-0000-0000-000000000001',
    'bb000001-0000-0000-0000-000000000001',
    '디너 코스',
    150000,
    '아뮤즈부쉬 → 전채 → 생선 → 메인 → 디저트',
    'DINNER',
    'AVAILABLE',
    NOW(),
    'aa000001-0000-0000-0000-000000000001',
    NOW(),
    NULL,
    NULL,
    NULL
)
ON CONFLICT (course_id) DO NOTHING;

-- ============================================================
-- 4. 코스 메뉴 (restaurant_service.p_restaurant_course_menu)
-- ============================================================
INSERT INTO restaurant_service.p_restaurant_course_menu (
    course_menu_id,
    course_id,
    course_part,
    menu_name,
    sort_order,
    created_at,
    created_by,
    updated_at,
    updated_by,
    deleted_at,
    deleted_by
) VALUES
    (gen_random_uuid(), 'cc000001-0000-0000-0000-000000000001', 'AMUSE_BOUCHE', '한우 타르타르', 1, NOW(), 'aa000001-0000-0000-0000-000000000001', NOW(), NULL, NULL, NULL),
    (gen_random_uuid(), 'cc000001-0000-0000-0000-000000000001', 'APPETIZER',    '제철 샐러드',   2, NOW(), 'aa000001-0000-0000-0000-000000000001', NOW(), NULL, NULL, NULL),
    (gen_random_uuid(), 'cc000001-0000-0000-0000-000000000001', 'FISH',         '제철 생선 구이',3, NOW(), 'aa000001-0000-0000-0000-000000000001', NOW(), NULL, NULL, NULL),
    (gen_random_uuid(), 'cc000001-0000-0000-0000-000000000001', 'MAIN',         '양갈비',        4, NOW(), 'aa000001-0000-0000-0000-000000000001', NOW(), NULL, NULL, NULL),
    (gen_random_uuid(), 'cc000001-0000-0000-0000-000000000001', 'DESSERT',      '바닐라 무스',   5, NOW(), 'aa000001-0000-0000-0000-000000000001', NOW(), NULL, NULL, NULL)
ON CONFLICT ON CONSTRAINT uk_restaurant_course_menu_course_id_sort_order DO NOTHING;

-- ============================================================
-- 5. 타임슬롯 (timeslot_service.p_time_slot) — 2026년 7월 전체
--    하루 3슬롯: 18:00 / 19:00 / 20:00 (1시간 단위)
--    수용 10명, OPENED, version=0
-- ============================================================
INSERT INTO timeslot_service.p_time_slot (
    time_slot_id,
    restaurant_id,
    target_date,
    start_time,
    end_time,
    capacity,
    remaining_capacity,
    status,
    version,
    created_at,
    created_by,
    updated_at,
    updated_by,
    deleted_at,
    deleted_by
)
SELECT
    gen_random_uuid(),
    'bb000001-0000-0000-0000-000000000001'::UUID,
    d::DATE,
    t::TIME,
    (t::TIME + INTERVAL '1 hour'),
    10,
    10,
    'OPENED',
    0,
    NOW(),
    'aa000001-0000-0000-0000-000000000001'::UUID,
    NOW(),
    NULL,
    NULL,
    NULL
FROM
    generate_series('2026-07-01'::DATE, '2026-07-31'::DATE, '1 day') AS d,
    (VALUES ('18:00'), ('19:00'), ('20:00')) AS times(t)
ON CONFLICT ON CONSTRAINT uk_time_slot_restaurant_date_start DO NOTHING;

-- ============================================================
-- 결과 확인
-- ============================================================
SELECT
    'p_restaurant'       AS "테이블", COUNT(*) AS "행 수"
    FROM restaurant_service.p_restaurant   WHERE restaurant_id = 'bb000001-0000-0000-0000-000000000001'
UNION ALL
SELECT 'p_restaurant_course',      COUNT(*) FROM restaurant_service.p_restaurant_course  WHERE restaurant_id = 'bb000001-0000-0000-0000-000000000001'
UNION ALL
SELECT 'p_restaurant_course_menu', COUNT(*) FROM restaurant_service.p_restaurant_course_menu WHERE course_id = 'cc000001-0000-0000-0000-000000000001'
UNION ALL
SELECT 'p_time_slot (7월)',        COUNT(*) FROM timeslot_service.p_time_slot WHERE restaurant_id = 'bb000001-0000-0000-0000-000000000001';
