# aws

Terraform landing zone for the AWS accounts of **nasir.id**: one AWS
Organization, sign-in with the Google Cloud Identity accounts of `@nasir.id`
through IAM Identity Center, and deployment by GitHub Actions through OIDC,
without access keys.

The structure follows
[ollionorg/aws-landing-zone](https://github.com/ollionorg/aws-landing-zone):
`lzconfig.yaml`, `global-lz-state-backend.conf`, the stages `0-bootstrap`,
`1-org` (with one sub-folder per service), `2-network`, `3-env/<env>`, and
`terraform/modules` plus `terraform/scp-stored`. It differs in two ways:

- **Free resources only.** The paid services of the Ollion landing zone are
  left out: AWS Config, GuardDuty, Security Hub, Macie, KMS keys, the
  CloudWatch exporters, NAT gateways, Transit Gateway, Network Firewall,
  Route 53 Resolver endpoints and the network/DNS hub accounts.
- **GitHub Actions instead of CodePipeline.** There is no LZ CI/CD account,
  CodeBuild or CodeStar connection: GitHub Actions assumes a role in the
  management account through OIDC.

> **Status:** `lzconfig.yaml`, `0-bootstrap` (both folders), `1-org` and the
> workflow are written; nothing is applied yet. The `1-org/*` services and
> `3-env` are added next. This README is updated with every change.

## Decisions

| Item | Value |
|---|---|
| Organization | The **existing** organization `r-iyjk`, imported into Terraform; nothing is recreated |
| Management account | The existing `647459380434` (Nasir Ahmad Nooruddin, root e-mail `nasir@nasir.id`). Its current workloads (lab VPC, WordPress, Lambda, Cognito…) stay where they are. SCPs never restrict a management account. |
| Old member accounts | `Jember Click` (`781980624727`) is being closed by hand; `Dunia Cloud 10` (`188919317772`) is already closed. Terraform ignores both. |
| New member accounts | `Log Archive`, `Security Tooling`, `Network Hub`, `Shared Services`, `Prod Master`, `NonProd Master` |
| Account e-mails | Plus-addressing on the management mailbox: `nasir+aws-<account>@nasir.id` |
| Home region | `ap-southeast-1` (Singapore): Identity Center, state bucket, CloudTrail. The only region member accounts may use, apart from the global services. |
| Identity | Google Cloud Identity, domain `nasir.id`, as the SAML identity provider of IAM Identity Center ([guide](docs/identity-center-cloud-identity.md)) |
| Principals | Six `@nasir.id` users of Google Cloud Identity, one per job role (`aws-admin@`, `aws-devops@`, …) |
| Network | prod `10.30.0.0/16`, nonprod `10.40.0.0/16` (no overlap with GCP or the old lab VPC) |
| Budget | USD 10 a month for the whole organization, alerts at 50 / 90 / 100 % |
| State | S3 bucket `nasir-aws-terraform-state`, S3 lock files (no DynamoDB table) |
| CI/CD | GitHub Actions on GitHub-hosted runners, repository `nasir19noor/aws`, branch `main`, AWS sign-in through OIDC |

## Organization structure

The OUs and accounts use the names of AWS's guidance (*Organizing Your AWS
Environment Using Multiple Accounts*): Security, Infrastructure, Workloads and
Suspended (Ollion calls the first and third Common and Application). The keys
in `lzconfig.yaml` match these names (`security`, `workloads`,
`log_archive_account`, ...) and are what the `1-org` outputs `ou_id_map` and
`accounts_id_map` use. Don't rename a key once its OU or account exists:
Terraform would delete and recreate it.

```
AWS Organization r-iyjk (management account 647459380434, nasir@nasir.id)
├── Security OU
│   ├── Log Archive        nasir+aws-security-logs@nasir.id    org CloudTrail bucket
│   └── Security Tooling   nasir+aws-security-tools@nasir.id   delegated admin: IAM Access Analyzer
├── Infrastructure OU
│   ├── Network Hub        nasir+aws-network@nasir.id          shared networking (empty for now: hubs need paid TGW)
│   └── Shared Services    nasir+aws-shared-services@nasir.id  tools shared by all environments
├── Workloads OU
│   ├── Prod OU
│   │   └── Prod Master    nasir+aws-prod@nasir.id             VPC 10.30.0.0/16
│   └── NonProd OU
│       └── NonProd Master nasir+aws-nonprod@nasir.id          VPC 10.40.0.0/16
└── Suspended OU           accounts waiting to be closed; deny-all SCP
```

