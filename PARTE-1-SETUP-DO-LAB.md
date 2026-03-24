# PARTE 1: MONTANDO O LAB DO ZERO (Setup Completo)

Esse guia assume: Windows, Azure Subscription ativa, conta pessoal do GitHub (free).
Siga na ordem. Cada passo depende do anterior.

---

## PASSO 0: INSTALAR TUDO NO SEU PC

Abre o PowerShell como Administrador e rode:

```powershell
winget install -e --id Git.Git
winget install -e --id Microsoft.DotNet.SDK.8
winget install -e --id Microsoft.VisualStudioCode
winget install -e --id Microsoft.AzureCLI
winget install -e --id Docker.DockerDesktop
winget install -e --id Kubernetes.kubectl
winget install -e --id GitHub.cli
```

FECHA e REABRE o PowerShell pra garantir que tudo está no PATH.

Testa se deu certo:
```powershell
git --version
dotnet --version
code --version
az --version
docker --version
kubectl version --client
gh --version
```

Se algum não funcionar, instala manualmente pelo site oficial.

---

## PASSO 1: CONFIGURAR O GIT

```powershell
git config --global user.name "Seu Nome"
git config --global user.email "seuemail@gmail.com"
```

---

## PASSO 2: LOGIN NO GITHUB CLI

```powershell
gh auth login
```

Seleciona:
1. GitHub.com
2. HTTPS
3. Login with a web browser
4. Copia o código, cola no browser, autoriza

---

## PASSO 3: LOGIN NO AZURE CLI

```powershell
az login
```

Vai abrir o browser. Loga com sua conta Azure.
Depois confirma qual subscription está ativa:

```powershell
az account show --query "{name:name, id:id}" -o table
```

Se não for a subscription certa:
```powershell
az account list -o table
az account set --subscription "NOME-OU-ID-DA-SUBSCRIPTION"
```

---

## PASSO 4: INSTALAR EXTENSÕES DO VS CODE

```powershell
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension GitHub.vscode-github-actions
code --install-extension ms-dotnettools.csdevkit
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
code --install-extension ms-vscode.azure-account
```

IMPORTANTE sobre o Copilot: você precisa ter uma licença ativa (Copilot Individual, Business ou Enterprise). Se não tiver, vai em https://github.com/features/copilot e ativa o trial de 30 dias gratuito.

---

## PASSO 5: CRIAR O PROJETO

Abre o PowerShell NORMAL (não precisa ser admin).

Você recebeu uma pasta `contoso-petstore-demo-lab` com todos os arquivos do lab.
Copia ela pra ser o seu projeto:

```powershell
# Copia a pasta do lab pra C:\Dev (ajuste o path de origem se necessário)
Copy-Item -Recurse "C:\Downloads\contoso-petstore-demo-lab" "C:\Dev\contoso-petstore"
cd C:\Dev\contoso-petstore
```

Se a pasta de origem tiver outro caminho, ajuste. O importante é que no final você tenha `C:\Dev\contoso-petstore` com todos os arquivos dentro.

Verifica que está tudo lá:
```powershell
dir
# Deve listar: Program.cs, ContosoPetStore.csproj, Dockerfile, src\, k8s\, .github\, etc.
```

---

## PASSO 6: RESTAURAR DEPENDÊNCIAS E TESTAR LOCAL

```powershell
cd C:\Dev\contoso-petstore
dotnet restore
dotnet build
```

Se o build passar SEM ERROS, rode:
```powershell
dotnet run
```

Abre o browser em: http://localhost:5000/swagger

Testa:
1. Clica em GET /api/pets
2. Try it out
3. Execute
4. Deve retornar a lista de pets (Buddy, Whiskers, Rex, Nemo, Luna)

Se funcionou, Ctrl+C pra parar.

---

## PASSO 7: TESTAR O DOCKER LOCAL

Garante que o Docker Desktop está rodando (ícone na bandeja do sistema).

```powershell
cd C:\Dev\contoso-petstore
docker build -t contoso-petstore:local .
docker run -p 8080:8080 contoso-petstore:local
```

Testa: http://localhost:8080/swagger
Se o Swagger abriu e retorna dados, o container funciona.

Ctrl+C pra parar o container.

---

## PASSO 8: CRIAR O REPOSITÓRIO NO GITHUB

