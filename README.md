# Refinery

[![GitHub License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](https://opensource.org/licenses/MIT)
[![Gitpod: ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod&style=flat-square)](https://gitpod.io/from-referrer/)
[![Maintenence status: best-effort](https://img.shields.io/badge/Maintained%3F-best--effort-yellow?style=flat-square)](https://github.com/vlaaaaaaad)

## Introduction

[Refinery](https://github.com/honeycombio/refinery) is a proxy from [Honeycomb](https://www.honeycomb.io) which offers trace-aware sampling.

This module contains the Terraform infrastructure code that creates the required AWS resources to run [Refinery](https://github.com/honeycombio/refinery) in AWS, including the following:

- A **V**irtual **P**rivate **C**loud (VPC)
- A SSL certificate using **A**mazon **C**ertificate **M**anager (ACM)
- An **A**pplication **L**oad **B**alancer (ALB)
- A DNS Record using AWS Route53 which points to ALB
- An [AWS **E**lastic **C**loud **S**ervice (ECS)](https://aws.amazon.com/ecs/) Cluster leveraging Spot [AWS Fargate](https://aws.amazon.com/fargate/) to run the Refinery Docker image
- Two Parameters in [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html) to store the Refinery configuration and rules and access them natively in Fargate
- A single-node Redis (cluster mode disabled) Cluster in [AWS ElastiCache](https://aws.amazon.com/elasticache/) to be used by Refinery for high-availability and peer discovery

![Diagram showing the architecture. The Honeycomb-instrumented apps use Route53 to connect to the ALB. The ALB routes traffic to refinery containers running in Fargate, in different AZs and public subnets. The Refinery containers connect to a single-AZ Redis and communicate between them.](./assets/diagram.svg)

## Gotchas

Due to Fargate on ECS having [no support for configuration files](https://github.com/aws/containers-roadmap/issues/56), the configuration is Base64-encoded, stored in [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html), and then put in the Container Secrets. When Refinery starts, it decodes the secret and creates the config file on disk. This leads to two limitations:

- configuration files cannot be bigger than 8Kb
- a [custom image](https://github.com/Vlaaaaaaad/refinery-fargate-image) has to be used as the upstream image does not have `sh` or `base64` included

## Versions

This module requires **Terraform 0.13**.

This module is in beta (pre-`0.1`) which means **any new release can have breaking changes**.

## Usage

### As a standalone project

Using this module as a standalone project is **only recommended for testing**.

1. Clone this github repository:

```console
$ git clone git@github.com:vlaaaaaaad/terraform-aws-fargate-refinery.git

$ cd terraform-aws-fargate-refinery
```

2. Copy the sample `terraform.tfvars.sample` into `terraform.tfvars` and specify the required variables there.

3. Run `terraform init` to download required providers and modules.

4. Run `terraform apply` to apply the Terraform configuration and create the required infrastructure.

5. Run `terraform output refinery_url` to get URL where Refinery is reachable. (Note: It may take a minute or two for the URL to become reachable the first time)

### As a Terraform module

Using this as a Terraform module allows integration with your existing Terraform configurations and pipelines.

```hcl
module "refinery" {
  # Use git to pull the module from GitHub, the latest version
  # source = "git@github.com:vlaaaaaaad/terraform-aws-fargate-refinery.git?ref=main"
  # or
  # Pull a specific version from Terraform Module Registry
  source  = "Vlaaaaaaad/fargate-refinery/aws"
  version = "0.1.0"

  # REQUIRED: DNS (without trailing dot)
  route53_zone_name = "example.com"

  # REQUIRED: Refinery configs
  refinery_sampler_configs = [
    {
      dataset_name = "_default",
      options = [
        {
          "name"  = "Sampler"
          "value" = "DeterministicSampler"
        },
        {
          "name"  = "SampleRate"
          "value" = 1
        },
      ]
    },
    {
      dataset_name = "my-test-app",
      options = [
        {
          "name"  = "Sampler"
          "value" = "DynamicSampler"
        },
        {
          "name"  = "SampleRate"
          "value" = "2"
        },
        {
          "name"  = "FieldList"
          "value" = "['app.run']"
        },
        {
          "name"  = "UseTraceLength"
          "value" = "true"
        },
        {
          "name"  = "AddSampleRateKeyToTrace"
          "value" = "true"
        },
        {
          "name"  = "AddSampleRateKeyToTraceField"
          "value" = "meta.refinery.dynsampler_key"
        },
      ]
    },
  ]

  # Optional: override the name
  name = "refinery"

  # Optional: customize the VPC
  azs                = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  vpc_cidr           = "10.20.0.0/16"
  vpc_public_subnets = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]

  # Optional: use pre-exiting ACM Certificate instead of creating and validating a new certificate
  certificate_arn = "arn:aws:acm:eu-west-1:135367859851:certificate/70e008e1-c0e1-4c7e-9670-7bb5bd4f5a84"

  # Optional: Send Refinery logs&metrics to Honeycomb, instead of ECS&nowhere
  refinery_logger_option   = "honeycomb"
  refinery_logger_api_key  = "00000000000000000000000000000000"
  refinery_metrics_option  = "honeycomb"
  refinery_metrics_api_key = "00000000000000000000000000000000"
}
```

### As a Terraform module, as part of existing infrastructure

Using this module also allows integration with existing AWS resources -- VPC, Subnets, IAM Roles. Specify the required arguments.

> **WARNING**: This was not tested.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13, < 0.14 |
| aws | ~> 3 |
| local | ~> 1.2 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 3 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| acm\_certificate\_arn | The ARN of a certificate issued by AWS ACM. If empty, a new ACM certificate will be created and validated using Route53 DNS | `string` | `""` | no |
| acm\_certificate\_domain\_name | The Route53 domain name to use for ACM certificate. Route53 zone for this domain should be created in advance. Specify if it is different from value in `route53_zone_name` | `string` | `""` | no |
| alb\_additional\_sgs | A list of additional Security Groups to attach to the ALB | `list(string)` | `[]` | no |
| alb\_internal | Whether the load balancer is internal or external | `bool` | `false` | no |
| alb\_log\_bucket\_name | The name of the S3 bucket (externally created) for storing load balancer access logs. Required if `alb_logging_enabled` is true | `string` | `""` | no |
| alb\_log\_location\_prefix | The S3 prefix within the `log_bucket_name` under which logs are stored | `string` | `""` | no |
| alb\_logging\_enabled | Whether if the ALB will log requests to S3 | `bool` | `false` | no |
| azs | A list of availability zones that you want to use from the Region | `list(string)` | `[]` | no |
| create\_route53\_record | Whether to create Route53 record for Refinery | `bool` | `true` | no |
| ecs\_capacity\_providers | A list of short names or full Amazon Resource Names (ARNs) of one or more capacity providers to associate with the cluster. Valid values also include `FARGATE` and `FARGATE_SPOT` | `list(string)` | <pre>[<br>  "FARGATE_SPOT"<br>]</pre> | no |
| ecs\_cloudwatch\_log\_retention\_in\_days | The retention time for CloudWatch Logs | `number` | `30` | no |
| ecs\_container\_memory\_reservation | The amount of memory (in MiB) to reserve for Refinery | `number` | `4096` | no |
| ecs\_default\_capacity\_provider\_strategy | The capacity provider strategy to use by default for the cluster. Can be one or more. List of map with corresponding items in docs. See [Terraform Docs](https://www.terraform.io/docs/providers/aws/r/ecs_cluster.html#default_capacity_provider_strategy) | `list(any)` | <pre>[<br>  {<br>    "capacity_provider": "FARGATE_SPOT"<br>  }<br>]</pre> | no |
| ecs\_execution\_role | The ARN of an existing IAM Role that will be used ECS to start the Tasks | `string` | `""` | no |
| ecs\_service\_additional\_sgs | A list of additional Security Groups to attach to the ECS Service | `list(string)` | `[]` | no |
| ecs\_service\_assign\_public\_ip | Whether the ECS Tasks should be assigned a public IP. Should be true, if ECS service is using public subnets. See [AWS Docs](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_cannot_pull_image.html) | `bool` | `true` | no |
| ecs\_service\_deployment\_maximum\_percent | The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment | `number` | `300` | no |
| ecs\_service\_deployment\_minimum\_healthy\_percent | The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment | `number` | `100` | no |
| ecs\_service\_desired\_count | The number of instances of the task definition to place and keep running | `number` | `2` | no |
| ecs\_service\_subnets | If using a pre-existing VPC, subnet IDs to be used for the ECS Service | `list(string)` | `[]` | no |
| ecs\_settings | A list of maps with cluster settings. For example, this can be used to enable CloudWatch Container Insights for a cluster. See [Terraform Docs](https://www.terraform.io/docs/providers/aws/r/ecs_cluster.html#setting) | `list(any)` | <pre>[<br>  {<br>    "name": "containerInsights",<br>    "value": "enabled"<br>  }<br>]</pre> | no |
| ecs\_task\_cpu | The number of CPU units to be used by Refinery | `number` | `2048` | no |
| ecs\_task\_memory | The amount of memory (in MiB) to be used by Samprixy | `number` | `4096` | no |
| ecs\_task\_role | The ARN of an existin IAM Role that will be used by the Refinery Task | `string` | `""` | no |
| ecs\_use\_new\_arn\_format | Whether the AWS Account has opted in to the new longer ARN format which allows tagging ECS | `bool` | `false` | no |
| execution\_policies\_arn | A list of ARN of the policies to attach to the execution role | `list(string)` | <pre>[<br>  "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",<br>  "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"<br>]</pre> | no |
| firelens\_configuration | The FireLens configuration for the Refinery container. This is used to specify and configure a log router for container logs. See [AWS Docs](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_FirelensConfiguration.html) | <pre>object({<br>    type    = string<br>    options = map(string)<br>  })</pre> | `null` | no |
| image\_repository | The Refinery image repository | `string` | `"vlaaaaaaad/refinery-fargate-image"` | no |
| image\_repository\_credentials | The container repository credentials; required when using a private repo.  This map currently supports a single key; `"credentialsParameter"`, which should be the ARN of a Secrets Manager's secret holding the credentials | `map(string)` | `null` | no |
| image\_tag | The Refinery image tag to use | `string` | `"v0.14.0"` | no |
| name | The name to use on all resources created (VPC, ALB, etc) | `string` | `"refinery"` | no |
| redis\_node\_type | The instance type used for the Redis cache cluster. See [all available values on the AWS website](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html) | `string` | `"cache.t2.micro"` | no |
| redis\_port | The Redis port | `string` | `"6379"` | no |
| redis\_subnets | If using a pre-exiting VPC, subnet IDs to be used for Redis | `list(string)` | `[]` | no |
| redis\_version | The Redis version | `string` | `"5.0.6"` | no |
| refiery\_sampler\_dry\_run | The flag to enable DryRun mode for Refinery | `bool` | `false` | no |
| refinery\_accepted\_api\_keys | The list of Honeycomb API keys that the proxy will accept | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| refinery\_cache\_capacity | The number of spans to cache | `number` | `1000` | no |
| refinery\_default\_sample\_rate | The sampler rate for the default sampler | `number` | `1` | no |
| refinery\_dry\_run\_field\_name | The key to add to each event when in DryRun mode | `string` | `"refinery_kept"` | no |
| refinery\_log\_level | The Refinery log level | `string` | `"debug"` | no |
| refinery\_logger\_api\_key | The API key to use to send Refinery logs to Honeycomb | `string` | `""` | no |
| refinery\_logger\_dataset\_name | The dataset to which to send Refinery logs to | `string` | `"Refinery Logs"` | no |
| refinery\_logger\_option | The loger option for refinery | `string` | `"logrus"` | no |
| refinery\_max\_alloc | The maximum memory to use | `number` | `0` | no |
| refinery\_metrics\_api\_key | The API key used to send Refinery metrics to Honeycomb | `string` | `""` | no |
| refinery\_metrics\_dataset | The dataset to which to send Refinery metrics to | `string` | `"Refinery Metrics"` | no |
| refinery\_metrics\_option | The metrics option for refinery | `string` | `"prometheus"` | no |
| refinery\_metrics\_reporting\_interval | The interval (in seconds) to wait between sending metrics to Honeycomb | `number` | `3` | no |
| refinery\_peer\_buffer\_size | The number of events to buffer before seding to peers | `number` | `10000` | no |
| refinery\_sampler\_configs | The Refinery sampling rules configuration | <pre>list(<br>    object(<br>      {<br>        dataset_name = string<br>        options      = list(map(string))<br>      }<br>    )<br>  )</pre> | <pre>[<br>  {<br>    "dataset_name": "_default",<br>    "options": [<br>      {<br>        "name": "Sampler",<br>        "value": "DynamicSampler"<br>      },<br>      {<br>        "name": "SampleRate",<br>        "value": 1<br>      }<br>    ]<br>  }<br>]</pre> | no |
| refinery\_send\_delay | The delay to wait after a trace is complete, before sending | `string` | `"2s"` | no |
| refinery\_send\_ticker | The duration to use to check for traces to send | `string` | `"100ms"` | no |
| refinery\_trace\_timeout | The amount of time to wait for a trace to be completed before sending | `string` | `"60s"` | no |
| refinery\_upstream\_buffer\_size | The number of events to buffer before sending to Honeycomb | `number` | `10000` | no |
| route53\_record\_name | The name of Route53 record to create ACM certificate in and main A-record. If `null` is specified, `var.name` is used instead. Provide empty string to point root domain name to ALB | `string` | `null` | no |
| route53\_zone\_name | The Route53 zone name to create ACM certificate in and main A-record, without trailing dot | `string` | `""` | no |
| tags | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| vpc\_alb\_subnets | If using a pre-exiting VPC, subnet IDs to be used for the ALBs | `list(string)` | `[]` | no |
| vpc\_cidr | The CIDR block for the VPC which will be created if `vpc_id` is not specified | `string` | `"172.16.0.0/16"` | no |
| vpc\_id | The ID of an existing VPC where resources will be created | `string` | `""` | no |
| vpc\_public\_subnets | A list of public subnets inside the VPC | `list(string)` | <pre>[<br>  "172.16.0.0/18",<br>  "172.16.64.0/18",<br>  "172.16.128.0/18"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| alb\_dns\_name | The DNS name of the ALB |
| alb\_sg | The ID of the Security Group attached to the ALB |
| alb\_zone\_id | The ID of the Route53 zone containing the ALB record |
| ecs\_cluster\_id | The ARN of the ECS cluster hosting Refinery |
| refinery\_ecs\_security\_group | The ID of the Security group assigned to the Refinery ECS Service |
| refinery\_ecs\_task\_definition | The task definition for the Refinery ECS service |
| refinery\_execution\_role\_arn | The IAM Role used to create the Refinery tasks |
| refinery\_task\_role\_arn | The Atlantis ECS task role name |
| refinery\_url | The URL to use for Refinery |
| vpc\_id | The ID of the VPC that was created or passed in |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

This module is created and maintained by [Vlad Ionescu](https://github.com/vlaaaaaaad), in his free time. This is a best-effort allocation of time.

This module was inspired by [Anton Babenko's](https://github.com/antonbabenko) [terraform-aws-atlantis](https://github.com/terraform-aws-modules/terraform-aws-atlantis), which was, in turn, inspired by [Seth Vargo's](https://github.com/sethvargo) [atlantis-on-gke](https://github.com/sethvargo/atlantis-on-gke). Yay, open-source!

## License

MIT licensed. See [LICENSE](./LICENSE) details.
