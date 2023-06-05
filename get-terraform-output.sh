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

export PROJECT_ID=$(terraform -chdir=terraform output -raw project_id)
export GCP_REGION=$(terraform -chdir=terraform output -raw region)
export BQ_DATASET=$(terraform -chdir=terraform output -raw bq-dataset)
export TABLE_NAME=$(terraform -chdir=terraform output -raw table-name)
export EVENT_GENERATOR_TEMPLATE=$(terraform -chdir=terraform output -raw event-generator-template)
export EVENT_TOPIC=$(terraform -chdir=terraform output -raw event-topic)
export NO_UPDATE_SUBSCRIPTION=$(terraform -chdir=terraform output -raw event-no-update-sub)
export UPDATE_SUBSCRIPTION=$(terraform -chdir=terraform output -raw event-update-sub)
export DATAFLOW_SA=$(terraform -chdir=terraform output -raw dataflow-sa)
export DATAFLOW_TEMP_BUCKET=$(terraform -chdir=terraform output -raw dataflow-temp-bucket)