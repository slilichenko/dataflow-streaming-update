#!/usr/bin/env bash
#
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e
set -u

function pipeline_has_started_processing() {
  local project_id=$1
  local pipeline_id=$2
  local query_file=query.txt
  local query_result=query_result.json

  # JSON doesn't allow multiline literals...
  # TODO: this QML can/should be refined. For now we are just trying to get any signal that data is being processed.
  printf '
{
  "pageSize": 100,
  "query": "fetch dataflow_job| metric '\''dataflow.googleapis.com/job/element_count'\''| filter (metric.job_id == '\''%s'\'' && metric.pcollection == '\''Transform.out0'\'')| group_by 5m, [value_element_count_mean: mean(value.element_count)]| every 1m| group_by [], [row_count: row_count()]"
}
' "${pipeline_id}" > $query_file

  curl --no-progress-meter --request POST \
    "https://monitoring.googleapis.com/v3/projects/${project_id}/timeSeries:query" \
    --header "Authorization: Bearer $(gcloud auth print-access-token)" \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --data "@$query_file" \
    --compressed > $query_result

  local transform_pcollection_element_count
  transform_pcollection_element_count=$(jq -r .timeSeriesData[0].pointData[0].values[0].int64Value < $query_result)

  if [[ $transform_pcollection_element_count = 'null' ]]; then
      echo "Metrics API doesn't show any data being processed yet for pipeline $pipeline_id"
      return 1
  fi

  if (( transform_pcollection_element_count > 0 )); then
    echo "Pipeline $pipeline_id processed at least ${transform_pcollection_element_count} elements"
    return 0
  else
    echo "Pipeline $pipeline_id hasn't yet processed elements in the Transform DoFn."
  fi
}



source ./get-terraform-output.sh

echo "Checking the status of currently running pipelines..."
JOB_NAME_PATTERN='data-processing-main-*'
pipeline_ids=$(gcloud dataflow jobs list --region "$GCP_REGION" --filter="NAME:${JOB_NAME_PATTERN} AND STATE:Running" --format="get(JOB_ID)")

id_array=($pipeline_ids)

case "${#id_array[@]}" in

0)  echo "No current pipeline running. Starting a new one."
    ./start-main-pipeline.sh
    exit 0;
    ;;

1)  echo "Starting pipeline update process..."
    pipeline_id_to_replace=${id_array[0]}
    ;;

*)  echo "There are ${#id_array[@]} running pipelines."
    echo "Apparently the previous update process is not yet completed. You can manually shut down the pipeline with the lower number."
    exit 0;
   ;;
esac

current_worker_count=$(gcloud compute instances list --filter="labels.dataflow_job_id:${pipeline_id_to_replace}" --format="get(NAME)" | wc -l)
# For simplicity, currently we use the same number of workers as the running pipeline. This can be adjusted.
replacement_worker_count=$((current_worker_count))

echo "Starting a new pipeline with restricted autoscaling of exactly ${replacement_worker_count} worker ..."
./start-main-pipeline.sh ${replacement_worker_count}

replacement_pipeline_id=$(<last_launched_pipeline.id)

wait_start=$SECONDS
TIMEOUT_IN_SECS=600
while true
do
  sleep 15
  echo "Checking if the new pipeline ${replacement_pipeline_id} started processing..."
  pipeline_has_started_processing "${PROJECT_ID}" "${replacement_pipeline_id}" && break
  if ((SECONDS - wait_start > TIMEOUT_IN_SECS)); then
    echo "Couldn't determine if the new pipeline is processing the data, but reached the timeout of $TIMEOUT_IN_SECS seconds"
    break
  fi
done


echo "Starting draining the original pipeline..."
gcloud dataflow jobs drain "${pipeline_id_to_replace}" --region "${GCP_REGION}"

DEFAULT_MIN_WORKERS=2
DEFAULT_MAX_WORKERS=30

echo "Changing autoscaling parameters of the new pipeline..."
./update-pipeline-scaling.sh "${PROJECT_ID}" "${GCP_REGION}" "${replacement_pipeline_id}" ${DEFAULT_MIN_WORKERS} ${DEFAULT_MAX_WORKERS}


