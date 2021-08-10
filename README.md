# Refinery

[![GitHub License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](https://opensource.org/licenses/MIT)
[![Gitpod: ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod&style=flat-square)](https://gitpod.io/#https://github.com/vlaaaaaaad/terraform-aws-fargate-refinery)
[![Maintenance status: best-effort](https://img.shields.io/badge/Maintained%3F-best--effort-yellow?style=flat-square)](https://github.com/vlaaaaaaad)

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

![Diagram showing the architecture. The Honeycomb-instrumented apps use Route53 to connect to the ALB. The ALB routes traffic to Refinery containers running in Fargate, in different AZs and public subnets. The Refinery containers connect to a single-AZ Redis and communicate between them.](./assets/diagram.svg)

## Gotchas

Due to Fargate on ECS having [no support for configuration files](https://github.com/aws/containers-roadmap/issues/56), the configuration is Base64-encoded, stored in [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html), and then put in the Container Secrets. When Refinery starts, it decodes the secret and creates the config file on disk. This leads to two limitations:

- configuration files cannot be bigger than 8Kb
- a [custom image](https://github.com/Vlaaaaaaad/refinery-fargate-image) has to be used as the upstream image does not have `sh` or `base64` included

## Usage

### As a standalone project

Using this module as a standalone project is **only recommended for testing**.

1. Clone this github repository:

```console
$ git clone git@github.com:vlaaaaaaad/terraform-aws-fargate-refinery.git

$ cd terraform-aws-fargate-refinery
```

2. Copy the sample `terraform.tfvars.sample` into `terraform.tfvars` and specify the required variables there.

3. Create a `myrules.toml` file with your Refinery rules.

4. Run `terraform init` to download required providers and modules.

5. Run `terraform apply` to apply the Terraform configuration and create the required infrastructure.

6. Run `terraform output refinery_url` to get URL where Refinery is reachable. (Note: It may take a minute or two for the URL to become reachable the first time)

### As a Terraform module

Using this as a Terraform module allows integration with your existing Terraform configurations and pipelines.

```hcl
module "refinery" {
  # Use git to pull the module from GitHub, the latest version
  source = "git@github.com:vlaaaaaaad/terraform-aws-fargate-refinery.git?ref=main"
  # or
  # Pull a specific version from Terraform Module Registry
  # source  = "Vlaaaaaaad/fargate-refinery/aws"
  # version = "1.2.3-replace-me"

  # REQUIRED: DNS (without trailing dot)
  route53_zone_name = "example.com"

  # REQUIRED: Refinery config file
  refinery_rules_file_path = "${path.module}/myrules.toml"

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

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_refinery_rules_file_path"></a> [refinery\_rules\_file\_path](#input\_refinery\_rules\_file\_path) | The path to a toml files with the Refinery rules. Must be less than 8Kb | `any` | n/a | yes |
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | The ARN of a certificate issued by AWS ACM. If empty, a new ACM certificate will be created and validated using Route53 DNS | `string` | `""` | no |
| <a name="input_acm_certificate_domain_name"></a> [acm\_certificate\_domain\_name](#input\_acm\_certificate\_domain\_name) | The Route53 domain name to use for ACM certificate. Route53 zone for this domain should be created in advance. Specify if it is different from value in `route53_zone_name` | `string` | `""` | no |
| <a name="input_alb_additional_sgs"></a> [alb\_additional\_sgs](#input\_alb\_additional\_sgs) | A list of additional Security Groups to attach to the ALB | `list(string)` | `[]` | no |
| <a name="input_alb_internal"></a> [alb\_internal](#input\_alb\_internal) | Whether the load balancer is internal or external | `bool` | `false` | no |
| <a name="input_alb_log_bucket_name"></a> [alb\_log\_bucket\_name](#input\_alb\_log\_bucket\_name) | The name of the S3 bucket (externally created) for storing load balancer access logs. Required if `alb_logging_enabled` is true | `string` | `""` | no |
| <a name="input_alb_log_location_prefix"></a> [alb\_log\_location\_prefix](#input\_alb\_log\_location\_prefix) | The S3 prefix within the `log_bucket_name` under which logs are stored | `string` | `""` | no |
| <a name="input_alb_logging_enabled"></a> [alb\_logging\_enabled](#input\_alb\_logging\_enabled) | Whether if the ALB will log requests to S3 | `bool` | `false` | no |
| <a name="input_aws_cloudwatch_log_group_kms_key_id"></a> [aws\_cloudwatch\_log\_group\_kms\_key\_id](#input\_aws\_cloudwatch\_log\_group\_kms\_key\_id) | The ID of the KMS key to use when encrypting log data | `any` | `null` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | A list of availability zones that you want to use from the Region | `list(string)` | `[]` | no |
| <a name="input_create_route53_record"></a> [create\_route53\_record](#input\_create\_route53\_record) | Whether to create Route53 record for Refinery | `bool` | `true` | no |
| <a name="input_ecs_capacity_providers"></a> [ecs\_capacity\_providers](#input\_ecs\_capacity\_providers) | A list of short names or full Amazon Resource Names (ARNs) of one or more capacity providers to associate with the cluster. Valid values also include `FARGATE` and `FARGATE_SPOT` | `list(string)` | <pre>[<br>  "FARGATE_SPOT"<br>]</pre> | no |
| <a name="input_ecs_cloudwatch_log_retention_in_days"></a> [ecs\_cloudwatch\_log\_retention\_in\_days](#input\_ecs\_cloudwatch\_log\_retention\_in\_days) | The retention time for CloudWatch Logs | `number` | `30` | no |
| <a name="input_ecs_container_memory_reservation"></a> [ecs\_container\_memory\_reservation](#input\_ecs\_container\_memory\_reservation) | The amount of memory (in MiB) to reserve for Refinery | `number` | `4096` | no |
| <a name="input_ecs_default_capacity_provider_strategy"></a> [ecs\_default\_capacity\_provider\_strategy](#input\_ecs\_default\_capacity\_provider\_strategy) | The capacity provider strategy to use by default for the cluster. Can be one or more. List of map with corresponding items in docs. See [Terraform Docs](https://www.terraform.io/docs/providers/aws/r/ecs_cluster.html#default_capacity_provider_strategy) | `list(any)` | <pre>[<br>  {<br>    "capacity_provider": "FARGATE_SPOT"<br>  }<br>]</pre> | no |
| <a name="input_ecs_execution_role"></a> [ecs\_execution\_role](#input\_ecs\_execution\_role) | The ARN of an existing IAM Role that will be used ECS to start the Tasks | `string` | `""` | no |
| <a name="input_ecs_service_additional_sgs"></a> [ecs\_service\_additional\_sgs](#input\_ecs\_service\_additional\_sgs) | A list of additional Security Groups to attach to the ECS Service | `list(string)` | `[]` | no |
| <a name="input_ecs_service_assign_public_ip"></a> [ecs\_service\_assign\_public\_ip](#input\_ecs\_service\_assign\_public\_ip) | Whether the ECS Tasks should be assigned a public IP. Should be true, if ECS service is using public subnets. See [AWS Docs](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_cannot_pull_image.html) | `bool` | `true` | no |
| <a name="input_ecs_service_deployment_maximum_percent"></a> [ecs\_service\_deployment\_maximum\_percent](#input\_ecs\_service\_deployment\_maximum\_percent) | The upper limit (as a percentage of the service's desiredCount) of the number of running tasks that can be running in a service during a deployment | `number` | `300` | no |
| <a name="input_ecs_service_deployment_minimum_healthy_percent"></a> [ecs\_service\_deployment\_minimum\_healthy\_percent](#input\_ecs\_service\_deployment\_minimum\_healthy\_percent) | The lower limit (as a percentage of the service's desiredCount) of the number of running tasks that must remain running and healthy in a service during a deployment | `number` | `100` | no |
| <a name="input_ecs_service_desired_count"></a> [ecs\_service\_desired\_count](#input\_ecs\_service\_desired\_count) | The number of instances of the task definition to place and keep running | `number` | `2` | no |
| <a name="input_ecs_service_subnets"></a> [ecs\_service\_subnets](#input\_ecs\_service\_subnets) | If using a pre-existing VPC, subnet IDs to be used for the ECS Service | `list(string)` | `[]` | no |
| <a name="input_ecs_settings"></a> [ecs\_settings](#input\_ecs\_settings) | A list of maps with cluster settings. For example, this can be used to enable CloudWatch Container Insights for a cluster. See [Terraform Docs](https://www.terraform.io/docs/providers/aws/r/ecs_cluster.html#setting) | `list(any)` | <pre>[<br>  {<br>    "name": "containerInsights",<br>    "value": "enabled"<br>  }<br>]</pre> | no |
| <a name="input_ecs_task_cpu"></a> [ecs\_task\_cpu](#input\_ecs\_task\_cpu) | The number of CPU units to be used by Refinery | `number` | `2048` | no |
| <a name="input_ecs_task_memory"></a> [ecs\_task\_memory](#input\_ecs\_task\_memory) | The amount of memory (in MiB) to be used by Samprixy | `number` | `4096` | no |
| <a name="input_ecs_task_role"></a> [ecs\_task\_role](#input\_ecs\_task\_role) | The ARN of an existin IAM Role that will be used by the Refinery Task | `string` | `""` | no |
| <a name="input_ecs_use_new_arn_format"></a> [ecs\_use\_new\_arn\_format](#input\_ecs\_use\_new\_arn\_format) | Whether the AWS Account has opted in to the new longer ARN format which allows tagging ECS | `bool` | `false` | no |
| <a name="input_execution_policies_arn"></a> [execution\_policies\_arn](#input\_execution\_policies\_arn) | A list of ARN of the policies to attach to the execution role | `list(string)` | <pre>[<br>  "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",<br>  "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"<br>]</pre> | no |
| <a name="input_firelens_configuration"></a> [firelens\_configuration](#input\_firelens\_configuration) | The FireLens configuration for the Refinery container. This is used to specify and configure a log router for container logs. See [AWS Docs](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_FirelensConfiguration.html) | <pre>object({<br>    type    = string<br>    options = map(string)<br>  })</pre> | `null` | no |
| <a name="input_image_repository"></a> [image\_repository](#input\_image\_repository) | The Refinery image repository | `string` | `"public.ecr.aws/vlaaaaaaad/refinery-fargate-image"` | no |
| <a name="input_image_repository_credentials"></a> [image\_repository\_credentials](#input\_image\_repository\_credentials) | The container repository credentials; required when using a private repo.  This map currently supports a single key; `"credentialsParameter"`, which should be the ARN of a Secrets Manager's secret holding the credentials | `map(string)` | `null` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | The Refinery image tag to use | `string` | `"1.4.1"` | no |
| <a name="input_name"></a> [name](#input\_name) | The name to use on all resources created (VPC, ALB, etc) | `string` | `"refinery"` | no |
| <a name="input_redis_node_type"></a> [redis\_node\_type](#input\_redis\_node\_type) | The instance type used for the Redis cache cluster. See [all available values on the AWS website](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html) | `string` | `"cache.t2.micro"` | no |
| <a name="input_redis_port"></a> [redis\_port](#input\_redis\_port) | The Redis port | `string` | `"6379"` | no |
| <a name="input_redis_subnets"></a> [redis\_subnets](#input\_redis\_subnets) | If using a pre-exiting VPC, subnet IDs to be used for Redis | `list(string)` | `[]` | no |
| <a name="input_redis_version"></a> [redis\_version](#input\_redis\_version) | The Redis version | `string` | `"6.x"` | no |
| <a name="input_refinery_accepted_api_keys"></a> [refinery\_accepted\_api\_keys](#input\_refinery\_accepted\_api\_keys) | The list of Honeycomb API keys that the proxy will accept | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| <a name="input_refinery_cache_capacity"></a> [refinery\_cache\_capacity](#input\_refinery\_cache\_capacity) | The number of spans to cache | `number` | `1000` | no |
| <a name="input_refinery_compress_peer_communication"></a> [refinery\_compress\_peer\_communication](#input\_refinery\_compress\_peer\_communication) | The flag to enable or disable compressing span data when forwarded to peers | `bool` | `true` | no |
| <a name="input_refinery_log_level"></a> [refinery\_log\_level](#input\_refinery\_log\_level) | The Refinery log level | `string` | `"debug"` | no |
| <a name="input_refinery_logger_api_key"></a> [refinery\_logger\_api\_key](#input\_refinery\_logger\_api\_key) | The API key to use to send Refinery logs to Honeycomb | `string` | `""` | no |
| <a name="input_refinery_logger_dataset_name"></a> [refinery\_logger\_dataset\_name](#input\_refinery\_logger\_dataset\_name) | The dataset to which to send Refinery logs to | `string` | `"Refinery Logs"` | no |
| <a name="input_refinery_logger_option"></a> [refinery\_logger\_option](#input\_refinery\_logger\_option) | The loger option for refinery | `string` | `"logrus"` | no |
| <a name="input_refinery_logger_sampler_enabled"></a> [refinery\_logger\_sampler\_enabled](#input\_refinery\_logger\_sampler\_enabled) | The flag to enable or disable sampling Refinery logs | `bool` | `false` | no |
| <a name="input_refinery_logger_sampler_throughput"></a> [refinery\_logger\_sampler\_throughput](#input\_refinery\_logger\_sampler\_throughput) | The per key per second throughput for the log message dynamic sampler | `number` | `10` | no |
| <a name="input_refinery_max_alloc"></a> [refinery\_max\_alloc](#input\_refinery\_max\_alloc) | The maximum memory to use | `number` | `0` | no |
| <a name="input_refinery_metrics_api_key"></a> [refinery\_metrics\_api\_key](#input\_refinery\_metrics\_api\_key) | The API key used to send Refinery metrics to Honeycomb | `string` | `""` | no |
| <a name="input_refinery_metrics_dataset"></a> [refinery\_metrics\_dataset](#input\_refinery\_metrics\_dataset) | The dataset to which to send Refinery metrics to | `string` | `"Refinery Metrics"` | no |
| <a name="input_refinery_metrics_option"></a> [refinery\_metrics\_option](#input\_refinery\_metrics\_option) | The metrics option for refinery | `string` | `"prometheus"` | no |
| <a name="input_refinery_metrics_reporting_interval"></a> [refinery\_metrics\_reporting\_interval](#input\_refinery\_metrics\_reporting\_interval) | The interval (in seconds) to wait between sending metrics to Honeycomb | `number` | `3` | no |
| <a name="input_refinery_peer_buffer_size"></a> [refinery\_peer\_buffer\_size](#input\_refinery\_peer\_buffer\_size) | The number of events to buffer before seding to peers | `number` | `10000` | no |
| <a name="input_refinery_send_delay"></a> [refinery\_send\_delay](#input\_refinery\_send\_delay) | The delay to wait after a trace is complete, before sending | `string` | `"2s"` | no |
| <a name="input_refinery_send_ticker"></a> [refinery\_send\_ticker](#input\_refinery\_send\_ticker) | The duration to use to check for traces to send | `string` | `"100ms"` | no |
| <a name="input_refinery_trace_timeout"></a> [refinery\_trace\_timeout](#input\_refinery\_trace\_timeout) | The amount of time to wait for a trace to be completed before sending | `string` | `"60s"` | no |
| <a name="input_refinery_upstream_buffer_size"></a> [refinery\_upstream\_buffer\_size](#input\_refinery\_upstream\_buffer\_size) | The number of events to buffer before sending to Honeycomb | `number` | `10000` | no |
| <a name="input_route53_record_name"></a> [route53\_record\_name](#input\_route53\_record\_name) | The name of Route53 record to create ACM certificate in and main A-record. If `null` is specified, `var.name` is used instead. Provide empty string to point root domain name to ALB | `string` | `null` | no |
| <a name="input_route53_zone_name"></a> [route53\_zone\_name](#input\_route53\_zone\_name) | The Route53 zone name to create ACM certificate in and main A-record, without trailing dot | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_alb_subnets"></a> [vpc\_alb\_subnets](#input\_vpc\_alb\_subnets) | If using a pre-exiting VPC, subnet IDs to be used for the ALBs | `list(string)` | `[]` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC which will be created if `vpc_id` is not specified | `string` | `"172.16.0.0/16"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The ID of an existing VPC where resources will be created | `string` | `""` | no |
| <a name="input_vpc_public_subnets"></a> [vpc\_public\_subnets](#input\_vpc\_public\_subnets) | A list of public subnets inside the VPC | `list(string)` | <pre>[<br>  "172.16.0.0/18",<br>  "172.16.64.0/18",<br>  "172.16.128.0/18"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | The DNS name of the ALB |
| <a name="output_alb_sg"></a> [alb\_sg](#output\_alb\_sg) | The ID of the Security Group attached to the ALB |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | The ID of the Route53 zone containing the ALB record |
| <a name="output_ecs_cluster_id"></a> [ecs\_cluster\_id](#output\_ecs\_cluster\_id) | The ARN of the ECS cluster hosting Refinery |
| <a name="output_refinery_ecs_security_group"></a> [refinery\_ecs\_security\_group](#output\_refinery\_ecs\_security\_group) | The ID of the Security group assigned to the Refinery ECS Service |
| <a name="output_refinery_ecs_task_definition"></a> [refinery\_ecs\_task\_definition](#output\_refinery\_ecs\_task\_definition) | The task definition for the Refinery ECS service |
| <a name="output_refinery_execution_role_arn"></a> [refinery\_execution\_role\_arn](#output\_refinery\_execution\_role\_arn) | The IAM Role used to create the Refinery tasks |
| <a name="output_refinery_task_role_arn"></a> [refinery\_task\_role\_arn](#output\_refinery\_task\_role\_arn) | The Atlantis ECS task role name |
| <a name="output_refinery_url"></a> [refinery\_url](#output\_refinery\_url) | The URL to use for Refinery |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC that was created or passed in |
<!-- END_TF_DOCS -->

## Authors

This module is created and maintained by [Vlad Ionescu](https://github.com/vlaaaaaaad), in his free time. This is a best-effort allocation of time.

This module was inspired by [Anton Babenko's](https://github.com/antonbabenko) [terraform-aws-atlantis](https://github.com/terraform-aws-modules/terraform-aws-atlantis), which was, in turn, inspired by [Seth Vargo's](https://github.com/sethvargo) [atlantis-on-gke](https://github.com/sethvargo/atlantis-on-gke). Yay, open-source!

## License

MIT licensed. See [LICENSE](./LICENSE) details.
