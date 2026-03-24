# Terraform - Contoso Pet Store Infrastructure

Infrastructure as Code para toda a infra Azure do Contoso Pet Store.

## O que é criado

| Recurso | Module | Detalhe |
|---------|--------|---------|
| Resource Group | root | `rg-petstore-{env}` |
| VNet + 3 Subnets | networking | AKS, App, Data com NSGs |
| NSGs | networking | HTTP/HTTPS inbound, deny-all default |
| Azure Container Registry | acr | Standard SKU, admin disabled |
| Azure Kubernetes Service | aks | 3 nodes B2s, Managed Identity, Calico network policy |
| Application Insights | monitoring | Workspace-based, failure anomaly alert |
| Log Analytics Workspace | monitoring | 30 dias de retenção |
| Key Vault | keyvault | Secrets do App Insights armazenados automaticamente |

## Pré-requisitos

1. Terraform >= 1.5.0 instalado (`winget install HashiCorp.Terraform`)
2. Azure CLI logado (`az login`)
3. Permissão de Contributor na Subscription

## Bootstrap (uma vez só)

Antes de rodar o Terraform, crie o storage account pro remote state:

```powershell
# Cria resource group e storage pro tfstate
az group create --name rg-petstore-tfstate --location eastus2
az storage account create `
    --name stpetstoretfstate `
    --resource-group rg-petstore-tfstate `
    --location eastus2 `
    --sku Standard_LRS
az storage container create `
    --name tfstate `
    --account-name stpetstoretfstate
```

## Como usar

### Init (primeira vez ou quando muda backend/providers)
```powershell
cd terraform
terraform init
```

### Plan (ver o que vai ser criado/modificado)
```powershell
terraform plan -var-file=environments/demo.tfvars
```

### Apply (criar/modificar a infra)
```powershell
terraform apply -var-file=environments/demo.tfvars
```

### Ver outputs (depois do apply)
```powershell
terraform output
terraform output -raw acr_login_server
terraform output -raw aks_cluster_name
```

### Destroy (deletar tudo)
```powershell
terraform destroy -var-file=environments/demo.tfvars
```

## GitHub Actions

O workflow `.github/workflows/terraform.yaml` automatiza tudo:

| Evento | O que acontece |
|--------|---------------|
| PR tocando `terraform/**` | `terraform plan` roda e posta o output como comentário no PR |
| Merge pra main tocando `terraform/**` | `terraform apply` roda automaticamente |

### Secrets necessários no GitHub

| Secret | Valor | Como obter |
|--------|-------|------------|
| `ARM_CLIENT_ID` | App ID do Service Principal | `az ad sp create-for-rbac --json-auth` |
| `ARM_CLIENT_SECRET` | Password do Service Principal | Mesmo comando acima |
| `ARM_SUBSCRIPTION_ID` | ID da Subscription | `az account show --query id -o tsv` |
| `ARM_TENANT_ID` | Tenant ID | `az account show --query tenantId -o tsv` |

## Estrutura

```
terraform/
  main.tf                    # Root module, orquestra tudo
  variables.tf               # Variáveis de input
  outputs.tf                 # Outputs pro pipeline de app
  locals.tf                  # Tags comuns
  environments/
    demo.tfvars              # Valores pro ambiente demo
  modules/
    networking/main.tf       # VNet, Subnets, NSGs
    acr/main.tf              # Container Registry
    aks/main.tf              # Kubernetes Service
    monitoring/main.tf       # Log Analytics + App Insights
    keyvault/main.tf         # Key Vault
```
