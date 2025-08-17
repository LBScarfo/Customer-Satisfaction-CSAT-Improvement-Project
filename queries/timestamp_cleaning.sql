-- Validate and clean impossible timestamps for reported/responded events
-- Purpose: Ensure chronological and logical consistency between reporting and response times.
-- Method: Identify responses before reports, simultaneous email events, and suspicious midnight times.
-- Note: No rows dropped. Only corrected timestamps to NULL where values were clearly invalid.
-- 1. verify data range for issue_reported_at column
SELECT 
  MIN(issue_reported_at) AS oldest_reported_date,
  MAX(issue_reported_at) AS newest_reported_date
FROM csat_data;
-- result '2023-07-28 20:42:00', '2023-08-31 23:58:00'
-- 2. verify data range for issue_responded_at column
SELECT 
MIN(issue_responded_at) AS oldest_responded_date,
MAX(issue_responded_at) AS newest_responded_date
FROM csat_data;
-- result '2023-08-01 00:00:00', '2023-08-31 23:59:00'
-- 3. check how many responses appear at 00:00:00 (time might be incorrect)
SELECT COUNT(*) AS midnight_response_count
FROM csat_data
WHERE TIME(issue_responded_at) = '00:00:00';
-- result 3441 
-- 4. check how many responses are registered before reports
SELECT
  COUNT(*) AS invalid_response_count
FROM csat_data
WHERE issue_responded_at < issue_reported_at;
-- 3127 (invalid_response)
-- 5. check how many responses are registered at the same time of reports and channel_name is Email
-- issues can't be reported via e-mail and be answered at the same time
SELECT
  COUNT(*) AS invalid_response_count
FROM csat_data
WHERE issue_responded_at = issue_reported_at AND channel_name = 'Email';
-- result 120 (invalid_response)
-- 6. check day/s with the most invalid_response
SELECT DATE(issue_responded_at), COUNT(*) AS invalid_response_count 
FROM csat_data 
WHERE (issue_responded_at < issue_reported_at) 
   OR (issue_responded_at = issue_reported_at AND channel_name = 'Email') 
GROUP BY DATE(issue_responded_at) 
ORDER BY invalid_response_count DESC;
-- result: on 2023-08-28 there are 3107 invalid_responses
-- 7. isolate incorrect timestamp for all values
SELECT COUNT(*)
FROM csat_data
WHERE
  issue_responded_at < issue_reported_at
  OR (issue_responded_at = issue_reported_at AND channel_name = 'Email');
-- result 3247
-- 8. Nullify responses before reports
UPDATE csat_data 
SET issue_responded_at = NULL 
WHERE issue_responded_at < issue_reported_at; 
-- 9. Nullify same-time email channel responses 
UPDATE csat_data 
SET issue_responded_at = NULL 
WHERE issue_responded_at = issue_reported_at 
AND channel_name = 'Email';
-- 10. Check if invalid timestamps have been removed correctly
SELECT COUNT(*) AS invalid_response_count
FROM csat_data
WHERE issue_responded_at < issue_reported_at
   OR (issue_responded_at = issue_reported_at AND channel_name = 'Email');
-- result 0, invalid timestamps have been removed correctly
-- 11. Check remaining 00:00:00 timestamps
SELECT COUNT(*) AS remaining_midnight_timestamp FROM csat_data 
WHERE TIME(issue_responded_at) = '00:00:00' OR TIME(issue_reported_at)= '00:00:00';
 -- result 333
 -- 12. check if any issue_responded_at are registered at 00:00:00 for agents on a Morning, Afternoon or Evening shift
 -- Night shift is any shift starting after 8:00 PM and ending before 6:00 AM, Split shift is not described
 SELECT COUNT(*) FROM (SELECT issue_responded_at , agent_shift FROM csat_data 
                       WHERE TIME(issue_responded_at) = '00:00:00' AND (agent_shift <> 'Night' AND agent_shift <> 'Split')) AS derived;
-- result 297 
-- 13. Setting issue_responded_at as NULL when recorded for agents not working on Night or Split shift
UPDATE csat_data
SET issue_responded_at = NULL
WHERE TIME(issue_responded_at) = '00:00:00'
  AND agent_shift <> 'Night'
  AND agent_shift <> 'Split';
-- 14. Count how many rows still exists with issue_responded_at or issue_reported_at 00:00:00
SELECT COUNT(*) AS remaining_midnight_timestamp FROM csat_data 
WHERE (TIME(issue_responded_at) = '00:00:00' OR TIME(issue_reported_at)= '00:00:00'); 
-- result 37, use select to visualize results 
SELECT * FROM csat_data 
WHERE (TIME(issue_responded_at) = '00:00:00' OR TIME(issue_reported_at)= '00:00:00'); 
-- Just one row still has suspiscious issue_reported_at timestamp, it is an inbound at 00:00:00 with issue_responded_at NULL
-- 15. Checking data from backup
SELECT * FROM csat_data_backup WHERE order_id = '2c0e82b6-5ac3-4f20-a174-0710dc12d56d';
-- issue_reported_at and issue_responded_at have both timestamp 00:00:00, agent_shift is Evening
-- 16. issue reported_at for order_id '2c0e82b6-5ac3-4f20-a174-0710dc12d56d' is an error and it has to be nullified
UPDATE csat_data
SET issue_reported_at = NULL
WHERE order_id = '2c0e82b6-5ac3-4f20-a174-0710dc12d56d';
-- 17. final check 
SELECT channel_name, issue_reported_at, issue_responded_at, agent_shift FROM csat_data 
WHERE (TIME(issue_responded_at) = '00:00:00' OR TIME(issue_reported_at)= '00:00:00'); 
-- the data remaining will not be nullified as it looks plausible given agent shift and context


