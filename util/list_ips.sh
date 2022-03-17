#!/bin/bash
for project in  $(gcloud projects list --format="value(projectId)")
do
  echo "ProjectId:  $project"
  for instance in $(gcloud compute instances list --project $project --quiet --format="list(EXTERNAL_IP)")
   do
     echo "    -> Instance $instance"
   done
done
