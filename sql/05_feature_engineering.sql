
-- ============================================================
-- Phase 3: Feature Engineering
-- ============================================================

-- Add prescribing quartile using NTILE window function
ALTER TABLE fact_opioid_analysis ADD COLUMN IF NOT EXISTS prescribing_quartile INTEGER;

UPDATE fact_opioid_analysis f
SET prescribing_quartile = q.quartile
FROM (
    SELECT state_abbrev,
           NTILE(4) OVER (ORDER BY opioid_rx_rate) AS quartile
    FROM fact_opioid_analysis
) q
WHERE f.state_abbrev = q.state_abbrev;
