#standardSQL
CREATE VIEW IF NOT EXISTS covid19.daily_new_cases AS
WITH daily AS
(
	SELECT state, county, date,  LPAD(CAST(fips AS string),5,"0") as fips,
	cases - lead(cases) OVER recent as new_cases, cases,
	deaths - lead(deaths) OVER recent as new_deaths, deaths
	FROM covid19.us_counties
	WINDOW recent AS (PARTITION BY state, county ORDER BY date DESC)
)
SELECT daily.*,
avg(new_cases) OVER rolling AS avg_new_cases_7da,
avg(new_deaths) OVER rolling AS avg_new_deaths_7da,
FROM daily
WINDOW rolling AS (PARTITION BY state, county ORDER BY date DESC ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING)
;
CREATE VIEW IF NOT EXISTS covid19.most_recent_totals AS
WITH most_recent AS (
	SELECT state, county, date, LPAD(CAST(fips AS string),5,"0") AS fips,
	row_number() OVER latest as rownum,
	cases - lead(cases) OVER latest as new_cases,
	deaths - lead(deaths) OVER latest as new_deaths,
	cases as tot_cases,
	deaths as tot_deaths
	FROM covid19.us_counties
	WINDOW latest AS (PARTITION BY state, county ORDER BY date DESC )
)
SELECT state, county, fips, date, new_cases, tot_cases, new_deaths, tot_deaths,
c.county_geom,
CASE
  WHEN county="New York City" THEN 8399000
    WHEN county="Kansas City" THEN 491918
      ELSE total_pop END as total_pop
FROM most_recent
LEFT OUTER JOIN
  `bigquery-public-data.census_bureau_acs.county_2018_5yr` p
ON
  (most_recent.fips = p.geo_id)
LEFT OUTER JOIN
  `bigquery-public-data.utility_us.us_county_area` c
ON
  (most_recent.fips = CONCAT(state_fips_code, county_fips_code) )
LEFT OUTER JOIN
  bigquery-public-data.utility_us.us_states_area s
ON
  (c.state_fips_code = s.state_fips_code)
WHERE rownum = 1