IMPORTANTE: No GitHub Free, o GHAS (CodeQL, Secret Scanning) só funciona em repositórios PÚBLICOS. Por isso criamos como público.

```powershell
cd C:\Dev\contoso-petstore

git init
git add -A
git commit -m "feat: initial commit - Contoso Pet Store API"

gh repo create contoso-petstore --public --source=. --remote=origin --push
```

⚠️ ATENÇÃO: O push PODE ser bloqueado pelo Push Protection por causa da fake secret no `DemoVulnerabilitiesController.cs`. Se isso acontecer, o terminal vai mostrar uma URL. Clica nela, seleciona "It's used in tests" e confirma. Isso é ESPERADO e inclusive pode ser um talking point na demo ("olha, o Push Protection bloqueou meu próprio push porque detectou uma credencial no código").

Confirma que subiu: abre https://github.com/SEU-USER/contoso-petstore no browser.

---

## PASSO 9: HABILITAR GHAS NO REPOSITÓRIO

No browser:

1. Abre https://github.com/SEU-USER/contoso-petstore
2. Clica em **Settings** (aba do repo, não do perfil)
3. No menu lateral esquerdo, clica em **Code security**
4. Liga TUDO que aparecer:
   - Dependency graph: Enable
   - Dependabot alerts: Enable
   - Dependabot security updates: Enable
   - Secret scanning: Enable
   - Push protection: Enable

O Code Scanning (CodeQL) será habilitado automaticamente pelo workflow ci-cd.yaml que já está no repo. Não precisa configurar manualmente.

---

## PASSO 10: CRIAR A INFRAESTRUTURA AZURE

Abre o PowerShell. Vamos criar recurso por recurso.

PRIMEIRO, define as variáveis (roda esse bloco inteiro de uma vez):

```powershell
$RANDOM_SUFFIX = -join ((48..57) + (97..122) | Get-Random -Count 6 | ForEach-Object { [char]$_ })
$ACR_NAME = "contosopetstore$RANDOM_SUFFIX"
$RESOURCE_GROUP = "rg-petstore-demo"
$LOCATION = "eastus2"
$AKS_CLUSTER = "aks-petstore-demo"
$APP_INSIGHTS = "appi-petstore-demo"
$LOG_ANALYTICS = "log-petstore-demo"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  ANOTA ESSES VALORES:" -ForegroundColor Yellow
Write-Host "  ACR Name:       $ACR_NAME" -ForegroundColor Green
Write-Host "  Resource Group: $RESOURCE_GROUP" -ForegroundColor Green
Write-Host "  AKS Cluster:    $AKS_CLUSTER" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
```

ANOTA o ACR_NAME num notepad. Você vai precisar depois.

Agora cria cada recurso (roda um por vez, espera terminar antes de rodar o próximo):

```powershell
# 10.1 Resource Group
Write-Host ">>> Criando Resource Group..." -ForegroundColor Cyan
az group create --name $RESOURCE_GROUP --location $LOCATION -o none
Write-Host "    OK" -ForegroundColor Green
```

```powershell
# 10.2 Azure Container Registry
Write-Host ">>> Criando ACR..." -ForegroundColor Cyan
az acr create `
    --resource-group $RESOURCE_GROUP `
    --name $ACR_NAME `
    --sku Standard `
    --admin-enabled false `
    -o none
Write-Host "    OK" -ForegroundColor Green
```

```powershell
# 10.3 Log Analytics Workspace
Write-Host ">>> Criando Log Analytics..." -ForegroundColor Cyan
$LOG_ID = az monitor log-analytics workspace create `
    --resource-group $RESOURCE_GROUP `
    --workspace-name $LOG_ANALYTICS `
    --location $LOCATION `
    --query id -o tsv
