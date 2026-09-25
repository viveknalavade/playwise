-- MySQL 8 analytical examples. Views use completed sessions unless documented.
-- Rank games per player and demonstrate cumulative playtime.
SELECT player_id,game_id,SUM(duration_minutes) minutes,
 RANK() OVER(PARTITION BY player_id ORDER BY SUM(duration_minutes) DESC) game_rank,
 DENSE_RANK() OVER(ORDER BY SUM(duration_minutes) DESC) overall_rank
FROM PLAYER_SESSIONS GROUP BY player_id,game_id HAVING SUM(duration_minutes)>60;
SELECT player_id,session_start,duration_minutes,
 SUM(duration_minutes) OVER(PARTITION BY player_id ORDER BY session_start,session_id) running_minutes
FROM PLAYER_SESSIONS WHERE session_end IS NOT NULL;
-- Safe transactional DELETE demonstration: rollback preserves data.
START TRANSACTION;
DELETE FROM LIMIT_HISTORY WHERE effective_to < UTC_TIMESTAMP() - INTERVAL 10 YEAR;
ROLLBACK;
