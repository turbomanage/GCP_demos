#standardSQL
CREATE VIEW IF NOT EXISTS covid19.per_capita_totals AS
WITH daily AS 
(
	SELECT state, county, fips, date, new_cases, new_deaths,
	tot_cases as cases, tot_deaths as deaths,
	avg(new_cases) OVER rolling AS avg_new_cases_7da,
	avg(new_deaths) OVER rolling AS avg_new_deaths_7da,
	FROM covid19.us_totals
	WINDOW rolling AS (PARTITION BY state, county ORDER BY date DESC ROWS BETWEEN CURRENT ROW AND 6 FOLLOWING)
)
SELECT daily.*, c.county_geom,
  CASE 
	  WHEN county="New York City" THEN 8399000 
		  WHEN county="Kansas City" THEN 491918 
			  ELSE total_pop END as total_pop
				FROM daily
				LEFT OUTER JOIN
				  bigquery-public-data.census_bureau_acs.county_2018_5yr p
				ON
				  (daily.fips = p.geo_id)
				LEFT OUTER JOIN 
				  `bigquery-public-data.utility_us.us_county_area` c
				ON
				  (CAST(daily.fips AS string) = CONCAT(state_fips_code, county_fips_code) )
				LEFT OUTER JOIN
				  bigquery-public-data.utility_us.us_states_area s
				ON
				  (c.state_fips_code = s.state_fips_code)
;
create or replace table covid19.us_totals_per_capita as
select *, safe_divide(avg_new_deaths_7da,avg_new_cases_7da) as cfr_7da from covid19.per_capita_totals
