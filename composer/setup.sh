#!/bin/bash

# Setup script for the Composer environment used in the Chicago Taxifare demo. The setup script will
# take around 20-25 minutes to run. This script was written with running in Cloud Shell in mind.

PROJECT_ID=$(gcloud config get-value project)
REGION=us-central1
BUCKET_NAME=${PROJECT_ID}-ml

gsutil mb -l ${REGION} gs://${BUCKET_NAME}

bq mk -d demos

gcloud pubsub topics create chicago-taxi-pipeline

gcloud composer environments create chicago-demo-environment \
  --location $REGION \
  --python-version 3 \
  --image-version composer-1.9.2-airflow-1.10.2

gcloud composer environments update chicago-demo-environment \
  --location $REGION \
  --update-env-variables=VERSION_NAME=v_default

DAGS_FOLDER=$(gcloud composer environments describe chicago-demo-environment \
   --location us-central1   --format="get(config.dagGcsPrefix)")

gsutil cp gs://cloud-training/CPB200/Composer/chicago_taxi_dag.py ${DAGS_FOLDER}/
gsutil cp gs://cloud-training/CPB200/Composer/trainer.tar gs://${BUCKET_NAME}/chicago_taxi/code/

# Copyright 2020 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.