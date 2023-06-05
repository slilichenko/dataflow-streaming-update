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

import com.google.api.services.bigquery.model.TableFieldSchema;
import com.google.api.services.bigquery.model.TableSchema;
import java.util.List;
import org.apache.beam.sdk.Pipeline;
import org.apache.beam.sdk.io.gcp.bigquery.BigQueryIO;
import org.apache.beam.sdk.io.gcp.pubsub.PubsubIO;
import org.apache.beam.sdk.io.gcp.pubsub.PubsubMessage;
import org.apache.beam.sdk.options.PipelineOptionsFactory;
import org.apache.beam.sdk.transforms.ParDo;
import org.apache.beam.sdk.values.PCollection;

public class PubSubToBigQueryIngestionPipeline {
    public static void main(String[] args) {
        IngestionPipelineOptions options =
                PipelineOptionsFactory.fromArgs(args).withValidation().as(IngestionPipelineOptions.class);

        run(options);
    }

    private static void run(IngestionPipelineOptions options) {
        Pipeline pipeline = Pipeline.create(options);

        String tableName = options.getDatasetName() + '.' + options.getTableName();

        PCollection<PubsubMessage> input =
                pipeline.begin()
                        .apply(
                                "Read PubSub",
                                PubsubIO.readMessages()
                                        .fromSubscription(options.getSubscription()));

        input.apply("Transform", ParDo.of(new EventPayloadToTableRow()))
                .apply(
                        "Save To BigQuery",
                        BigQueryIO.writeTableRows()
                                .to(tableName)
                                .withMethod(BigQueryIO.Write.Method.STREAMING_INSERTS)
                                .withCreateDisposition(
                                        BigQueryIO.Write.CreateDisposition.CREATE_NEVER)
                                .withWriteDisposition(BigQueryIO.Write.WriteDisposition.WRITE_APPEND)
                                .withSchema(getEventTableSchema()));

        pipeline.run();
    }

    private static TableSchema getEventTableSchema() {
        return new TableSchema()
                .setFields(
                        List.of(
                                new TableFieldSchema()
                                        .setName("publish_ts")
                                        .setType("TIMESTAMP")
                                        .setMode("REQUIRED"),
                                new TableFieldSchema()
                                        .setName("pipeline_type")
                                        .setType("STRING")
                                        .setMode("REQUIRED"),
                                new TableFieldSchema()
                                        .setName("dst_ip")
                                        .setType("STRING")
                                        .setMode("REQUIRED"),
                                new TableFieldSchema()
                                        .setName("dst_port")
                                        .setType("INT64")
                                        .setMode("REQUIRED"),
                                new TableFieldSchema()
                                        .setName("src_ip")
                                        .setType("STRING")
                                        .setMode("REQUIRED"),
                                new TableFieldSchema()
                                        .setName("bytes_sent")
                                        .setType("INT64")
                                        .setMode("REQUIRED"),
                                new TableFieldSchema()
                                        .setName("bytes_received")
                                        .setType("INT64")
                                        .setMode("REQUIRED"),
                                new TableFieldSchema()
                                        .setName("user_id")
                                        .setType("STRING")
                                        .setMode("REQUIRED"),
                                new TableFieldSchema()
                                        .setName("process_name")
                                        .setType("STRING")
                                        .setMode("REQUIRED")));
    }
}
