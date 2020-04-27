#standardSQL
CREATE VIEW IF NOT EXISTS covid19.daily_new_cases AS
SELECT state, county, date,
cases - lead(cases) OVER recent as new_cases, cases,
deaths - lead(deaths) OVER recent as new_deaths, deaths
FROM `cpb100-151023.covid19.us_counties`
WINDOW recent AS (PARTITION BY state, county ORDER BY date DESC)
ORDER BY state, county, date DESC
;
CREATE VIEW IF NOT EXISTS covid19.most_recent_totals AS
WITH most_recent AS (
SELECT state, county, date,
row_number() OVER latest as rownum,
cases as tot_cases,
deaths as tot_deaths
FROM `cpb100-151023.covid19.us_counties`
WINDOW latest AS (PARTITION BY state, county ORDER BY date DESC )
)
SELECT state, county, date, tot_cases, tot_deaths
FROM most_recent
WHERE rownum = 1
