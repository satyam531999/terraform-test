# Spinnaker Scaffold

This directory contains a starter scaffold for using Spinnaker with this Terraform-provisioned AWS stack.

## Ownership Model

- Terraform provisions and updates infrastructure.
- GitHub Actions validates and applies Terraform.
- Spinnaker deploys application revisions to ECS.
- AppConfig and CloudWatch provide rollout safety signals.

## Recommended Flow

1. Developer merges code to `main`.
2. CI builds and pushes a container image to Amazon ECR.
3. Spinnaker detects the new image artifact.
4. Spinnaker deploys the image to the ECS service in `dev`.
5. Health checks, CloudWatch alarms, and ALB checks validate the release.
6. Promotion to `prod` requires explicit approval.

## What You Need In Spinnaker

- AWS account configured with access to ECS, ECR, and optionally S3
- GitHub trigger or Docker registry trigger
- ECS deploy stage targeting the Terraform-created ECS cluster and service
- Manual judgment stage before production
- Optional webhook stage if you want Spinnaker to trigger AppConfig rollout commands

## Repo Mapping

- ECS cluster name is exposed as Terraform output: `ecs_cluster_name`
- ECS service name is exposed as Terraform output: `ecs_service_name`
- ALB endpoint is exposed as Terraform output: `alb_dns_name`
- AppConfig rollout objects are created by `modules/rollout`

## Suggested Next Implementation

- Add an application image build pipeline that publishes to ECR
- Configure a Spinnaker pipeline using `pipelines/ecs-app-deploy.json`
- Start with `dev` deployment only
- Add production promotion after the `dev` path is stable
