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

import com.google.api.client.json.GenericJson;
import com.google.api.client.json.gson.GsonFactory;
import com.google.api.services.bigquery.model.TableRow;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import org.apache.beam.sdk.io.gcp.pubsub.PubsubMessage;
import org.apache.beam.sdk.options.PipelineOptions;
import org.apache.beam.sdk.transforms.DoFn;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class EventPayloadToTableRow extends DoFn<PubsubMessage, TableRow> {
    private static final long serialVersionUID = 1L;
    public static final Logger LOG = LoggerFactory.getLogger(EventPayloadToTableRow.class);
    private GsonFactory gson;
    private String pipelineType;

    @StartBundle
    public void startBundle(PipelineOptions pipelineOptions) {
        gson = GsonFactory.getDefaultInstance();
        pipelineType = pipelineOptions.as(IngestionPipelineOptions.class).getType();
    }

    @ProcessElement
    public void process(
            @Element PubsubMessage message, ProcessContext context, OutputReceiver<TableRow> out) {
        GenericJson event;
        try (ByteArrayInputStream input = new ByteArrayInputStream(message.getPayload())) {
            event = gson.createJsonParser(input).parse(GenericJson.class);
        } catch (IOException e) {
            LOG.error("Failed to parse payload: ", e);
            return;
        }
        TableRow row = new TableRow();
        row.set("publish_ts", context.timestamp());
        row.set("pipeline_type", pipelineType);

        row.set("id", event.get("id"));
        // TODO: something is odd with this conversion. It loses precision.
        // The documentation states that it should be milliseconds, but
        row.set("request_ts", ((Number)event.get("request_timestamp")).longValue()/1000);
        row.set("dst_ip", event.get("destination_ip"));
        row.set("dst_port", event.get("destination_port"));
        row.set("src_ip", event.get("source_ip"));
        row.set("bytes_sent", event.get("bytes_sent"));
        row.set("bytes_received", event.get("bytes_received"));
        row.set("user_id", event.get("user"));
        row.set("process_name", event.get("process"));

        out.output(row);
    }
}