OUs, accounts and their SCPs are all defined in `org.org_hierarchy` in
`lzconfig.yaml`. Adding an account is a few lines there.

## Repository layout

```
aws/
├── lzconfig.yaml                         every setting; all stages read it
├── global-lz-state-backend.conf          state bucket, region, S3 locking
├── 0-bootstrap/                          by hand, once, in the management account
│   ├── tf-prerequisites/                 S3 state bucket
│   └── bootstrap/                        organization settings (imported), GitHub OIDC role
├── 1-org/                                OUs, member accounts, SCPs
│   ├── logging-buckets/                  CloudTrail bucket in Log Archive
│   ├── cloudtrail/                       organization trail
│   ├── billing/                          monthly budget and alerts
│   ├── permission-sets/                  Identity Center permission sets, users, assignments
│   └── aws-secure-baseline/
│       ├── iam-ebs-secure-baselines/     password policy, EBS encryption by default (every account)
│       ├── s3-baseline/                  account-level S3 Block Public Access (every account)
│       └── access-analyzer/              org-wide external access analyzer (Security Tooling)
├── 2-network/                            not used: hubs need Transit Gateway / Network Firewall (paid)
├── 3-env/
│   ├── prod/vpc/                         VPC in Prod Master
│   └── nonprod/vpc/                      VPC in NonProd Master
├── terraform/
│   ├── modules/                          organization-unit, org-account, ... (plus nasir19noor/terraform modules)
│   └── scp-stored/                       SCP JSON templates
├── docs/                                 guides
└── .github/workflows/terraform.yml       deploys the changed stages
```

Every folder with `.tf` files is a separate Terraform root with its own
state, key `<folder>/terraform.tfstate` in the state bucket. Later folders
read earlier ones through `terraform_remote_state` (for example the account
IDs from `1-org`). Member accounts are reached by assuming
`OrganizationAccountAccessRole`, which Organizations creates in every
account it creates.

## SCPs (`terraform/scp-stored`)

Named as in the Ollion landing zone. They are templates: regions, bucket and
role names come from `lzconfig.yaml`.

| SCP | Attached to | Effect |
|---|---|---|
| `denyLeaveOrganization` | Security, Infrastructure, Workloads OUs | Accounts can't leave the organization |
| `denyRootPolicy` | Security, Infrastructure, Workloads OUs | The root user of member accounts can do nothing |
| `denyCloudtrailChanges` | Security, Infrastructure, Workloads OUs | Trails can't be stopped, deleted or changed |
| `denyAllRegionsExceptSome` | Security, Infrastructure, Workloads OUs | Only `ap-southeast-1`, except global services (IAM, Organizations, STS, Route 53, CloudFront, ACM, WAF, Budgets, billing, Support, Identity Center, …) |
| `denyS3Modification` | Log Archive account | The CloudTrail bucket can't be deleted, emptied or reconfigured, except through `OrganizationAccountAccessRole` (Terraform) |
| `denyAll` | Suspended OU | Everything denied |

SCPs are never attached to Root: accounts left directly under Root are
unaffected, and AWS's `FullAWSAccess` stays on Root.

## Setup, step by step

### Prerequisites (by hand)

1. **Management account** `647459380434`: make sure its root user has MFA
   and no access keys.
2. **Check plus-addressing:** send a test mail to
   `nasir+aws-test@nasir.id` and make sure it arrives. Each member account's
   root e-mail must receive mail.
3. **IAM Identity Center with Google Cloud Identity**, step by step in
   [docs/identity-center-cloud-identity.md](docs/identity-center-cloud-identity.md):
   Identity Center enabled in `ap-southeast-1`, a SAML app in
   admin.google.com, the identity source switched to it, and a first admin
   user `nasir@nasir.id` with `AdministratorAccess` on `647459380434`.
   Done.
4. **CLI credentials:** `aws configure sso`, then `aws sso login`.
5. **Existing GitHub OIDC provider?** Only one can exist per account:

   ```sh
   aws iam list-open-id-connect-providers
   ```

   If `token.actions.githubusercontent.com` is listed, set
   `bootstrap.cicd.create_oidc_provider: false` in `lzconfig.yaml`.

