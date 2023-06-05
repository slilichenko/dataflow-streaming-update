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

source ./get-terraform-output.sh

number_of_workers=
if [ "$#" -eq 1 ]; then
  number_of_workers=$1
fi

next_pipeline_number () {
  JOB_NAME_PREFIX='data-processing-main-'
  local job_names
  job_names=$(gcloud dataflow jobs list --region "$GCP_REGION" --filter="NAME:${JOB_NAME_PREFIX}*" --format="get(NAME)")

  local next_number=1


  local name_array=($job_names)
  for (( i=0; i<${#name_array[@]}; i++ )) ; do
    local job_name="${name_array[$i]}"
    local job_number=${job_name:${#JOB_NAME_PREFIX}}
    if (( job_number > next_number )); then
        ((next_number=job_number+1))
    fi

  done

  echo -n "$next_number"
}

./start-pipeline.sh 'main' "${UPDATE_SUBSCRIPTION}" "$(next_pipeline_number)" "${number_of_workers}"