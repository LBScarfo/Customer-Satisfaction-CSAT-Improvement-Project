-- Perform data validation with random checks between MySQL query results and tableau data in worksheets
-- 1. Worksheet AVG CSAT by tenure, expected results in order by job tenure ASC 4.15, 4.26, 4.30, 4.35, 4.27 
SELECT DISTINCT avg_tenure_bucket_csat, tenure_bucket_num FROM csat_data_tableau ORDER BY tenure_bucket_num ASC;
-- Result: data matches
-- 2. Worksheet Team CSAT & Composition 
-- Check on team composition and avg csat_score 
-- Expected results Amelia Tanaka CSAT 4.31, job tenure: 57.89% num 5, 42.11% num 3
-- Austin Jhonson CSAT 4.12, job tenure:  37.93% num 2, 62.07 num 1
-- Oliver Nguyen CSAT 3.50, job tenure: 100% num 5 
SELECT
    supervisor,
    tenure_bucket_num,
    ROUND(AVG(avg_csat_per_tenure) OVER(PARTITION BY supervisor), 2) AS avg_csat_per_supervisor,
    tenure_count,
    ROUND(tenure_count * 100.0 / SUM(tenure_count) OVER(PARTITION BY supervisor), 2) AS percentage
FROM (
    SELECT
        supervisor,
        tenure_bucket_num,
        AVG(csat_score) AS avg_csat_per_tenure,
        COUNT(DISTINCT agent_name) AS tenure_count
    FROM
        csat_data_tableau
    WHERE
        supervisor IN ('Amelia Tanaka', 'Austin Johnson', 'Oliver Nguyen')
    GROUP BY
        supervisor,
        tenure_bucket_num
) AS subquery_alias
ORDER BY
    supervisor,
    tenure_bucket_num
LIMIT 100000;
-- Result: CSAT and tenure_bucket % match for the 3 supervisors selected 
-- Worksheet Average CSAT score by category, check on AVG csat_score by category
-- Expected results Others 3.43, App/website 4.40, Feedback 4.16
SELECT category, ROUND(AVG(csat_score),2)
FROM csat_data_tableau
WHERE category IN ('Others', 'App/website', 'Feedback')
GROUP BY category
LIMIT 100000;
-- Result: data matches 
-- 3. Worksheet Subcategories CSAT, check on AVG csat_score by sucategory
-- Expected result Call disconnected 3.59, Customer Requested Modifications 4.54, Delayed 4.01
SELECT subcategory, ROUND(AVG(csat_score),2)
FROM csat_data_tableau
WHERE subcategory IN ('Call disconnected', 'Customer Requested Modifications', 'Delayed')
GROUP BY subcategory
LIMIT 100000;
-- Result: data matched
-- 4. Worksheet CSAT vs Response Time
-- Expected results Response Time Bucket 0-30 min AVG csat_score 4.39, contacts 60.086, 
-- Response time bucket 3+ days AVG csat_score 3.14, contacts 309
SELECT response_time_bucket, ROUND(AVG(csat_score),2), COUNT(unique_id)
FROM csat_data_tableau
WHERE response_time_bucket IN ('0–30 min', '3+ days') 
GROUP BY response_time_bucket
LIMIT 100000;
-- Result data matches
-- 5 Worksheet Agent one card + Worksheet Agent two card
-- Joining csat_data table since the agent_shift was imported separetly into tableau and does not appear in the csat_data_tableau table
-- Expected results Alan Cruz: supervisor Isabella wong, Tenure Bucket 5 (> 90 days), Agent Shift Evening, Contact 45, CSAT 4.80
-- Thomas Martin: supervisor Wyatt Kim, Tenure bucket 1 (On training), Agent Shift Morning, Contacts 90, CSAT 3.93
SELECT t.agent_name,  t.supervisor, t.tenure_bucket_num, c.agent_shift, COUNT(t.unique_id), ROUND(AVG(t.csat_score),2)
FROM csat_data_tableau t
JOIN csat_data c
ON t.unique_id = c.unique_id
WHERE t.agent_name IN ('Alan Cruz', 'Thomas Martin')
GROUP BY t.agent_name, t.supervisor, t.tenure_bucket_num, c.agent_shift;
-- Result data matches for both the worksheets tested
-- 6. Worksheet Agent Deepdive category 
-- Expected results Michael Torres Returns 13, Order Related 6, Refund Related 3, Payment Related 1, Sophzilla Related 1
-- Alan Davies Returns 12, order Related 10
SELECT agent_name, category, COUNT(order_id)
FROM csat_data_tableau
WHERE agent_name IN ('Michael Torres', 'Alan Davies')
GROUP BY category, agent_name
LIMIT 100000;
-- Result data matches 
-- 7. Worksheet Agent deepdive Subcategory
-- Expected result Carmen Young Reverse Pickup Enquiry 4, Order status enquiry 3, Not Needed 3, Delayed 8, Missing 1
-- Andre Adams Not Needed 8, Delayed 37, Reverse Pickup Enquiry 8, Missing 1, Damaged 1
SELECT agent_name, subcategory, COUNT(order_id)
FROM csat_data_tableau
WHERE agent_name IN ('Carmen Young', 'Andre Adams')
GROUP BY subcategory, agent_name
LIMIT 100000;
-- Result data matches
-- 7. Categories Overview
-- Expected result Count of unique_id with category Returns 44,093, Count of unique_id with category Cancellation 2,212
SELECT COUNT(unique_id), category 
FROM csat_data_tableau
WHERE category IN ('Returns', 'Cancellation')
GROUP BY category; 
-- Result data matches
-- 8. Agent Performance Deepdive dashboard, Dynamic Peer Comparison CSAT
-- Result expected AVG csat for agents with agent_shift Night and tenure_bucket_num 3 (31-60 days) = 4.29
-- Joining csat_data table since the agent_shift was imported separetly into tableau and does not appear in the csat_data_tableau table
SELECT d.agent_shift, t.tenure_bucket_num, ROUND(AVG(d.csat_score),2)
FROM csat_data d
JOIN csat_data_tableau t
ON d.unique_id = t.unique_id
WHERE d.agent_shift = 'Night' AND t.tenure_bucket_num = 3
GROUP BY d.agent_shift, t.tenure_bucket_num




