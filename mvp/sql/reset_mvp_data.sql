-- ============================================================
-- Miche-Let MVP 테스트 데이터 초기화
-- 시드 데이터 및 시나리오 실행 중 생성된 데이터를 모두 삭제합니다.
--
-- 실행 방법:
--   docker exec -i db psql -U admin -d michelet_db \
--     < http-mvp/sql/reset_mvp_data.sql
-- 이후 seed_mvp_data.sql을 재실행하여 초기 상태로 복원하세요.
-- ============================================================

-- 체크인 로그 삭제 (restaurant_service)
DELETE FROM restaurant_service.p_restaurant_checkin_log
WHERE reservation_id IN (
    SELECT id FROM reservation_service.p_reservations
    WHERE restaurant_id = 'bb000001-0000-0000-0000-000000000001'
);

-- 예약 삭제
DELETE FROM reservation_service.p_reservations
WHERE restaurant_id = 'bb000001-0000-0000-0000-000000000001';

-- 대기열 삭제
DELETE FROM waiting_service.p_waiting_queue
WHERE restaurant_id = 'bb000001-0000-0000-0000-000000000001';

-- 타임슬롯 삭제
DELETE FROM timeslot_service.p_time_slot
WHERE restaurant_id = 'bb000001-0000-0000-0000-000000000001';

-- 코스 메뉴 삭제
DELETE FROM restaurant_service.p_restaurant_course_menu
WHERE course_id = 'cc000001-0000-0000-0000-000000000001';

-- 코스 삭제
DELETE FROM restaurant_service.p_restaurant_course
WHERE restaurant_id = 'bb000001-0000-0000-0000-000000000001';

-- 식당 삭제
DELETE FROM restaurant_service.p_restaurant
WHERE restaurant_id = 'bb000001-0000-0000-0000-000000000001';

-- 시드 점주 계정 삭제
DELETE FROM user_service.p_users
WHERE id = 'aa000001-0000-0000-0000-000000000001';

-- owner.http / user.http 시나리오에서 signup으로 생성된 계정 삭제
DELETE FROM user_service.p_users
WHERE login_id IN ('ownermvp', 'usermvp');

-- owner.http가 동적으로 생성한 restaurant / timeslot 삭제
-- (owner_mvp userId로 생성된 식당은 owner_mvp 계정이 없으므로 직접 삭제 불필요)

SELECT '초기화 완료 — seed_mvp_data.sql을 실행하세요.' AS "상태";
