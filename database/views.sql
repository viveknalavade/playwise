CREATE OR REPLACE VIEW VW_PLAYER_PLAYTIME_SUMMARY AS SELECT p.player_id,p.username,ROUND(COALESCE(SUM(s.duration_minutes),0)/60,2) total_playtime_hours,ROUND(COALESCE(SUM(s.duration_minutes),0)/GREATEST(1,DATEDIFF(UTC_DATE(),MIN(DATE(s.session_start)))+1),2) avg_daily_playtime FROM PLAYERS p LEFT JOIN PLAYER_SESSIONS s USING(player_id) GROUP BY p.player_id;
CREATE OR REPLACE VIEW VW_GAME_POPULARITY AS SELECT g.game_id,g.game_name,COUNT(DISTINCT s.player_id) total_players,ROUND(COALESCE(SUM(s.duration_minutes),0)/60,2) total_hours_played,COALESCE(AVG(s.duration_minutes),0) avg_session_duration FROM GAMES g LEFT JOIN PLAYER_SESSIONS s USING(game_id) GROUP BY g.game_id;
CREATE OR REPLACE VIEW VW_SPENDING_ANALYSIS AS WITH ranked AS (SELECT player_id,game_id,SUM(amount) spent,ROW_NUMBER() OVER(PARTITION BY player_id ORDER BY SUM(amount) DESC,game_id) position FROM PURCHASES GROUP BY player_id,game_id) SELECT p.player_id,p.username,COALESCE((SELECT SUM(amount) FROM PURCHASES WHERE player_id=p.player_id),0) total_spent,g.game_name most_spent_game FROM PLAYERS p LEFT JOIN ranked r ON r.player_id=p.player_id AND r.position=1 LEFT JOIN GAMES g ON g.game_id=r.game_id;
CREATE OR REPLACE VIEW VW_ACHIEVEMENT_PROGRESS AS SELECT p.player_id,p.username,COUNT(pa.achievement_id) total_achievements,COALESCE(SUM(a.points),0) total_points,MAX(pa.earned_at) recent_achievements FROM PLAYERS p LEFT JOIN PLAYER_ACHIEVEMENTS pa USING(player_id) LEFT JOIN ACHIEVEMENTS a USING(achievement_id) GROUP BY p.player_id;
CREATE OR REPLACE VIEW VW_BEHAVIOR_TRENDS AS WITH daily AS (SELECT player_id,DATE(session_start) date,SUM(duration_minutes) daily_playtime FROM PLAYER_SESSIONS WHERE session_end IS NOT NULL GROUP BY player_id,DATE(session_start)), changes AS (SELECT *,LAG(daily_playtime) OVER(PARTITION BY player_id ORDER BY date) previous_day_playtime FROM daily) SELECT *,daily_playtime-previous_day_playtime playtime_change,CASE WHEN previous_day_playtime IS NULL THEN 'First recorded day' WHEN daily_playtime>previous_day_playtime THEN 'Increasing' WHEN daily_playtime<previous_day_playtime THEN 'Decreasing' ELSE 'Stable' END trend FROM changes;
CREATE OR REPLACE VIEW VW_LIMIT_COMPLIANCE AS
WITH boundaries AS (
 SELECT p.player_id,p.username,p.timezone_offset_minutes,l.*,
 DATE_SUB(DATE(DATE_ADD(UTC_TIMESTAMP(),INTERVAL p.timezone_offset_minutes MINUTE)),INTERVAL p.timezone_offset_minutes MINUTE) today_start,
 DATE_SUB(DATE_SUB(DATE(DATE_ADD(UTC_TIMESTAMP(),INTERVAL p.timezone_offset_minutes MINUTE)),INTERVAL WEEKDAY(DATE_ADD(UTC_TIMESTAMP(),INTERVAL p.timezone_offset_minutes MINUTE)) DAY),INTERVAL p.timezone_offset_minutes MINUTE) week_start
 FROM PLAYERS p JOIN (SELECT player_id AS limit_player_id,daily_playtime_limit,weekly_playtime_limit,monthly_spending_limit FROM PLAYER_LIMITS) l ON l.limit_player_id=p.player_id
), actual AS (
 SELECT b.*,
 COALESCE((SELECT SUM(GREATEST(0,TIMESTAMPDIFF(SECOND,GREATEST(s.session_start,b.today_start),COALESCE(s.session_end,UTC_TIMESTAMP())))/60) FROM PLAYER_SESSIONS s WHERE s.player_id=b.player_id AND COALESCE(s.session_end,UTC_TIMESTAMP())>b.today_start),0) daily_actual,
 COALESCE((SELECT SUM(GREATEST(0,TIMESTAMPDIFF(SECOND,GREATEST(s.session_start,b.week_start),COALESCE(s.session_end,UTC_TIMESTAMP())))/60) FROM PLAYER_SESSIONS s WHERE s.player_id=b.player_id AND COALESCE(s.session_end,UTC_TIMESTAMP())>b.week_start),0) weekly_actual,
 COALESCE((SELECT SUM(amount) FROM PURCHASES x WHERE x.player_id=b.player_id AND DATE_FORMAT(DATE_ADD(x.purchase_date,INTERVAL b.timezone_offset_minutes MINUTE),'%Y-%m')=DATE_FORMAT(DATE_ADD(UTC_TIMESTAMP(),INTERVAL b.timezone_offset_minutes MINUTE),'%Y-%m')),0) monthly_actual
 FROM boundaries b
)
SELECT player_id,username,'Daily playtime' limit_type,daily_playtime_limit limit_value,daily_actual actual_value,daily_actual>daily_playtime_limit is_exceeded FROM actual
UNION ALL SELECT player_id,username,'Weekly playtime',weekly_playtime_limit,weekly_actual,weekly_actual>weekly_playtime_limit FROM actual
UNION ALL SELECT player_id,username,'Monthly spending',monthly_spending_limit,monthly_actual,monthly_actual>monthly_spending_limit FROM actual;