Write-Host "    OK" -ForegroundColor Green
```

```powershell
# 10.4 Application Insights
Write-Host ">>> Criando App Insights..." -ForegroundColor Cyan
$APPINSIGHTS_CONN = az monitor app-insights component create `
    --app $APP_INSIGHTS `
    --location $LOCATION `
    --resource-group $RESOURCE_GROUP `
    --workspace $LOG_ID `
    --application-type web `
    --query connectionString -o tsv

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  App Insights Connection String:" -ForegroundColor Yellow
Write-Host "  $APPINSIGHTS_CONN" -ForegroundColor Green
Write-Host "  ANOTA ESSE VALOR" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
```

```powershell
# 10.5 AKS Cluster
# DEMORA ~5 MINUTOS. Vai tomar um café.
Write-Host ">>> Criando AKS (~5 min)..." -ForegroundColor Cyan
az aks create `
    --resource-group $RESOURCE_GROUP `
    --name $AKS_CLUSTER `
    --node-count 2 `
    --node-vm-size Standard_B2s `
    --enable-managed-identity `
    --attach-acr $ACR_NAME `
    --enable-addons monitoring `
    --workspace-resource-id $LOG_ID `
    --generate-ssh-keys `
    -o none
Write-Host "    OK" -ForegroundColor Green
```

```powershell
# 10.6 Configura kubectl pra acessar o cluster
Write-Host ">>> Configurando kubectl..." -ForegroundColor Cyan
az aks get-credentials `
    --resource-group $RESOURCE_GROUP `
    --name $AKS_CLUSTER `
    --overwrite-existing

# Testa se funcionou
kubectl get nodes
# Deve mostrar 2 nodes com Status: Ready
```

```powershell
# 10.7 Cria namespace e secret do App Insights no cluster
kubectl create namespace petstore

kubectl create secret generic petstore-secrets `
    --namespace petstore `
    --from-literal=appinsights-connection-string="$APPINSIGHTS_CONN"

Write-Host "    Namespace e secret criados" -ForegroundColor Green
```

---

## PASSO 11: CRIAR O SERVICE PRINCIPAL PARA O GITHUB ACTIONS

```powershell
$SUBSCRIPTION_ID = az account show --query id -o tsv

$SP_JSON = az ad sp create-for-rbac `
    --name "sp-petstore-github" `
    --role contributor `
    --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP `
    --json-auth

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Service Principal JSON:" -ForegroundColor Yellow
Write-Host $SP_JSON
Write-Host ""
Write-Host "  COPIA ESSE JSON INTEIRO" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green
```

Copia esse JSON. Você vai colar no GitHub no próximo passo.

---

## PASSO 12: CONFIGURAR SECRETS E VARIABLES NO GITHUB

### Opção A: Pelo CLI

```powershell
cd C:\Dev\contoso-petstore

# Secret: cola o JSON do Service Principal quando o terminal pedir
gh secret set AZURE_CREDENTIALS

# Variables
gh variable set ACR_NAME --body "$ACR_NAME"
gh variable set AKS_CLUSTER --body "$AKS_CLUSTER"
gh variable set AKS_RG --body "$RESOURCE_GROUP"
```

### Opção B: Pelo browser

1. Vai em https://github.com/SEU-USER/contoso-petstore/settings/secrets/actions
2. Clica "New repository secret"
   - Name: `AZURE_CREDENTIALS`
   - Value: cola o JSON inteiro do Service Principal
3. Vai pra aba "Variables"
4. Clica "New repository variable" e adiciona:
   - `ACR_NAME` = o valor que você anotou no Passo 10
   - `AKS_CLUSTER` = `aks-petstore-demo`
   - `AKS_RG` = `rg-petstore-demo`

---

## PASSO 13: CONFIGURAR O ENVIRONMENT DE PRODUÇÃO

1. Vai em https://github.com/SEU-USER/contoso-petstore/settings/environments
2. Clica "New environment"
3. Nome: `production`
4. (RECOMENDADO pra demo) Adiciona "Required reviewer" com seu user. Isso habilita approval manual no deploy, que é ótimo pra mostrar na demo. Porém, se preferir automático pra simplificar, não adiciona reviewer.

---

## PASSO 14: PRIMEIRO DEPLOY

Faz uma mudança mínima e push pra triggar o pipeline:

```powershell
cd C:\Dev\contoso-petstore

Add-Content -Path README.md -Value "`n<!-- first deploy trigger -->"
git add -A
git commit -m "ci: trigger first pipeline run"
git push
```

Vai em https://github.com/SEU-USER/contoso-petstore/actions e acompanha:

1. **Security Scan** (CodeQL) ~3 min
2. **Build & Push to ACR** ~5 min
3. **Deploy to AKS** ~2 min (se configurou reviewer, precisa aprovar)

---

## PASSO 15: VALIDAR QUE TUDO FUNCIONOU

```powershell
# Verifica os pods (deve mostrar 3 pods Running)
kubectl get pods -n petstore

