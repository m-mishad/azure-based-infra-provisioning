
# Azure-Based Infrastructure Provisioning

This project automates the provisioning of Azure infrastructure using **Terraform** and **GitHub Actions**.  
The pipeline supports multi-environment deployments (`dev` and `prod`) with secure handling of secrets and environment variables.

---

## Prerequisites

Before running the pipeline, ensure the following:

1. **Service Principal (SPN)**  
   - Must have sufficient permissions to deploy infrastructure in the target Azure subscription.

2. **Azure Storage Account**  
   - Configure a storage account to store Terraform remote state.

3. **GitHub Environments**  
   - Create two environments: `dev` and `prod` with the following **secrets** and **variables**:

   **Secrets:**  

   | Name                   | Description                                     |
   |------------------------|-------------------------------------------------|
   | `ADMIN_PASSWORD`       | Password for PostgreSQL server                 |
   | `TARGET_CLIENT_SECRET` | Secret for the Service Principal used for deployment |

   **Variables:**  

   | Name                     | Description                         |
   |--------------------------|-------------------------------------|
   | `TARGET_CLIENT_ID`       | Client ID of the Service Principal |
   | `TARGET_SUBSCRIPTION_ID` | Azure Subscription ID               |
   | `TARGET_TENANT_ID`       | Azure Tenant ID                     |

---

## Pipeline Location

Save the workflow at: .github/workflows/terraform-azure.yml



> Replace the environment variables `TF_BACKEND_RG`, `TF_BACKEND_STORAGE`, `TF_BACKEND_CONTAINER`  with the Azure backend configuration.

---

## GitHub Actions Pipeline

The workflow defines multi-environment Terraform deployment. Full YAML:

