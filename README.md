# terraform-core

This repository manages shared AWS infrastructure for the lab and provides
the AWS identity and Terraform state storage used by `terraform-app`.
Deploy the core foundation before deploying workloads that depend on it.

## What it manages

- A versioned, AES-256-encrypted S3 bucket for Terraform state, with public
  access blocked, ACLs disabled, TLS required, and bucket deletion prevented
  by Terraform.
- Account-wide S3 Block Public Access to prevent public bucket policies or
  ACLs throughout this lab AWS account.
- A VPC with public and private subnets. Public subnets route through an
  internet gateway; private subnets currently have no NAT gateway or outbound
  route.
- A public web security group and a small public web EC2 instance.
- An EC2 IAM role and instance profile with the AWS-managed SSM
  `AmazonSSMManagedInstanceCore` policy.
- GitHub's OIDC provider and separate IAM roles for the core and app
  repositories.
- A permissions boundary and IAM policies for Terraform automation.

The web security group allows HTTP and HTTPS from any IPv4 address. The
current core configuration does not create an app-tier instance or app
security group; the workload repository owns its own security group.

## State and bootstrap

Core state is configured in `providers.tf` to use the S3 key
`terraform-core/terraform.tfstate`, with S3 lock files enabled. The bucket
enforces Bucket Owner Enforced ownership, server-side encryption, versioning,
bucket-level public access blocking, and TLS-only requests. Account-level
S3 Block Public Access is also enabled by Terraform. This affects all buckets
in the account, not just this state bucket. The bucket name in the backend
configuration must refer to an existing bucket before `terraform init` can use
the remote backend. The configuration also manages the state bucket itself,
so bootstrap the bucket and migrate state deliberately. Do not delete or
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
- The app repository limits pull requests to validation; apply runs from
  trusted `main` deployments, and workload destruction is a manual,
  confirmation-gated operation.
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
the trust policy are defined in `variables.tf`. Role trust accepts only the
`production` environment subject, not pull-request or branch subjects.
Restrict that environment to `main` and require reviewers where supported.

The core role is security-sensitive because it can manage foundation IAM
resources. It uses a custom policy for the EC2/network and S3 operations
defined here instead of AWS-wide `PowerUserAccess`. Its S3 object access is
limited to the core state and lock keys. A separate IAM-management policy
requires the permissions boundary when it creates lab roles and prevents the
role from changing its own trust and permissions. The core role can manage
the GitHub OIDC provider and lab roles because those are part of the core
configuration.

The permissions boundary explicitly allows only workload EC2 operations,
the app state key, passing the SSM role to EC2, and the SSM agent actions
needed by the instance. It also denies IAM escalation and state-bucket
configuration changes. A boundary does not grant permissions by itself; it
caps permissions granted separately to a role. The app automation role and
EC2 SSM role are assigned this boundary. The core role may assign only this
exact boundary to lab roles, and is explicitly denied removing it. The
high-privilege core automation role itself is not boundary-constrained; its
permissions are limited by its attached custom policies and self-protection
denies.

The core workflow cannot update its own IAM policies or detach its own managed
policies. Apply changes to the core role's permissions with an authorized
bootstrap/admin session. In particular, removing the old `PowerUserAccess`
attachment, adding the scoped AWS policy, and attaching the boundary to
existing workload roles cannot be applied by that same GitHub role; apply
those changes once using an authorized admin session.

## Outputs and dependent workloads

`terraform output` exposes the VPC ID, public/private subnet IDs, web security
group ID, web instance address, and the core/app role ARNs. Pass the appropriate
foundation identifiers to `terraform-app` as input variables. The app
repository has a separate backend key and should not manage core resources.

## Teardown

Destroy workload resources from `terraform-app` first. Do not run a routine
`terraform destroy` against core: its state bucket stores the state needed to
manage the foundation and has `prevent_destroy`. For final teardown, securely
preserve any required state backup, remove the core resources in dependency
order, and remove the backend bucket only after the active state no longer
depends on it.
