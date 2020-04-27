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
bq query </home/drfib13/demo/covid19/create_views.sh
bq query </home/drfib13/demo/covid19/materialize.sh
