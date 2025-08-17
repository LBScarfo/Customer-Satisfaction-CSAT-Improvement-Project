-- 1. Check for NULL values in order_id column
SELECT COUNT(*) AS null_count
FROM csat_data
WHERE order_id IS NULL;
-- result 0
-- 2. Check for empty strings or strings containing only whitespace (including hidden chars) in order_id
-- Expected: Some rows may contain invisible characters that should be treated as NULL
SELECT COUNT(*) FROM csat_data WHERE LENGTH(TRIM(order_id)) = 0;
-- result 18230
-- 3. Count total rows before charset change (to verify no rows lost)
SELECT COUNT(*) AS total_rows_before FROM csat_data;
-- result 85895
-- 4. Count question marks before charset change (to detect existing ? characters)
SELECT COUNT(*) AS question_mark_count_before FROM csat_data
WHERE unique_id LIKE '%?%' OR channel_name LIKE '%?%' OR category LIKE '%?%' OR
      subcategory LIKE '%?%' OR customer_remarks LIKE '%?%' OR order_id LIKE '%?%' OR
      agent_name LIKE '%?%' OR supervisor LIKE '%?%' OR manager LIKE '%?%' OR
      tenure_bucket LIKE '%?%' OR agent_shift LIKE '%?%';
-- result 2502
-- 5. Change character set & collation to latin1_swedish_ci to better handle certain whitespace characters
ALTER TABLE csat_data CONVERT TO CHARACTER SET latin1 COLLATE latin1_swedish_ci;
-- 6. Count total rows after charset change (should match total_rows_before)
SELECT COUNT(*) AS total_rows_after FROM csat_data;
-- result 85895
-- 7. Count question marks after charset change (should be same or lower than before if no corruption)
SELECT COUNT(*) AS question_mark_count_after FROM csat_data
WHERE unique_id LIKE '%?%' OR channel_name LIKE '%?%' OR category LIKE '%?%' OR
      subcategory LIKE '%?%' OR customer_remarks LIKE '%?%' OR order_id LIKE '%?%' OR
      agent_name LIKE '%?%' OR supervisor LIKE '%?%' OR manager LIKE '%?%' OR
      tenure_bucket LIKE '%?%' OR agent_shift LIKE '%?%';
