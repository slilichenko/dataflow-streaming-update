/*
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.google.cloud.solutions;

import org.apache.beam.runners.dataflow.options.DataflowPipelineOptions;
import org.apache.beam.sdk.options.Default;
import org.apache.beam.sdk.options.Validation;

public interface IngestionPipelineOptions extends DataflowPipelineOptions {

    @Validation.Required
    String getSubscription();

    void setSubscription(String value);

    @Validation.Required
    String getType();

    void setType(String value);

    @Default.String("ingestion_test")
    String getDatasetName();

    void setDatasetName(String value);

    @Default.String("event")
    String getTableName();

    void setTableName(String value);
}
