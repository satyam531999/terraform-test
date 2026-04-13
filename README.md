# Terraform AWS Production Hands-On Lab

This repository is a practical starter kit to learn production-grade Terraform on AWS with:

- Infrastructure provisioning (network + ECS service)
- Progressive rollout controls (AppConfig deployment strategy)
- Observability foundation (CloudWatch alarms/dashboard)
- Dynatrace integration scaffolding (cross-account IAM role + secrets)

## Repository Structure

- `bootstrap/`: Creates remote Terraform state backend (S3 + DynamoDB lock table)
- `app/`: Observable demo application source code and container build context
- `environments/dev/`: Development environment stack
- `environments/prod/`: Production environment stack
- `modules/network/`: VPC, subnets, routing, NAT
- `modules/compute_ecs/`: ECS Fargate service behind ALB
- `modules/telemetry/`: CloudWatch alarms and dashboard
- `modules/rollout/`: AWS AppConfig rollout strategy and deployment objects
- `modules/dynatrace_aws_integration/`: IAM role/policy + secret placeholders for Dynatrace

## Prerequisites

- Terraform >= 1.6
- AWS CLI configured (`aws configure` or SSO profile)
- IAM permissions to create VPC, ECS, IAM, CloudWatch, AppConfig, Secrets Manager

## Step 1: Create Remote State Backend (one-time)

```bash
cd bootstrap
terraform init
terraform apply -var="aws_region=us-east-1" -var="state_bucket_name=<globally-unique-bucket-name>"
```

Capture outputs:

- `state_bucket_name`
- `lock_table_name`

## Step 2: Configure Environment Backend

In each environment folder (`environments/dev`, `environments/prod`), create `backend.hcl` from `backend.hcl.example` and fill values.

Then initialize:

```bash
cd environments/dev
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

Repeat for prod.

## Step 3: Add Dynatrace Details

In `terraform.tfvars` set:

- `dynatrace_aws_account_arn`
- `dynatrace_external_id`
- `dynatrace_api_url`
- `dynatrace_api_token` (optional; can be injected later via Secrets Manager)

Use module output `dynatrace_integration_role_arn` in Dynatrace AWS integration setup.

## Step 4: Rollout Practice

This lab provisions AppConfig rollout components. For hands-on rollout exercises:

1. Create a feature flag JSON in AppConfig hosted configuration profile.
2. Update hosted configuration version.
3. Trigger deployment with gradual strategy.
4. Use CloudWatch alarms to gate rollout progression.

## Suggested Learning Milestones

1. Bring up `dev` fully, then destroy and recreate.
2. Modify ECS desired count and observe zero-downtime service update.
3. Tighten IAM policy scope in Dynatrace module.
4. Add SNS topic and wire alarm notifications.
5. Add CI checks in your own Git provider using `.github/workflows/terraform.yml` as reference.
6. Build and publish the observable app image using `.github/workflows/app-image.yml`.

## Safety Notes

- Start in a sandbox AWS account.
- Avoid hardcoded secrets.
- Keep prod applies behind manual approval.
- Review `terraform plan` for every change.

## CI/CD Pipeline

Workflow file: `.github/workflows/terraform.yml`

Application image workflow: `.github/workflows/app-image.yml`

### What It Does

- Pull requests:
	- Terraform fmt check
	- Terraform validate
	- Terraform plan against `terraform.tfvars.example`
	- tfsec security scan
	- Uploads plan artifacts for dev and prod

- Manual runs (`workflow_dispatch`):
	- `action=plan`: Runs remote-state plan for selected environment
	- `action=apply`: Runs guarded apply for selected environment
	- Apply requires explicit confirmation text: `apply-dev` or `apply-prod`

### Required GitHub Secrets

Set these repository secrets:

- `AWS_ROLE_TO_ASSUME`: IAM role ARN used by GitHub OIDC
- `AWS_REGION`: e.g. `us-east-1`
- `TF_STATE_BUCKET`: S3 backend bucket name
- `TF_LOCK_TABLE`: DynamoDB lock table name

The application image workflow publishes to the `observable-demo-app` ECR repository and will create that repository automatically if it does not exist.

On branch pushes and manual runs, the same workflow also deploys the newly published immutable image into `dev` by running Terraform with a `container_image` override. This removes the need to manually edit `terraform.tfvars` for every app change while keeping `prod` under manual control.

If the GitHub secret `SPINNAKER_WEBHOOK_URL` is configured, the app workflow switches to a Spinnaker handoff model for `dev`: it publishes the image, sends the image metadata to Spinnaker via webhook, and skips the Terraform-based `deploy_dev` fallback.

## Observable Demo App

The `app/` directory contains a small Express service intentionally shaped for monitoring and rollout demonstrations.

Endpoints:

- `/`: HTML landing page with app name, environment, version, hostname, and render time
- `/health`: lightweight health endpoint for ALB checks
- `/api/demo`: normal JSON response path
- `/api/slow?delay=2000`: controlled latency generator
- `/api/error?code=500`: controlled failure generator
- `/api/log-demo`: structured log emitter

This gives you useful signals today in ALB metrics and CloudWatch logs, and later in Dynatrace when instrumentation is added.

### Recommended GitHub Environments

Create two environments in GitHub: `dev` and `prod`.

- For `prod`, enable required reviewers before deployment.
- This provides a manual approval gate before apply.

### OIDC Trust Setup (AWS)

The role in `AWS_ROLE_TO_ASSUME` should trust GitHub OIDC and allow Terraform actions required for this lab.

### How To Run In GitHub Actions

1. Open Actions -> Terraform CI CD -> Run workflow.
2. Choose `action=plan` and `target_env=dev` (or `prod`).
3. Review uploaded plan artifact.
4. Re-run with `action=apply`, same `target_env`, and `confirm_apply=apply-<env>`.

## Spinnaker Delivery Model

Use GitHub Actions for infrastructure CI/CD and use Spinnaker for application delivery.

Recommended split:

- Terraform + GitHub Actions:
	- `terraform fmt`
	- `terraform validate`
	- `terraform plan`
	- `tfsec` security scanning
	- manual `apply` to `dev` or `prod`
- Spinnaker:
	- deploy new ECS application versions
	- promote releases from `dev` to `prod`
	- run manual approval before production rollout
	- roll back on failed health checks

Why this split works well:

- Terraform remains the source of truth for infrastructure state
- Spinnaker handles release orchestration better than raw Terraform applies
- AppConfig and CloudWatch alarms continue to provide rollout guardrails

Suggested rollout path:

1. Provision infrastructure with Terraform.
2. Build and publish container image to ECR.
3. Trigger Spinnaker pipeline for ECS deployment.
4. Verify ALB health and CloudWatch alarms.
5. Promote to production with approval.

## Demo Walkthrough (Short)

Use this sequence during demo to validate that infrastructure is not only created, but usable and rollout-safe.

### 1) Verify ALB endpoint is serving traffic

Why: Confirms end-to-end path works (`ALB -> target group -> ECS task -> container`).

```bash
ALB_DNS=$(terraform -chdir=environments/dev output -raw alb_dns_name)
curl -I "http://$ALB_DNS"
```

Expected: `HTTP/1.1 200 OK`.

### 2) Verify AWS resources are present

Why: Confirms network and ingress resources exist in AWS (independent of Terraform CLI output).

```bash
aws ec2 describe-vpcs \
	--filters "Name=tag:Name,Values=prodlab-dev-vpc" \
	--query "Vpcs[0].[VpcId,CidrBlock]"

