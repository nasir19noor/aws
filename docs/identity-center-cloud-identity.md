# IAM Identity Center with Google Cloud Identity

How to make the `@nasir.id` accounts of Google Cloud Identity the sign-in for
every AWS account in the organization. This is done by hand, once, before
`0-bootstrap`. Terraform can't change an Identity Center identity source.

```
user@nasir.id ──▶ AWS access portal ──▶ Google sign-in (SAML) ──▶ back to AWS ──▶ account + permission set
```

- **Google Cloud Identity** is the identity provider (IdP): it holds the
  users and their passwords and 2-Step Verification.
- **IAM Identity Center** in the management account `647459380434` is the
  service provider (SP): it holds the users' AWS side (same user names),
  the permission sets and the account assignments.

You need: a nasir.id **super admin** in admin.google.com, and an
administrator of the management account in the AWS console. Keep both open
in two browser tabs, because values are copied back and forth.

## 1. AWS: enable IAM Identity Center

1. Sign in to the console of the management account `647459380434` and
   select the region **Asia Pacific (Singapore) `ap-southeast-1`**.
2. Open **IAM Identity Center**.
   - If it says **Enable**: choose **Enable**, then **Enable with AWS
     Organizations** (organization instance). It runs in the selected region
     from then on.
   - If it is already enabled: note the region shown on its dashboard. If it
     isn't `ap-southeast-1`, keep it and set that region for Identity Center
     in `config.yaml`; an instance can't be moved to another region.
3. On the **Dashboard**, note the **AWS access portal URL**
   (`https://d-xxxxxxxxxx.awsapps.com/start`). You can change the
   `d-xxxxxxxxxx` part to something readable under **Settings → Identity
   source → Actions → Customize AWS access portal URL**, e.g.
   `https://nasir-id.awsapps.com/start`. Do this **before** step 3, because
   the portal URL is part of what Google is told.

## 2. AWS: start changing the identity source

1. **Settings → Identity source → Actions → Change identity source.**
2. Choose **External identity provider → Next**.
3. The page shows **Service provider metadata**. Copy these three values:

   | Value | Looks like |
   |---|---|
   | AWS access portal sign-in URL | `https://nasir-id.awsapps.com/start` |
   | IAM Identity Center Assertion Consumer Service (ACS) URL | `https://ap-southeast-1.signin.aws.amazon.com/platform/saml/acs/…` |
   | IAM Identity Center issuer URL | `https://ap-southeast-1.signin.aws.amazon.com/platform/saml/d-…` |

4. **Leave this tab open.** The second half of the page (identity provider
   metadata) is filled in at step 4.

## 3. Google: create the SAML app

1. Sign in to **admin.google.com** as a super admin.
2. **Apps → Web and mobile apps → Add app → Search for apps**, search for
   **Amazon Web Services**, and choose the **Amazon Web Services** SAML app.
   (Alternatively, **Add app → Add custom SAML app** with the name `AWS IAM
   Identity Center` works the same way.)
3. **Google Identity Provider details:** choose **Download metadata** and
   save `GoogleIDPMetadata.xml`. Then **Continue**.
4. **Service provider details:**

   | Field | Value |
   |---|---|
   | ACS URL | the IAM Identity Center ACS URL from step 2 |
   | Entity ID | the IAM Identity Center issuer URL from step 2 |
   | Start URL | the AWS access portal sign-in URL (optional; makes the app tile in Google open the portal) |
   | Signed response | off |
   | Name ID format | **EMAIL** |
   | Name ID | **Basic Information → Primary email** |

   **Continue.**
5. **Attribute mapping:** Identity Center needs none; it identifies the
   user by the Name ID only. The **Amazon Web Services** catalog app marks
   `https://aws.amazon.com/SAML/Attributes/Role` and `…/RoleSessionName` as
   required and pre-fills them (Last name, First name). Keep them as they
   are: they're meant for SAML-to-IAM-role sign-in, and Identity Center
   ignores them. They can't be removed, and saving them empty is refused.
   (A custom SAML app has no required attributes; leave its mapping empty.)
   **Finish.**
