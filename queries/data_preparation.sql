CREATE TABLE csat_data_tableau AS
-- creating a CTE to prep data for calculations
WITH csat_with_tenure AS (SELECT *,
						   -- assigning numerical values to tenure bucket for correlation and sorting purposes
                           -- calculating response time in minutes 
						   CASE 
                               WHEN tenure_bucket = 'On Job Training' THEN 1 
                               WHEN tenure_bucket = '0-30' THEN 2
                               WHEN tenure_bucket = '31-60' THEN 3
                               WHEN tenure_bucket = '61-90' THEN 4
                               WHEN tenure_bucket = '>90' THEN 5
                           END AS tenure_bucket_num,
                           TIMESTAMPDIFF(MINUTE, issue_reported_at, issue_responded_at) AS response_time_minutes
						  FROM csat_data), 
-- casting response_time_minutes in buckets for reasability 
	 csat_final AS (SELECT *,
						                CASE 
                                             WHEN response_time_minutes IS NULL THEN NULL
                                             WHEN response_time_minutes BETWEEN 0 AND 30 THEN '0–30 min'
                                             WHEN response_time_minutes BETWEEN 31 AND 60 THEN '31–60 min'
                                             WHEN response_time_minutes BETWEEN 61 AND 480 THEN '1 hr 1 min–8 hr'
											 WHEN response_time_minutes BETWEEN 481 AND 1440 THEN '8 hr 1 min–24 hr'
                                             WHEN response_time_minutes BETWEEN 1441 AND 2880 THEN '1 day 1 min–2 days'
                                             WHEN response_time_minutes BETWEEN 2881 AND 4320 THEN '2 days 1 min–3 days'
                                             ELSE '3+ days'
										END AS response_time_bucket
					FROM csat_with_tenure)
                          
-- selecting data from CTE csat_final
SELECT unique_id, channel_name, category, subcategory, order_id, agent_name,
       supervisor, manager, csat_score, issue_reported_at, issue_responded_at, response_time_minutes, response_time_bucket, tenure_bucket_num,
       ROUND(AVG(csat_score) OVER (PARTITION BY manager),2) AS avg_manager_csat, -- calculating average csat for agents with the same manager
       ROUND(AVG(csat_score) OVER (PARTITION BY supervisor),2) AS avg_supervisor_csat, -- calculating average csat for agents with the same supervisor
       ROUND(AVG(csat_score) OVER (PARTITION BY agent_name),2) AS avg_agent_csat, -- calculating average csat by agent_name
       ROUND(AVG(csat_score) OVER (PARTITION BY category),2) AS avg_category_csat, -- calculating average csat by category
       ROUND(AVG(csat_score) OVER (PARTITION BY tenure_bucket_num),2) AS avg_tenure_bucket_csat -- calculating average cstat by tenure bucket
FROM csat_final
LIMIT 90000