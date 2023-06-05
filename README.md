# Dataflow Streaming Pipeline Update Test 

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=GITHUB_URL)

*Description*
Test code for low latency streaming pipeline updates

## Features

## Getting Started
1. Clone this repo and switch to the checked out directory
2. Designate or create a project to run the tests and create `terraform/terraform.tfvars` file with the following content:
```text
project_id = "<your project id>"
```
2. Create infrastructure to run:
```shell
cd terraform
terraform init
terraform apply
cd ..
```

## Running Tests
### Start the test harness
This will start a pipeline which will be generating synthetic events:

```shell
./start-event-generation.sh <rate>
```

A typical rate is tens of thousands of events per second. A Dataflow pipeline named `data-generator-<rate>`
will be started. You can simulate event load increases by starting additional pipelines. Note, that you can't start
several pipelines with exactly the same rate because the pipeline name needs to be unique.

You can see the current publishing load by summing the rates of all active data generation pipelines.

### Start the baseline consumption pipeline
This pipeline runs uninterrupted on a dedicated PubSub subscription. The goals are to collect the message
processing latencies under the perfect circumstances and the unique message ids in order to later compare them with
the pipelines being tested.

```shell
./start-baseline-pipeline.sh
```

### Start the pipeline which will be updated

```shell
./start-main-pipeline.sh
```

### Update the pipeline
We are going to use the same pipeline code to update the existing pipeline - there is no difference
in processing time

```shell
./update-pipeline.sh
```

### Analyse the data
All scripts below have time ranges defined in the beginning of the scripts. Adjust them as needed.

#### Event latencies comparison
Use the following query to compare latency of ingest of the baseline pipeline and the main pipeline:

```sql
DECLARE
  start_ts DEFAULT TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL -40 MINUTE);
DECLARE
  end_ts DEFAULT TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL -20 MINUTE);
WITH
  latency AS (
  SELECT
    pipeline_type,
    ingest_ts,
    publish_ts,
    TIMESTAMP_DIFF(ingest_ts, publish_ts, SECOND) latency_secs
  FROM
    pipeline_update.event
  WHERE
    publish_ts BETWEEN start_ts AND end_ts)
SELECT
  pipeline_type,
  COUNT(*) total_events,
  AVG(latency.latency_secs) average_latency_secs,
  MIN(latency.latency_secs) min_latency_secs,
  MAX(latency.latency_secs) max_latency_secs,
  STDDEV(latency.latency_secs) std_deviation
FROM
  latency
GROUP BY
  pipeline_type
ORDER BY
  pipeline_type;
```

#### Missing records
To check if there were missing records:
```sql
DECLARE
  start_ts DEFAULT TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL -40 MINUTE);
DECLARE
  end_ts DEFAULT TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL -20 MINUTE);
SELECT
  COUNT(*) missed_events,
FROM
  pipeline_update.event base
WHERE
  base.publish_ts BETWEEN start_ts
  AND end_ts
  AND pipeline_type = 'baseline'
  AND NOT EXISTS(
  SELECT
    *
  FROM
    pipeline_update.event main
  WHERE
    main.publish_ts BETWEEN start_ts
    AND end_ts
    AND pipeline_type = 'main'
    AND base.id = main.id);
```

#### Duplicates
Duplicate events
```sql
DECLARE
  start_ts DEFAULT TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL -40 MINUTE);
DECLARE
  end_ts DEFAULT TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL -20 MINUTE);

SELECT
  id,
  pipeline_type,
  COUNT(*) event_count,
FROM
  pipeline_update.event base
WHERE
  base.publish_ts BETWEEN start_ts
  AND end_ts
GROUP BY id, pipeline_type
HAVING event_count > 1
```

#### Duplicate statistics
```sql
DECLARE
  start_ts DEFAULT TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL -40 MINUTE);
DECLARE
  end_ts DEFAULT TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL -20 MINUTE);
WITH
  counts AS (
  SELECT
    COUNT(id) total_event_count,
    COUNT(DISTINCT id) event_distinct_count,
    pipeline_type,
  FROM
    pipeline_update.event base
  WHERE
    base.publish_ts BETWEEN start_ts
    AND end_ts
  GROUP BY
    pipeline_type)
SELECT
  event_distinct_count,
  counts.total_event_count - counts.event_distinct_count AS dups_count,
  (counts.total_event_count - counts.event_distinct_count)*100/counts.total_event_count dups_percentage,
  pipeline_type
FROM
  counts
ORDER BY
  pipeline_type DESC;
```

## Cleanup

```shell
./stop-event-generation.sh
./stop-processing-pipelines.sh
terraform -chdir terraform destroy 
```

## Contributing

Contributions to this repo are always welcome and highly encouraged.

See [CONTRIBUTING](CONTRIBUTING.md) for more information how to get started.

Please note that this project is released with a Contributor Code of Conduct. By participating in
this project you agree to abide by its terms. See [Code of Conduct](CODE_OF_CONDUCT.md) for more
information.

## License

Apache 2.0 - See [LICENSE](LICENSE) for more information.