-- result 2502
-- 8. Check for replacement characters (�) indicating encoding issues after charset change
SELECT COUNT(*) AS replacement_char_count FROM csat_data
WHERE unique_id LIKE _latin1 '�' COLLATE latin1_swedish_ci
OR channel_name LIKE _latin1 '�' COLLATE latin1_swedish_ci
OR category LIKE _latin1 '�' COLLATE latin1_swedish_ci
OR subcategory LIKE _latin1 '�' COLLATE latin1_swedish_ci
OR customer_remarks LIKE _latin1 '�' COLLATE latin1_swedish_ci
OR order_id LIKE _latin1 '�' COLLATE latin1_swedish_ci
OR agent_name LIKE _latin1 '�' COLLATE latin1_swedish_ci
OR supervisor LIKE _latin1 '�' COLLATE latin1_swedish_ci
OR manager LIKE _latin1 '�' COLLATE latin1_swedish_ci
OR tenure_bucket LIKE _latin1 '�' COLLATE latin1_swedish_ci
OR agent_shift LIKE _latin1 '�' COLLATE latin1_swedish_ci;
-- result 0
-- 9. Clean all columns by removing hidden whitespace characters:
--    non-breaking space (CHAR(160)), tab (CHAR(9)), line feed (CHAR(10)), and carriage return (CHAR(13)),
--    then trim leading and trailing spaces to ensure data consistency.
--    This step fixes invisible characters that can cause filtering and comparison issues.
UPDATE csat_data
SET
  unique_id = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(unique_id, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')),
  channel_name = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(channel_name, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')),
  category = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(category, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')),
  subcategory = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(subcategory, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')),
  customer_remarks = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(customer_remarks, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')),
  order_id = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(order_id, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')),
  agent_name = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(agent_name, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')),
  supervisor = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(supervisor, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')),
  manager = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(manager, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')),
  tenure_bucket = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(tenure_bucket, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '')),
  agent_shift = TRIM(REPLACE(REPLACE(REPLACE(REPLACE(agent_shift, CHAR(160), ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), ''));
  -- 10a. Select rows with empty or whitespace-only strings that would be converted to NULL (preview before update)
SELECT
  COUNT(*) AS empty_or_whitespace_count
FROM csat_data
WHERE LENGTH(TRIM(unique_id)) = 0
   OR LENGTH(TRIM(channel_name)) = 0
   OR LENGTH(TRIM(category)) = 0
   OR LENGTH(TRIM(subcategory)) = 0
   OR LENGTH(TRIM(customer_remarks)) = 0
   OR LENGTH(TRIM(order_id)) = 0
   OR LENGTH(TRIM(agent_name)) = 0
   OR LENGTH(TRIM(supervisor)) = 0
   OR LENGTH(TRIM(manager)) = 0
   OR LENGTH(TRIM(tenure_bucket)) = 0
   OR LENGTH(TRIM(agent_shift)) = 0;
-- result 63255
-- 10b. Convert empty or whitespace-only strings to NULL for consistent missing data representation
UPDATE csat_data
SET
  unique_id = CASE WHEN LENGTH(TRIM(unique_id)) = 0 THEN NULL ELSE unique_id END,
  channel_name = CASE WHEN LENGTH(TRIM(channel_name)) = 0 THEN NULL ELSE channel_name END,
  category = CASE WHEN LENGTH(TRIM(category)) = 0 THEN NULL ELSE category END,
  subcategory = CASE WHEN LENGTH(TRIM(subcategory)) = 0 THEN NULL ELSE subcategory END,
  customer_remarks = CASE WHEN LENGTH(TRIM(customer_remarks)) = 0 THEN NULL ELSE customer_remarks END,
  order_id = CASE WHEN LENGTH(TRIM(order_id)) = 0 THEN NULL ELSE order_id END,
  agent_name = CASE WHEN LENGTH(TRIM(agent_name)) = 0 THEN NULL ELSE agent_name END,
  supervisor = CASE WHEN LENGTH(TRIM(supervisor)) = 0 THEN NULL ELSE supervisor END,
  manager = CASE WHEN LENGTH(TRIM(manager)) = 0 THEN NULL ELSE manager END,
  tenure_bucket = CASE WHEN LENGTH(TRIM(tenure_bucket)) = 0 THEN NULL ELSE tenure_bucket END,
  agent_shift = CASE WHEN LENGTH(TRIM(agent_shift)) = 0 THEN NULL ELSE agent_shift END;
-- rows updated 63255 
-- 10c. Verify conversion: count rows now NULL in each column after update
SELECT 'unique_id' AS column_name, COUNT(*) AS null_count FROM csat_data WHERE unique_id IS NULL
UNION ALL
SELECT 'channel_name', COUNT(*) FROM csat_data WHERE channel_name IS NULL
UNION ALL
SELECT 'category', COUNT(*) FROM csat_data WHERE category IS NULL
UNION ALL
SELECT 'subcategory', COUNT(*) FROM csat_data WHERE subcategory IS NULL
UNION ALL
SELECT 'customer_remarks', COUNT(*) FROM csat_data WHERE customer_remarks IS NULL
UNION ALL
SELECT 'order_id', COUNT(*) FROM csat_data WHERE order_id IS NULL
UNION ALL
SELECT 'agent_name', COUNT(*) FROM csat_data WHERE agent_name IS NULL
UNION ALL
SELECT 'supervisor', COUNT(*) FROM csat_data WHERE supervisor IS NULL
UNION ALL
SELECT 'manager', COUNT(*) FROM csat_data WHERE manager IS NULL
UNION ALL
SELECT 'tenure_bucket', COUNT(*) FROM csat_data WHERE tenure_bucket IS NULL
UNION ALL
SELECT 'agent_shift', COUNT(*) FROM csat_data WHERE agent_shift IS NULL;
-- result 75381 (57151 customer_remarks + 18230 order_id)
-- 11. Check if hidden-only values remain in any other column (non-visible characters after trimming)
SELECT 'unique_id' AS column_name, COUNT(*) AS hidden_only_count
FROM csat_data
WHERE LENGTH(unique_id) > 0 AND LENGTH(TRIM(unique_id)) = 0
UNION ALL
SELECT 'channel_name', COUNT(*)
FROM csat_data
WHERE LENGTH(channel_name) > 0 AND LENGTH(TRIM(channel_name)) = 0
UNION ALL
SELECT 'category', COUNT(*)
FROM csat_data
WHERE LENGTH(category) > 0 AND LENGTH(TRIM(category)) = 0
UNION ALL
SELECT 'subcategory', COUNT(*)
FROM csat_data
WHERE LENGTH(subcategory) > 0 AND LENGTH(TRIM(subcategory)) = 0
UNION ALL
SELECT 'customer_remarks', COUNT(*)
FROM csat_data
WHERE LENGTH(customer_remarks) > 0 AND LENGTH(TRIM(customer_remarks)) = 0
UNION ALL
SELECT 'agent_name', COUNT(*)
FROM csat_data
WHERE LENGTH(agent_name) > 0 AND LENGTH(TRIM(agent_name)) = 0
UNION ALL
SELECT 'supervisor', COUNT(*)
FROM csat_data
WHERE LENGTH(supervisor) > 0 AND LENGTH(TRIM(supervisor)) = 0
UNION ALL
SELECT 'manager', COUNT(*)
FROM csat_data
WHERE LENGTH(manager) > 0 AND LENGTH(TRIM(manager)) = 0
UNION ALL
SELECT 'tenure_bucket', COUNT(*)
FROM csat_data
WHERE LENGTH(tenure_bucket) > 0 AND LENGTH(TRIM(tenure_bucket)) = 0
UNION ALL
SELECT 'agent_shift', COUNT(*)
FROM csat_data
WHERE LENGTH(agent_shift) > 0 AND LENGTH(TRIM(agent_shift)) = 0;
-- result 0 hidden-only values found, confirming data cleaning was successful
-- 12. Revert character set & collation to utf8mb4_unicode_ci for future compatibility
ALTER DATABASE customer_satisfaction_project CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
ALTER TABLE csat_data CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- 13. Count total rows after reverting charset (should remain consistent)
SELECT COUNT(*) AS total_rows_after_revert FROM csat_data;
-- result 85895 (consistent)
-- 14. Count question marks after reverting charset (should remain consistent)
SELECT COUNT(*) AS question_mark_count_after_revert FROM csat_data
WHERE unique_id LIKE '%?%' OR channel_name LIKE '%?%' OR category LIKE '%?%' OR
      subcategory LIKE '%?%' OR customer_remarks LIKE '%?%' OR order_id LIKE '%?%' OR
      agent_name LIKE '%?%' OR supervisor LIKE '%?%' OR manager LIKE '%?%' OR
      tenure_bucket LIKE '%?%' OR agent_shift LIKE '%?%';
      -- result 2502 (consistent)
-- 15. Replace NULL values in customer_remarks with 'No remark' to avoid missing info
UPDATE csat_data
SET customer_remarks = 'No remark'
WHERE customer_remarks IS NULL;
-- 57151 rows affected
-- 16. Check if order_id is unique
SELECT order_id, COUNT(*) AS count_order_id
FROM csat_data
WHERE order_id IS NOT NULL
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY count_order_id DESC;
-- result no duplicate order_id
-- 17. Replace NULL values in order_id with 'Missing#'
SET @missing_counter = 0;
UPDATE csat_data
SET order_id = CONCAT('MISSING ', (@missing_counter := @missing_counter + 1))
WHERE order_id IS NULL OR order_id = '' OR order_id = 'Missing' OR order_id = 'missing';
-- 18. Final validation: count NULLs to check remaining missing data
SELECT 'order_id' AS column_name, COUNT(*) AS null_count FROM csat_data WHERE order_id IS NULL
UNION ALL
SELECT 'customer_remarks', COUNT(*) FROM csat_data WHERE customer_remarks IS NULL;
-- result each column 0, data set has been properly cleaned