6. Open the new app → **User access** → **ON for everyone** → **Save**.
   It can take a few minutes (rarely up to 24 hours) before it works.

## 4. AWS: finish changing the identity source

Back in the tab from step 2:

1. Under **Identity provider metadata**, choose **Upload IdP SAML metadata
   file** and upload `GoogleIDPMetadata.xml`.
2. **Next**, read the review, type **ACCEPT**, and choose **Change identity
   source**.

From now on, Identity Center sends everyone to Google to sign in. MFA is
whatever Google enforces: turn on **2-Step Verification** for nasir.id in
admin.google.com (**Security → Authentication → 2-step verification**).

## 5. Provisioning: how users get into Identity Center

SAML only handles the sign-in. Identity Center also needs a user with the
**same user name** (the primary e-mail) before it can accept that person.

- **Cloud Identity Free** (nasir.id): Google's automatic provisioning to AWS
  is not included in the free edition. Leave **Settings → Automatic
  provisioning** off; the users are created on the AWS side by Terraform
  (`2-identity`), with **Username = the exact primary e-mail**, e.g.
  `gcp@nasir.id`.
- **Cloud Identity Premium or Google Workspace** (if you ever upgrade): in
  AWS, **Settings → Automatic provisioning → Enable**, copy the **SCIM
  endpoint** and **access token**. In Google, open the app → **Auto
  provisioning** → paste them, and turn it on. Google then creates, updates
  and suspends users in AWS by itself. The token expires after one year.

## 6. A first user and permission set, for the bootstrap

`0-bootstrap` needs administrator credentials before the CI role exists.
Create one admin by hand (Terraform takes it over later, in `2-identity`):

1. **Users → Add user**: Username `nasir@nasir.id`, e-mail
   `nasir@nasir.id`, first and last name. With an external IdP no password
   is set; sign-in goes through Google.
2. **Permission sets → Create permission set → Predefined permission set →
   AdministratorAccess**, session duration e.g. 4 hours.
3. **AWS accounts →** tick `647459380434` → **Assign users or groups** →
   `nasir@nasir.id` → `AdministratorAccess` → **Submit**.

## 7. Test

1. Open the AWS access portal URL in a private window.
2. You are sent to Google: sign in as `nasir@nasir.id`.
3. Back in the portal, `647459380434` is listed with `AdministratorAccess`;
   **Management console** opens the console, **Access keys** shows
   short-lived CLI credentials.

For the CLI (used for `0-bootstrap`):

```sh
aws configure sso
#   SSO session name:        nasir-id
#   SSO start URL:           https://nasir-id.awsapps.com/start
#   SSO region:              ap-southeast-1
#   then pick account 647459380434 and AdministratorAccess
#   profile name:            mgmt-admin
aws sso login --profile mgmt-admin
export AWS_PROFILE=mgmt-admin
aws sts get-caller-identity     # arn:aws:sts::647459380434:assumed-role/AWSReservedSSO_AdministratorAccess_.../nasir@nasir.id
```

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| Google: "app not configured for user" / 403 `app_not_configured_for_user` | The SAML app isn't ON for that user's organizational unit, or not yet propagated. Check **User access**; wait a few minutes. |
| AWS: "Something went wrong" after Google sign-in | No Identity Center user with that exact user name. Create it (or wait for provisioning); the name must equal the Google primary e-mail. |
| AWS: "Invalid SAML response" | ACS URL or Entity ID in Google don't match AWS exactly (region and `d-…` part), or Name ID format isn't EMAIL. Compare with step 2. If they all match and it still fails, replace the catalog app with a **custom SAML app** (same values, no attribute mapping) and upload its metadata in AWS. |
| Google: "Auto-provisioning isn't configured … You can provision 0 apps" | Expected with Cloud Identity Free, which allows no auto-provisioning apps. Ignore it; users are created on the AWS side (step 5). |
| Portal lists no accounts | The user has no account assignment yet (step 6, later `2-identity`). |
| Portal URL changed after Google was set up | Update the Start URL in the Google app; ACS URL and issuer don't change. |