### 0-bootstrap/tf-prerequisites (by hand, once)

S3 state bucket `nasir-aws-terraform-state` in `ap-southeast-1`, created with
the `s3` module of
[nasir19noor/terraform](https://github.com/nasir19noor/terraform/tree/main/aws/modules/s3)
(pinned to a commit): versioned, public access blocked, SSE-S3, and a bucket
policy that denies non-TLS access.

The bucket doesn't exist before this apply, so the apply uses local state,
which is then moved into the bucket. `backend_override.tf` is ignored by git.

```sh
cd 0-bootstrap/tf-prerequisites
printf 'terraform {\n  backend "local" {}\n}\n' > backend_override.tf
terraform init
terraform apply
rm backend_override.tf
terraform init -migrate-state -backend-config=../../global-lz-state-backend.conf    # answer "yes"
rm terraform.tfstate terraform.tfstate.backup
```

### 0-bootstrap/bootstrap (by hand, once)

- **The organization, imported** (`import` block, nothing is recreated):
  all features; SCPs enabled; trusted access for IAM Identity Center,
  CloudTrail, IAM Access Analyzer and account management. Trusted access and
  policy types that are already on are kept.
- **GitHub OIDC provider** `token.actions.githubusercontent.com`.
- **IAM role `github-terraform`** with `AdministratorAccess`. Only tokens
  from `nasir19noor/aws` on `main` can assume it: the trust policy accepts
  the `sub` claim in both the name form (`repo:nasir19noor/aws:ref:refs/heads/main`)
  and the immutable-ID form (`repo:nasir19noor@330575/aws@742005119:...`).

```sh
cd 0-bootstrap/bootstrap
terraform init -backend-config=../../global-lz-state-backend.conf
terraform apply
```

Then add the `role_arn` output as the GitHub repository variable
`AWS_ROLE_ARN` (Settings → Secrets and variables → Actions → Variables), and
check the sign-in: Actions → terraform → Run workflow → action
`auth-check`.

### 1-org (GitHub Actions)

From `org.org_hierarchy` in `lzconfig.yaml`, with the modules
`terraform/modules/organization-unit` and `terraform/modules/org-account`:

- the OUs and sub-OUs;
- the six member accounts, each with `OrganizationAccountAccessRole`.
  Removing an account from `lzconfig.yaml` doesn't close it
  (`close_on_deletion` is off): move it to Suspended and close it by hand;
- the SCPs from `terraform/scp-stored` and their attachments.

Outputs: `accounts_id_map`, `ou_id_map`, `root_id`, used by every later stage.

### 1-org services (GitHub Actions, to be written)

| Folder | Account | What (all free) |
|---|---|---|
| `1-org/logging-buckets` | Log Archive | Bucket `nasir-aws-org-cloudtrail`: versioned, SSE-S3, public access blocked, TLS only, bucket policy for CloudTrail |
| `1-org/cloudtrail` | management | Organization trail `org-trail`: management events of every account and region, log file validation. The first copy of management events is free. |
| `1-org/billing` | management | AWS Budget: USD 10 a month for the organization, e-mail to `nasir@nasir.id` at 50 / 90 / 100 % actual and 100 % forecast |
| `1-org/permission-sets` | management | Identity Center permission sets, users and account assignments (table below) |
| `1-org/aws-secure-baseline/iam-ebs-secure-baselines` | every member account | IAM password policy, EBS encryption by default (AWS managed key) |
| `1-org/aws-secure-baseline/s3-baseline` | every member account | Account-level S3 Block Public Access |
| `1-org/aws-secure-baseline/access-analyzer` | Security Tooling | Delegated admin and organization-wide external access analyzer |

Permission sets and assignments:

| User (`permission_sets_principal`) | management | Log Archive, Security Tooling | Network Hub | Shared Services | Prod Master | NonProd Master |
|---|---|---|---|---|---|---|
| `aws-admin@nasir.id` (`organization_admin`) | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess | AdministratorAccess |
| `aws-billing@nasir.id` (`billing_admin`) | Billing | | | | | |
| `aws-security@nasir.id` (`security_admin`) | ReadOnlyAccess | AdministratorAccess | ReadOnlyAccess | ReadOnlyAccess | ReadOnlyAccess | ReadOnlyAccess |
| `aws-network@nasir.id` (`network_admin`) | | | AdministratorAccess | | PowerUserAccess | PowerUserAccess |
| `aws-devops@nasir.id` (`devops`) | | | | PowerUserAccess | PowerUserAccess | PowerUserAccess |
| `aws-developers@nasir.id` (`developers`) | | | | ReadOnlyAccess | ReadOnlyAccess | PowerUserAccess |

### 2-network

Not used. In the Ollion landing zone it holds the network hub (Transit
Gateway, Network Firewall, interconnect VPCs) and the DNS hub (Route 53
Resolver endpoints), all billed by the hour. Each environment has its own
VPC in `3-env` instead.

### 3-env (GitHub Actions, to be written)

| | `3-env/prod/vpc` | `3-env/nonprod/vpc` |
|---|---|---|
| Account | Prod Master | NonProd Master |
| VPC | `vpc-prod`, `10.30.0.0/16` | `vpc-nonprod`, `10.40.0.0/16` |
| Public subnets, 3 AZs | `10.30.0.0/24`, `.1.0/24`, `.2.0/24` | `10.40.0.0/24`, `.1.0/24`, `.2.0/24` |
| Private subnets, 3 AZs | `10.30.10.0/24`, `.11.0/24`, `.12.0/24` | `10.40.10.0/24`, `.11.0/24`, `.12.0/24` |
| Internet gateway | yes (free) | yes (free) |
| NAT gateway | no | no |
| S3 and DynamoDB gateway endpoints | yes (free) | yes (free) |
| Default security group and NACL | locked down, as in the Ollion `env-vpc` | same |

Without NAT, private subnets have no internet access; they reach S3 and
DynamoDB through the gateway endpoints. VPC Flow Logs are off.

## CI/CD

[.github/workflows/terraform.yml](.github/workflows/terraform.yml), on
`ubuntu-latest` with Terraform 1.14.3 (in place of Ollion's CodePipeline):

- **Pull request:** `terraform fmt -check` and `validate` for the changed
  folders, including `0-bootstrap/*`. No AWS access, because the role
  trusts `main` only.
- **Push to `main`:** OIDC sign-in, then plan and apply only the changed
  stages, one job per stage, one at a time, in this order: `1-org`,
  `1-org/logging-buckets`, `1-org/cloudtrail`, `1-org/billing`,
  `1-org/permission-sets`, `1-org/aws-secure-baseline/*`, `3-env/prod/vpc`,
  `3-env/nonprod/vpc`. It stops at the first failure. A changed file belongs
  to the deepest stage folder that contains it. Stages that read a changed
  stage's outputs are included too. A change to `lzconfig.yaml`,
  `global-lz-state-backend.conf`, `terraform/modules` or the workflow deploys
  every stage; a change in `terraform/scp-stored` deploys `1-org`.
- **Manual run** (Actions → terraform → Run workflow): `action` `plan`,
  `apply` or `auth-check`, and `stages` (space-separated folders, empty =
  all).

`0-bootstrap/*` is never applied by CI.

## Cost

What `0-bootstrap` and `1-org` create, checked against AWS pricing:

| Resource | Price |
|---|---|
| S3 state bucket: versioning, Block Public Access, SSE-S3 (set explicitly, not KMS), TLS-only policy | Configuration free; storage and requests only, a few KB of state, well under USD 0.01 a month. Old state versions are kept (no lifecycle expiry). |
| IAM OIDC provider, IAM role, policy attachment, STS sign-ins from CI | Free |
| Organizations import, all features, SCP policy type, trusted access | Free; trusted access alone doesn't turn a service on |
| OUs, SCPs, attachments, member accounts | Free |

Everything here is free: Organizations, OUs, SCPs, IAM Identity Center,
IAM, IAM Access Analyzer (external access), VPCs, subnets, internet
gateways, gateway endpoints, account-level settings, and the first
CloudTrail copy of management events.

What could still cost a little:

- S3 storage of the CloudTrail logs and Terraform state: cents per month;
- AWS Budgets: the first budgets are free, and only one is created.

Left out because they are paid: AWS Config, GuardDuty, Security Hub, Macie,
KMS customer-managed keys, CloudWatch log exports, Control Tower, NAT
gateways, Transit Gateway, Network Firewall, Route 53 Resolver endpoints,
interface VPC endpoints, VPC Flow Logs.
