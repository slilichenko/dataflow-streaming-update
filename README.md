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
./start-pipeline-to-be-updated.
```

### Update the pipeline
We are going to use the same pipeline code to update the existing pipeline - there is no difference
in processing time

```shell
./update-pipeline.sh
```

### Analyse the data


## Contributing

Contributions to this repo are always welcome and highly encouraged.

See [CONTRIBUTING](CONTRIBUTING.md) for more information how to get started.

Please note that this project is released with a Contributor Code of Conduct. By participating in
this project you agree to abide by its terms. See [Code of Conduct](CODE_OF_CONDUCT.md) for more
information.

## License

Apache 2.0 - See [LICENSE](LICENSE) for more information.