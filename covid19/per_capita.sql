#standardSQL
create or replace table covid19.us_totals_per_capita as
select *, safe_divide(avg_new_deaths_7da,avg_new_cases_7da) as cfr_7da from covid19.per_capita_totals
