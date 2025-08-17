-- Create CTE with columns category, avg_csat_category, total_count_category, total_count_overall
WITH category_metrics AS (SELECT category, AVG(csat_score) AS avg_csat_category,
                         COUNT(unique_id) AS total_count_by_category,
												(SELECT COUNT(unique_id) FROM csat_data_tableau) AS total_count_overall
                                                 FROM csat_data_tableau
												 GROUP BY category)
-- Calculating the expected new overall csat if the Order Related csat_score increases by 2
-- Using weighted averages 
SELECT
    SUM(
        CASE
            WHEN category = 'Order Related'
            THEN (4.10 + 0.2) * (total_count_by_category * 1.0 / total_count_overall)
            ELSE avg_csat_category * (total_count_by_category * 1.0 / total_count_overall)
        END
    ) AS projected_overall_csat
FROM
category_metrics