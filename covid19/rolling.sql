#standardSQL
CREATE VIEW IF NOT EXISTS covid19.rolling_cfr AS
SELECT state, county, fips, date, new_cases, new_deaths,
cases, deaths,
avg(new_cases) OVER rolling AS avg_new_cases_7da,
avg(new_deaths) OVER rolling AS avg_new_deaths_7da,
FROM covid19.us_daily_cases
WINDOW rolling AS (PARTITION BY state, county ORDER BY date DESC ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING)
;
create or replace table covid19.us_rolling as
SELECT *,
lead(avg_new_cases_7da,28) over (PARTITION BY state, county ORDER BY date DESC) as avg_new_cases_7da_lag_28da
FROM covid19.rolling_cfr
