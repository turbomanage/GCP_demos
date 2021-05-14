#!/bin/bash
# Usage: ./tag_push_deploy img_name
IMG=$1
SVC=$IMG
docker tag httpd gcr.io/$DEVSHELL_PROJECT_ID/$IMG
docker push gcr.io/$DEVSHELL_PROJECT_ID/$IMG
gcloud run deploy $SVC --image=gcr.io/$DEVSHELL_PROJECT_ID/$IMG --port=80
