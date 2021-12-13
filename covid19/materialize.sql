#standardSQL
create or replace table covid19.us_daily_cases as
select *,
lead(avg_new_cases_7da,28) over (PARTITION BY state, county ORDER BY date DESC) as avg_new_cases_7da_lag_28da
from covid19.daily_new_cases
;
create or replace table covid19.us_totals as
select * from covid19.most_recent_totals