# Pega o IP externo (pode demorar 1-2 min pra sair de <pending>)
kubectl get svc -n petstore

# Quando tiver IP, salva numa variável
$IP = kubectl get svc petstore-api -n petstore -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
Write-Host "API URL: http://$IP" -ForegroundColor Green

# Testa
Invoke-RestMethod "http://$IP/api/pets" | ConvertTo-Json
Invoke-RestMethod "http://$IP/api/health/ready" | ConvertTo-Json
```

Abre no browser: http://<IP>/swagger

Se retornou a lista de pets, PARABÉNS!

---

## PASSO 16: GERAR DADOS NO APP INSIGHTS

```powershell
$IP = kubectl get svc petstore-api -n petstore -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

for ($i = 1; $i -le 50; $i++) {
    Invoke-RestMethod "http://$IP/api/pets" | Out-Null
    Invoke-RestMethod "http://$IP/api/pets/1" | Out-Null
    Invoke-RestMethod "http://$IP/api/pets/search?species=Dog" | Out-Null
    Invoke-RestMethod "http://$IP/api/health/ready" | Out-Null
    try { Invoke-RestMethod "http://$IP/api/pets/999" } catch {}
    Start-Sleep -Milliseconds 200
    Write-Host "." -NoNewline
}
Write-Host ""
Write-Host "Trafego gerado! Espera ~2 min pro App Insights processar." -ForegroundColor Green
```

---

## PASSO 17: ESPERAR O CODEQL PROCESSAR

O CodeQL leva 5-15 minutos pra analisar o código pela primeira vez.

Checa em: https://github.com/SEU-USER/contoso-petstore/security/code-scanning

Alertas esperados:
- SQL Injection (cs/sql-injection) na DemoVulnerabilitiesController
- Path Traversal (cs/path-injection) na DemoVulnerabilitiesController
- Possivelmente Log Injection (cs/log-forging)

Checa Secret Scanning em: https://github.com/SEU-USER/contoso-petstore/security/secret-scanning
Deve ter pego o fake token ou connection string no DemoVulnerabilitiesController.

Se não apareceu nada, espera. A primeira análise demora mais.

---

## PASSO 18: VERIFICAÇÃO FINAL (CHECKLIST)

- [ ] **GitHub repo**: código visível, todos os arquivos
- [ ] **GitHub Actions**: pelo menos 1 run verde (3/3 jobs OK)
- [ ] **GitHub Security > Code scanning**: alertas do CodeQL aparecendo
- [ ] **GitHub Security > Secret scanning**: pelo menos 1 alerta
- [ ] **Azure Portal > ACR > Repositories**: imagem `contoso-petstore` com tags
- [ ] **Azure Portal > AKS > Workloads**: 3 pods petstore-api Running
- [ ] **Azure Portal > App Insights > Live Metrics**: mostra dados recentes
- [ ] **Swagger**: http://<IP>/swagger abre e funciona
- [ ] **VS Code**: Copilot ativo (ícone no canto inferior direito)

Se tudo está checado, o lab está pronto!

---

## QUANTO CUSTA MANTER O LAB?

| Recurso | Custo estimado/dia |
|---------|-------------------|
| AKS (2x Standard_B2s) | ~$3.00 |
| ACR (Standard) | ~$0.60 |
| App Insights | ~$0.10 |
| Log Analytics | ~$0.05 |
| **Total** | **~$3.75/dia** |

Pra economizar quando não estiver usando:
```powershell
# Para o AKS (para de cobrar compute)
az aks stop --resource-group rg-petstore-demo --name aks-petstore-demo

