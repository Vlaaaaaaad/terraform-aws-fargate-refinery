# Public vs Private subnet usage

## Status

Live.

## Context

There are two options for the ECS Cluster / Tasks and for the Redis cluster: running them in a Private Subnet or a Public Subnet.

The debate can be translated to security VS cost.

Private Subnets require NAT Gateways, which are expensive to run. Public subnets use the already-existing Internet gateway.

From a security perspective, Private Subnets allow for an extra layer of security. Resources do not have a public IP so they are "hidden" from the Internet. Using a Public Subnet would only leverage Security Groups and passwords to protect the Redis cluster and Fargate containers, both of which would have public IPs.

## Decision

[@Vlaaaaaaad](https://github.com/vlaaaaaaad/) debated and decided with himself to use public subnets.

By definition, Refinery will be a network-intensive service. Putting the resources in a Private Subnet will [dramatically increase the bill](https://twitter.com/QuinnyPig/status/1232828155431247872), while only allowing for a slight increase in security.

An option that allows a custom VPC to be used is available, allowing for full Private Subnet usage if so desired.
