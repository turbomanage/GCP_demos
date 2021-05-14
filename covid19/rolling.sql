#standardSQL
create or replace table covid19.us_rolling as
SELECT *,
lead(avg_new_cases_7da,28) over (PARTITION BY state, county ORDER BY date DESC) as avg_new_cases_7da_lag_28da
FROM `cpb100-151023.covid19.rolling_cfr` 