```yaml
name: Terraform Azure Deploy
run-name: ${{ github.event_name }} - Terraform Multi-Environment

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      operation:
        type: choice
        description: "Terraform operation"
        options: [plan, apply, destroy]
        required: true
      environment:
        type: choice
        description: "Target environment"
        options: [prod, dev]
        required: true

env:
  TERRAFORM_VERSION: "1.13.2"
  TF_BACKEND_RG: "YOUR_RESOURCE_GROUP"
  TF_BACKEND_STORAGE: "YOUR_STORAGE_ACCOUNT"
  TF_BACKEND_CONTAINER: "YOUR_CONTAINER_NAME"

jobs:
  # ==========================================================
  # DEV PLAN + APPLY — Auto for PR + Merge
  # ==========================================================
  dev-deploy:
    name: Infrastructure Provisioning 
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request' || github.event_name == 'push'
    environment: dev

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: '{"clientId":"${{ vars.TARGET_CLIENT_ID }}","clientSecret":"${{ secrets.TARGET_CLIENT_SECRET }}","subscriptionId":"${{ vars.TARGET_SUBSCRIPTION_ID }}","tenantId":"${{ vars.TARGET_TENANT_ID }}"}'

      - name: Terraform Init (Dev)
        run: |
          terraform init \
            -backend-config="resource_group_name=${{ env.TF_BACKEND_RG }}" \
            -backend-config="storage_account_name=${{ env.TF_BACKEND_STORAGE }}" \
            -backend-config="container_name=${{ env.TF_BACKEND_CONTAINER }}" \
            -backend-config="key=dev.tfstate" \
            -backend-config="use_azuread_auth=true"

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan (Dev)
        run: terraform plan -input=false -no-color -var-file="environments/dev.tfvars" -out=tfplan -var "admin_password=${{ secrets.ADMIN_PASSWORD }}" -var "target_tenant_id=${{ vars.TARGET_TENANT_ID}}" -var "target_subscription_id=${{ vars.TARGET_SUBSCRIPTION_ID}}"

      - name: Terraform Apply (Dev)
        if: github.event_name == 'push'
        run: terraform apply -auto-approve -input=false -no-color -var-file="environments/dev.tfvars" -var "admin_password=${{ secrets.ADMIN_PASSWORD }}" -var "target_tenant_id=${{ vars.TARGET_TENANT_ID}}" -var "target_subscription_id=${{ vars.TARGET_SUBSCRIPTION_ID}}"

  # ==========================================================
  # PROD PLAN + APPLY — Only via Workflow Dispatch
  # ==========================================================
  prod-deploy:
    name: Infrastructure Provisioning
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch' && (inputs.environment == 'prod' || inputs.environment == 'dev')
    environment:
      name: prod
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TERRAFORM_VERSION }}

      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: '{"clientId":"${{ vars.TARGET_CLIENT_ID }}","clientSecret":"${{ secrets.TARGET_CLIENT_SECRET }}","subscriptionId":"${{ vars.TARGET_SUBSCRIPTION_ID }}","tenantId":"${{ vars.TARGET_TENANT_ID }}"}'

      - name: Terraform Init (Prod or Dev)
        if: github.event_name == 'workflow_dispatch' && (inputs.environment == 'prod' || inputs.environment == 'dev')
        run: |
          terraform init \
            -backend-config="resource_group_name=${{ env.TF_BACKEND_RG }}" \
            -backend-config="storage_account_name=${{ env.TF_BACKEND_STORAGE }}" \
            -backend-config="container_name=${{ env.TF_BACKEND_CONTAINER }}" \
            -backend-config="key=prod-${{ inputs.environment }}.tfstate" \
            -backend-config="use_azuread_auth=true"

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan (Prod)
        if: inputs.operation == 'plan' || inputs.operation == 'apply'
        run: terraform plan -input=false -no-color -var-file="environments/prod.tfvars" -out=tfplan -var "admin_password=${{ secrets.ADMIN_PASSWORD }}" -var "target_tenant_id=${{ vars.TARGET_TENANT_ID}}" -var "target_subscription_id=${{ vars.TARGET_SUBSCRIPTION_ID}}"

      - name: Terraform Apply (Prod)
        if: inputs.operation == 'apply'
        run: terraform apply -auto-approve -input=false -no-color -var-file="environments/prod.tfvars" -var "admin_password=${{ secrets.ADMIN_PASSWORD }}" -var "target_tenant_id=${{ vars.TARGET_TENANT_ID}}" -var "target_subscription_id=${{ vars.TARGET_SUBSCRIPTION_ID}}"

      - name: Terraform Destroy (Prod or Dev)
        if: inputs.operation == 'destroy' && (inputs.environment == 'prod' || inputs.environment == 'dev')
        run: terraform destroy -auto-approve -input=false -no-color -var-file="environments/${{ inputs.environment }}.tfvars" -var "admin_password=${{ secrets.ADMIN_PASSWORD }}" -var "target_tenant_id=${{ vars.TARGET_TENANT_ID}}" -var "target_subscription_id=${{ vars.TARGET_SUBSCRIPTION_ID}}"



> Replace backend variables (`TF_BACKEND_RG`, `TF_BACKEND_STORAGE`, `TF_BACKEND_CONTAINER`, `key`) with your Azure configuration.

---

## Workflow Overview

The pipeline supports three Terraform operations: `plan`, `apply`, `destroy` and deploys to `dev` automatically or to `prod` manually.

<details>
<summary>Compact Workflow Diagram</summary>

```mermaid
flowchart TD
    A[GitHub Event Trigger] -->|Pull Request / Push| B[Dev Deploy]
    A -->|Workflow Dispatch| C[Prod Deploy]

    subgraph Dev Deploy
        B1[Checkout Repository]
        B2[Setup Terraform]
        B3[Azure Login with SPN]
        B4[Terraform Init (Dev backend)]
        B5[Terraform Validate]
        B6[Terraform Plan]
        B7[Terraform Apply on push]
        B1 --> B2 --> B3 --> B4 --> B5 --> B6 --> B7
    end

    subgraph Prod Deploy
        C1[Checkout Repository]
        C2[Setup Terraform]
        C3[Azure Login with SPN]
        C4[Terraform Init (Prod backend)]
        C5[Terraform Validate]
        C6[Terraform Plan / Apply / Destroy based on input]
        C1 --> C2 --> C3 --> C4 --> C5 --> C6
    end