aws elbv2 describe-load-balancers \
	--names prodlab-dev-alb \
	--query "LoadBalancers[0].[LoadBalancerArn,State.Code]"
```

### 3) Resolve AppConfig IDs dynamically (no hardcoded IDs)

Why: AppConfig IDs change after destroy/recreate. Dynamic lookup keeps demo commands stable.

```bash
APP_ID=$(aws appconfig list-applications \
	--query "Items[?Name=='prodlab-dev-appconfig-app'].Id | [0]" \
	--output text)

ENV_ID=$(aws appconfig list-environments \
	--application-id "$APP_ID" \
	--query "Items[?Name=='dev'].Id | [0]" \
	--output text)

PROFILE_ID=$(aws appconfig list-configuration-profiles \
	--application-id "$APP_ID" \
	--query "Items[0].Id" \
	--output text)

echo "APP_ID=$APP_ID ENV_ID=$ENV_ID PROFILE_ID=$PROFILE_ID"
```

### 4) Verify rollout guardrails (alarms + AppConfig objects)

Why: Confirms progressive rollout safety controls are in place.

```bash
aws cloudwatch describe-alarms \
	--alarm-names prodlab-dev-alb-5xx prodlab-dev-alb-p95-latency \
	--query "MetricAlarms[].AlarmName"

aws appconfig list-environments \
	--application-id "$APP_ID" \
	--query "Items[0].[Name,State]"
```

### 5) Create and upload a feature flag version

Why: Demonstrates config-as-code release without rebuilding/redeploying the app image.

```bash
cat > feature-flags.json << 'EOF'
{
	"enabled_features": {
		"new_ui": true,
		"beta_api": false
	},
	"rollout": {
		"percentage": 20
	}
}
EOF

VERSION=$(aws appconfig create-hosted-configuration-version \
	--application-id "$APP_ID" \
	--configuration-profile-id "$PROFILE_ID" \
	--content fileb://feature-flags.json \
	--content-type "application/json" \
	--query "VersionNumber" \
	--output text)

echo "Uploaded Version=$VERSION"
```

### 6) Start progressive deployment and track status

Why: Shows staged rollout behavior and observable deployment state.

```bash
STRATEGY_ID=$(aws appconfig list-deployment-strategies \
	--query "Items[?contains(Name,'Gradual') || contains(Name,'gradual')].Id | [0]" \
	--output text)

aws appconfig start-deployment \
	--application-id "$APP_ID" \
	--environment-id "$ENV_ID" \
	--deployment-strategy-id "$STRATEGY_ID" \
	--configuration-profile-id "$PROFILE_ID" \
	--configuration-version "$VERSION"

aws appconfig list-deployments \
	--application-id "$APP_ID" \
	--environment-id "$ENV_ID" \
	--query "Items[0].[DeploymentNumber,State,PercentageComplete]"
```

### If you see `503 Service Temporarily Unavailable`

This usually means ALB is reachable but targets are not healthy yet. Wait briefly and re-check:

```bash
aws ecs describe-services \
	--cluster prodlab-dev-cluster \
	--services prodlab-dev-service \
	--query "services[0].[desiredCount,runningCount,pendingCount,status]"

aws elbv2 describe-target-groups --names prodlab-dev-tg --query "TargetGroups[0].TargetGroupArn" --output text
# Use returned ARN below:
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```
