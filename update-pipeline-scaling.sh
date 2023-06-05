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

project_id=$1
region=$2
job_id=$3
min_num_workers=$4
max_num_workers=$5


status_code=$(curl -X PUT "https://dataflow.googleapis.com/v1b3/projects/${project_id}/locations/${region}/jobs/${job_id}?updateMask=runtime_updatable_params.max_num_workers,runtime_updatable_params.min_num_workers" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H 'Content-Type: application/json' \
  -H "Accept: application/json" \
  --data "\
{
    \"runtime_updatable_params\": {
        \"min_num_workers\": ${min_num_workers},
        \"max_num_workers\": ${max_num_workers}
    }
}" \
  --write-out '%{http_code}' \
  --silent --output /dev/null)

if [[ "$status_code" -ne 200 ]] ; then
  echo "Failed to update scaling parameters. Return code: ${status_code}"
  exit 1
else
  echo "Successfully updated scaling parameters."
  exit 0
fi