# Liga de novo antes da demo (~3 min pra voltar)
az aks start --resource-group rg-petstore-demo --name aks-petstore-demo
```

Pra deletar TUDO (irreversível):
```powershell
az group delete --name rg-petstore-demo --yes --no-wait
```

---

## TROUBLESHOOTING

| Problema | Causa provável | Solução |
|----------|---------------|---------|
| `dotnet build` falha | Faltou `dotnet restore` | Rode `dotnet restore` e tente de novo |
| `docker build` falha | Docker Desktop não rodando | Abre Docker Desktop, espera iniciar |
| Push bloqueado | Push Protection detectou a fake secret | Clica na URL no terminal, "It's used in tests" |
| AKS create falha com quota | Sem quota pra B2s na região | Muda `$LOCATION = "centralus"` e tenta |
| Pipeline falha no Azure Login | Secret AZURE_CREDENTIALS errado | Recria: `gh secret set AZURE_CREDENTIALS` |
| Pods em ImagePullBackOff | AKS sem permissão no ACR | `az aks update -g $RESOURCE_GROUP -n $AKS_CLUSTER --attach-acr $ACR_NAME` |
| EXTERNAL-IP em pending | Normal, demora 1-2 min | Espera e roda `kubectl get svc -n petstore` de novo |
| App Insights sem dados | Connection string errada | Deleta e recria o secret no k8s com a string correta |
| CodeQL não mostra alertas | Primeira análise demora | Espera 15 min. Se nada, checa aba Actions se o job rodou |

---

## SETUP ADICIONAL: TERRAFORM (Infrastructure as Code)

Se você quiser mostrar IaC na demo, siga esses passos extras. Se não, pode pular.

### Instalar Terraform

```powershell
winget install HashiCorp.Terraform
# Fecha e reabre o PowerShell
terraform --version
```

### Bootstrap do Remote State

O Terraform precisa de um storage account pra guardar o state:

```powershell
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

### Configurar Secrets do Terraform no GitHub

O pipeline de Terraform usa secrets separados (não o AZURE_CREDENTIALS JSON, mas valores individuais):

```powershell
# Pega os valores do Service Principal que você já criou
$SP = az ad sp create-for-rbac `
    --name "sp-petstore-terraform" `
    --role contributor `
    --scopes /subscriptions/$(az account show --query id -o tsv) `
    --json-auth | ConvertFrom-Json

# Configura no GitHub
cd C:\Dev\contoso-petstore
gh secret set ARM_CLIENT_ID --body $SP.clientId
gh secret set ARM_CLIENT_SECRET --body $SP.clientSecret
gh secret set ARM_SUBSCRIPTION_ID --body $SP.subscriptionId
gh secret set ARM_TENANT_ID --body $SP.tenantId
```

### Criar o Environment de Infrastructure

1. Vai em https://github.com/SEU-USER/contoso-petstore/settings/environments
2. Clica "New environment"
3. Nome: `infrastructure`
4. (Opcional) Adiciona reviewer pra aprovação manual no `terraform apply`

### Testar localmente

```powershell
cd C:\Dev\contoso-petstore\terraform
terraform init
terraform plan -var-file=environments/demo.tfvars
```

Se o plan mostrar os recursos que vai criar sem erro, está OK. Não precisa rodar `apply` local se preferir que o pipeline faça.

### Trigger do Pipeline

```powershell
cd C:\Dev\contoso-petstore
git add terraform/
git commit -m "infra: add terraform IaC"
git push
```

O workflow `terraform.yaml` vai rodar automaticamente.

---

## SETUP ADICIONAL: SRE AUTO-ROLLBACK

O pipeline ci-cd.yaml agora tem um Job 4 (SRE Health Check) que automaticamente:
1. Gera carga contra a API (30s com `hey`)
2. Espera 30s pro App Insights ingerir
3. Consulta latência média e error rate via API
4. Se latência > 500ms ou error rate > 5%, faz rollback automático

### Configurar a variável APPINSIGHTS_APP_ID

O SRE job precisa do App ID do Application Insights pra fazer queries via API:

```powershell
# Pega o App ID
$APP_ID = az monitor app-insights component show `
    --app appi-petstore-demo `
    --resource-group rg-petstore-demo `
    --query appId -o tsv

# Configura no GitHub
cd C:\Dev\contoso-petstore
gh variable set APPINSIGHTS_APP_ID --body "$APP_ID"
```

### Testar o rollback (opcional, pra treinar antes da demo)

```powershell
# Simula um deploy quebrado (troca a imagem por nginx que não tem /api/pets)
kubectl set image deployment/petstore-api `
    petstore-api=nginx:alpine `
    -n petstore

# Agora faz push pra triggar o pipeline
cd C:\Dev\contoso-petstore
git commit --allow-empty -m "ci: test rollback"
git push

# O Job 4 vai detectar error rate alta e rollback pro version anterior
# Depois, restaura manualmente se necessário:
# kubectl rollout undo deployment/petstore-api -n petstore
```
