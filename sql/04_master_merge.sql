
-- ============================================================
-- Phase 3: Master Merge — 4-CTE Join Query
-- Joins CMS prescribing + CDC deaths + AHRQ SDOH via dim_state
-- Output: fact_opioid_analysis (one row per state)
-- ============================================================

DROP TABLE IF EXISTS fact_opioid_analysis;

CREATE TABLE fact_opioid_analysis AS

WITH cte_prescribing AS (
    -- CTE 1: State-level prescribing metrics from CMS
    SELECT
        state_abbrev,
        total_opioid_claims,
        total_30day_fills,
        total_day_supply,
        total_opioid_cost,
        total_opioid_prescribers,
        distinct_opioid_drugs
    FROM clean_cms_state
),

cte_deaths AS (
    -- CTE 2: State-level opioid death counts from CDC
    SELECT
        state_abbrev,
        opioid_deaths,
        percent_complete,
        percent_pending_investigation,
        death_indicator
    FROM clean_cdc_state
),

cte_sdoh AS (
    -- CTE 3: State-level SDOH (population-weighted) from AHRQ
    SELECT
        state_abbrev,
        w_pct_poverty,
        w_pct_unemployed,
        w_median_income,
        w_gini_index,
        w_pct_uninsured,
        state_population,
        county_count
    FROM agg_state_sdoh
),

cte_merged AS (
    -- CTE 4: Join all three through dim_state
    SELECT
        d.state_abbrev,
        d.state_name,
        d.state_fips,
        d.census_region,
        d.census_division,

        -- Prescribing metrics
        rx.total_opioid_claims,
        rx.total_30day_fills,
        rx.total_day_supply,
        rx.total_opioid_cost,
        rx.total_opioid_prescribers,
        rx.distinct_opioid_drugs,

        -- Death metrics
        deaths.opioid_deaths,
        deaths.percent_complete AS cdc_percent_complete,
        deaths.death_indicator,

        -- SDOH metrics (population-weighted)
        sdoh.w_pct_poverty,
        sdoh.w_pct_unemployed,
        sdoh.w_median_income,
        sdoh.w_gini_index,
        sdoh.w_pct_uninsured,
        sdoh.state_population,

        -- Calculated rates
        ROUND(
            rx.total_opioid_claims * 1000.0 / NULLIF(sdoh.state_population, 0)
        , 2) AS opioid_rx_rate,

        ROUND(
            deaths.opioid_deaths * 100000.0 / NULLIF(sdoh.state_population, 0)
        , 2) AS death_rate_per_100k

    FROM dim_state d
    JOIN cte_prescribing rx ON d.state_abbrev = rx.state_abbrev
    JOIN cte_sdoh sdoh ON d.state_abbrev = sdoh.state_abbrev
    -- LEFT JOIN for CDC since not all states have death data
    LEFT JOIN cte_deaths deaths ON d.state_abbrev = deaths.state_abbrev
)

SELECT * FROM cte_merged
ORDER BY opioid_rx_rate DESC;
