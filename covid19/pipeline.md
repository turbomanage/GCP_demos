# Creating a Pipeline and Dashboard for COVID-19 Data
The New York Times is publishing COVID-19 data on a county-by-county basis daily. In this demo, we create a pipeline to import the data into BigQuery daily and then create a map and DataStudio dashboard to visualize the data.
## Explore the Data
First let's look at the sample data from the [NYT repo on Github](https://raw.githubusercontent.com/nytimes/covid-19-data/master/):

```csv
us-counties.csv:

date,county,state,fips,cases,deaths
2020-01-21,Snohomish,Washington,53061,1,0
2020-01-22,Snohomish,Washington,53061,1,0
2020-01-23,Snohomish,Washington,53061,1,0
2020-01-24,Cook,Illinois,17031,1,0
2020-01-24,Snohomish,Washington,53061,1,0
2020-01-25,Orange,California,06059,1,0
2020-01-25,Cook,Illinois,17031,1,0
2020-01-25,Snohomish,Washington,53061,1,0
...
```
The counties CSV contains a row for each county and each day containing the CUMULATIVE number of cases and deaths in the county. The ```fips``` column contains the [FIPS county code](https://en.wikipedia.org/wiki/FIPS_county_code) (Federal Information Processing Standard), which allows us to join the COVID data easily with other BigQuery public datasets containing population, land area, and geographic boundaries for each county in the US.

 # Create a Pipeline
 In order to process this data most effectively in a variety of tools, let's import it into BigQuery. We'll do this using a simple shell script to download the data using ```wget``` and import it using ```bq load```. Here's the script:
 
 ```shell script
#!/bin/bash
cd /home/drfib13/covid19
export today="$(date +"%Y-%m-%d")"
mkdir $today
cd $today
wget https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv
wget https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-states.csv
cd ..
gsutil cp -r "$today" gs://drfib-usc1/covid19/
bq load --source_format=CSV --autodetect --replace \
	covid19.us_counties \
	gs://drfib-usc1/covid19/"$today"/us-counties.csv
bq load --source_format=CSV --autodetect --replace \
	covid19.us_states \
	gs://drfib-usc1/covid19/"$today"/us-states.csv
bq query </home/drfib13/demo/covid19/create_views.sql
bq query </home/drfib13/demo/covid19/materialize.sql
```
In a nutshell, we create a new directory for each day's imported data, then download it and import it into BigQuery. This is a super lazy script, as it automatically detects the schema and replaces the table each day, but NYT is updating the file in place each day, so that's all we need.

To run the script once a day, we can just use good old Unix ```cron```. Every GCP project gets one free f1-micro class instance. To get your pipeline running in your own project, first create a BigQuery dataset named "covid19" in your GCP project, then start a new f1-micro instance and SSH into it. From there, run the following commands:

```shell script
sudo apt-get update
sudo apt-get install git curl
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```
Now you're ready to install the pipeline code and run the first import.
```shell script
# Download the repo
git clone https://github.com/GoogleCloudPlatform/training-data-analyst```
# Create a link to the COVID-19 demo code
mkdir demo
cd demo
ln -s training-data-analyst/courses/data-engineering/demos/covid19 covid19
# Try it out
cd covid19
bash import.sh
```
You should see output showing successful download of two files and several BigQuery jobs completed. At the prompt, type
```shell script
bq ls covid19
```
You should see the following output:
```
       tableId         Type    Labels   Time Partitioning   Clustered Fields  
 -------------------- ------- -------- ------------------- ------------------ 
  daily_new_cases      VIEW                                                   
  most_recent_totals   VIEW                                                   
  us_counties          TABLE                                                  
  us_daily_cases       TABLE                                                  
  us_states            TABLE                                                  
  us_totals            TABLE
```
In the BigQuery console, navigate to the us_counties table and click Preview. You should see a row for each county and date just like the CSV.

To run the script as a cron job every day, run `crontab -e`. That will open the crontab editor. At the end of the file, paste in the following entry: 
```shell script
00 17 * * * /home/[USER_NAME]/demo/covid19/import.sh
```
Replace [USER_NAME] with your actual Unix username shown at the prompt. Save the file. Now the import script will run once a day at 17:00 UTC, which is usually when the latest updates are available in the NYT github repo. 

## Enhance the data
The raw data has the runnign cumulative totals for each county, but we'd like to compute the new cases each day by county as well as have a single table which contains only the most recent totals for each county. We'll look at each of these in turn.
### Compute daily new cases by county
We can do this easily using a BigQuery analytical function. Analytical functions let you define a window of the data over which to perform the analysis. In order to compute the difference of cases for each day, we need a window for each state and county with the data in descending order by date. We define a window named ```recent``` like this:
```sql
WINDOW recent AS (PARTITION BY state, county ORDER BY date DESC)
```
Now we can use a function which operates over the defined window. Among BigQuery's analytical functions, the _navigation functions_ let you compare rows with preceding or subsequent rows. We'll use the LEAD() function to compute the difference between a county's number of cases and deaths from the preceding day, and we'll further make this a BigQuery view called `daily_new_cases`:
```sql
CREATE VIEW IF NOT EXISTS covid19.daily_new_cases AS
SELECT state, county, date,
cases - LEAD(cases) OVER recent as new_cases, cases,
deaths - LEAD(deaths) OVER recent as new_deaths, deaths
FROM covid19.us_counties
WINDOW recent AS (PARTITION BY state, county ORDER BY date DESC)
``` 
The fields new_cases and new_deaths are computed as the difference between the current row and the next (leading) row. Because we've ordered the window by descending date, the next row represents yesterday's data. Let's query this view for a specific county and look at the results:
```sql
SELECT * FROM covid19.daily_new_cases
WHERE state='Colorado' and county='Douglas'
``` 
The output looks like this:
```
+----------+---------+------------+-----------+-------+------------+--------+
|  state   | county  |    date    | new_cases | cases | new_deaths | deaths |
+----------+---------+------------+-----------+-------+------------+--------+
| Colorado | Douglas | 2020-04-25 |        11 |   425 |         -2 |     19 |
| Colorado | Douglas | 2020-04-24 |        15 |   414 |          0 |     21 |
| Colorado | Douglas | 2020-04-23 |         7 |   399 |          0 |     21 |
| Colorado | Douglas | 2020-04-22 |         8 |   392 |          4 |     21 |
| Colorado | Douglas | 2020-04-21 |         3 |   384 |          0 |     17 |

```
Note that the first value of new_deaths is negative. This happens when a county revises the cumulative total downward for some reason. Now we have a view that computes the daily new cases for us, which is going to be very useful for our dashboard.

### Store only the most recent totals
In addition to showing the daily new cases, we'll want to show the total number of cases on a dashboard. In order to support this, let's extract just the latest data for each county. We could filter by today's or yesterday's date, but won't always work because some counties report later than others. Therefore, we just want the latest data for each county. Once again, a BigQuery navigation function comes to the rescue. We'll define the same window again but now select only the first row in the window, which represents the most recent data regardless of the specific date. The resulting view looks like this:
```sql
CREATE VIEW IF NOT EXISTS covid19.most_recent_totals AS
WITH most_recent AS (
    SELECT state, county, date,
    ROW_NUMBER() OVER latest as rownum,
    cases as tot_cases,
    deaths as tot_deaths
    FROM covid19.us_counties
    WINDOW latest AS (PARTITION BY state, county ORDER BY date DESC )
)
SELECT state, county, date, tot_cases, tot_deaths
FROM most_recent
WHERE rownum = 1
```
This view selects only the first row from each partition (county), so we'll now have only one row for each county containing the latest data.

