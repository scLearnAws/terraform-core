# terraform-core

This repository manages shared AWS infrastructure for the lab and provides
the AWS identity and Terraform state storage used by `terraform-app`.
Deploy the core foundation before deploying workloads that depend on it.

## What it manages

- A versioned, AES-256-encrypted S3 bucket for Terraform state, with public
  access blocked and bucket deletion prevented by Terraform.
- A VPC with public and private subnets. Public subnets route through an
  internet gateway; private subnets currently have no NAT gateway or outbound
  route.
- Web and app security groups, plus a small public web EC2 instance.
- An EC2 IAM role and instance profile with the AWS-managed SSM
  `AmazonSSMManagedInstanceCore` policy.
- GitHub's OIDC provider and separate IAM roles for the core and app
  repositories.
- A permissions boundary and IAM policies for Terraform automation.

The web security group allows HTTP and HTTPS from any IPv4 address. The app
security group allows TCP port 8080 only from the web security group. The
current core configuration does not create an app-tier instance.

## State and bootstrap

Core state is configured in `providers.tf` to use the S3 key
`terraform-core/terraform.tfstate`, with S3 lock files enabled. The bucket name
in that backend configuration must refer to an existing bucket before
`terraform init` can use the remote backend. The configuration also manages
the state bucket itself, so bootstrap the bucket and migrate state deliberately.
The current bucket configuration does not yet enforce Bucket Owner Enforced
ownership or deny non-TLS requests; treat those as security-hardening items
before considering the state-bucket requirements complete. Do not delete or
recreate the backend while it contains the active state.

For a first setup, use a non-root AWS session with the permissions needed to
create the backend. Once the configured bucket exists, initialize and migrate
any existing local state:

```sh
terraform init -migrate-state
terraform fmt -check -recursive
terraform validate
terraform plan
terraform apply
```

Review the plan before applying. Do not commit local state, `.terraform/`,
plan files, or variable files containing sensitive values.

## GitHub Actions

`.github/workflows/terraform.yml` has two jobs:

- `validate` runs on pull requests and pushes to `main`; it checks formatting
  and validates Terraform without AWS credentials.
- `deploy` runs only for a push to `main` or a manual run on `main`. It uses
  GitHub OIDC to assume the core role, then plans and applies against remote
  state. The plan file remains on the runner and is not uploaded as an
  artifact.

The deploy job targets the GitHub `production` environment. Configure that
environment to allow deployments from `main` and require approval if supported
by the repository's GitHub plan. The workflow role ARN and region are currently
set to account `119307041607`, role `dev-terraform-core-role`, and
`eu-central-1`; update the workflow and matching OIDC trust configuration if
those values change. The repository and organization identity claims used in
the trust policy are defined in `variables.tf`.

The core role is security-sensitive because it can manage foundation IAM
resources. The custom IAM policy prevents the role from changing its own trust
and permissions. Therefore, changes to that role's own policy—including newly
required read permissions—must first be applied through an authorized
bootstrap/admin session; the GitHub workflow role cannot grant itself access.

## Outputs and dependent workloads

`terraform output` exposes the VPC ID, public/private subnet IDs, security-group
IDs, web instance address, and the core/app role ARNs. Pass the appropriate
foundation identifiers to `terraform-app` as input variables. The app
repository has a separate backend key and should not manage core resources.

## Teardown

Destroy workload resources from `terraform-app` first. Do not run a routine
`terraform destroy` against core: its state bucket stores the state needed to
manage the foundation and has `prevent_destroy`. For final teardown, securely
preserve any required state backup, remove the core resources in dependency
order, and remove the backend bucket only after the active state no longer
depends on it.
