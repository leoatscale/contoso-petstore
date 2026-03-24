# PARTE 2: ROTEIRO DA DEMO (O que fazer e o que falar)

Fluxo da demo:
```
VS Code (Copilot) → git push → GitHub (GHAS) → Actions (CI/CD) → ACR → AKS → App Insights
                                                      ↑                          ↓
                                              Terraform (IaC)              SRE Health Check
                                              plan em PR                   latência > 500ms?
                                              apply no merge               error rate > 5%?
                                                                                ↓
                                                                      AUTO-ROLLBACK ← versão anterior
```

Duração: 60-75 minutos (com Terraform e SRE) ou 45-60 (sem)
Público: Devs/DevOps técnicos

---

## ANTES DE COMEÇAR A DEMO (15 min antes)

### 1. Liga o AKS se estava parado:
```powershell
az aks start --resource-group rg-petstore-demo --name aks-petstore-demo
# Espera ~3 min
kubectl get nodes  # Confirma Status: Ready
```

### 2. Salva o IP da API:
```powershell
$IP = kubectl get svc petstore-api -n petstore -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
Write-Host "API: http://$IP/swagger" -ForegroundColor Green
```

### 3. Gera tráfego fresco pro App Insights:
```powershell
for ($i = 1; $i -le 30; $i++) {
    Invoke-RestMethod "http://$IP/api/pets" | Out-Null
    Invoke-RestMethod "http://$IP/api/pets/1" | Out-Null
    try { Invoke-RestMethod "http://$IP/api/pets/999" } catch {}
    Start-Sleep -Milliseconds 300
}
```

### 4. Abre todas as tabs no browser (nessa ordem):
   - Tab 1: GitHub repo (aba Code)
   - Tab 2: GitHub Actions
   - Tab 3: GitHub Security > Code scanning
   - Tab 4: Azure Portal > ACR > Repositories
   - Tab 5: Azure Portal > AKS > Workloads
   - Tab 6: Azure Portal > App Insights > Live Metrics
   - Tab 7: http://<IP>/swagger
   - Tab 8: (Se mostrar Terraform) Um PR anterior com terraform plan output

### 5. Abre o VS Code com o projeto:
```powershell
cd C:\Dev\contoso-petstore
code .
```

### 6. No VS Code, deixa esses arquivos abertos em tabs:
   - Program.cs
   - src/Controllers/PetsController.cs
   - Dockerfile
   - .github/workflows/ci-cd.yaml
   - k8s/deployment.yaml
   - terraform/main.tf (se for mostrar IaC)
   - .github/workflows/terraform.yaml (se for mostrar IaC)

### 7. DESFAZ qualquer mudança do Copilot de testes anteriores:
```powershell
cd C:\Dev\contoso-petstore
git checkout -- .
```
Isso garante que o PetsController.cs está "limpo" pra você adicionar código com o Copilot ao vivo.

---

## ABERTURA (2 min)

> "Hoje vou mostrar o ciclo completo de vida de uma aplicação, do momento que o dev escreve uma linha de código até ela estar rodando em produção com monitoramento.
>
> A gente vai passar por 6 ferramentas e vocês vão ver como elas se conectam: Visual Studio Code com Copilot, GitHub com Advanced Security, GitHub Actions, Azure Container Registry, Azure Kubernetes Service, e Application Insights.
>
> Não é slide. É tudo ao vivo."

---

## ATO 1: VS CODE + GITHUB COPILOT (10 min)

**Onde você está:** VS Code
**Produto:** GitHub Copilot
**Mensagem chave:** "O dev escreve código mais rápido sem sacrificar qualidade"

---

### 1.1 Mostra o projeto (1 min)

Mostra o Explorer do VS Code com a estrutura de arquivos.

> "Isso é uma API .NET 8 de uma Pet Store. Simples de propósito, o foco é no fluxo, não na complexidade da app. Mas tem tudo que uma API real tem: controllers, services, models, Docker, Kubernetes manifests, CI/CD pipeline."

---

### 1.2 Copilot Autocomplete (3 min)

Abre `src/Controllers/PetsController.cs`.
Vai até o final do arquivo, ANTES do último `}`.
Começa a digitar:

```csharp
    /// <summary>
    /// Get statistics about available pets
    /// </summary>
    [HttpGet("stats")]
    public ActionResult GetStats()
    {
```

PARA de digitar. Espera o Copilot sugerir o corpo do método (texto fantasma cinza).
Aceita com Tab.

> "Eu escrevi o doc comment e a assinatura. O Copilot entendeu que eu quero um endpoint de estatísticas, olhou o PetService que já existe no projeto, e gerou a implementação inteira. Eu não copiei de Stack Overflow, não saí do editor. O Copilot entende o CONTEXTO do seu projeto."

DICA: Se o Copilot não sugerir imediatamente, espera 2-3 segundos. Se nada aparecer, adiciona uma linha em branco e digita `var` pra dar um empurrão.

---

### 1.3 Copilot Chat: gerar código (3 min)

Abre o Copilot Chat (Ctrl+Shift+I ou ícone de chat na barra lateral).
Digite:

```
@workspace Create a new endpoint POST /api/pets/batch that accepts a list of PetCreateRequest 
and creates multiple pets at once. Add the method to PetsController and the service interface.
```

Espera a resposta. Mostra o código gerado.

> "Pedi um feature mais complexo, batch create. O Copilot leu o controller, o service, o model, e gerou código que segue o MESMO padrão do projeto. Injeção de dependência, logging, status codes corretos. Não é código genérico, é código que respeita a arquitetura do time."

---

### 1.4 Copilot Instructions (2 min)

Abre `.github/copilot-instructions.md` e mostra.

> "Isso aqui é ouro. Cada repositório pode ter um arquivo de instruções pro Copilot. A gente definiu: use C# 12, use async/await, use FluentAssertions pra testes, siga OWASP. Isso é GOVERNANÇA sobre IA generativa. Não é o dev decidindo sozinho, é o time definindo o padrão e o Copilot seguindo."

---

### 1.5 Transição

> "OK, o dev escreveu código rápido. Agora ele vai fazer push pro GitHub. E é aí que a segurança entra."

---

## ATO 2: GIT PUSH + GITHUB ADVANCED SECURITY (10 min)

**Onde você está:** VS Code (terminal) + GitHub (browser)
**Produto:** GHAS (CodeQL, Secret Scanning, Dependency Review)
**Mensagem chave:** "Segurança shift-left: encontra vulnerabilidades antes de virar problema"

---

### 2.1 Mostra o código vulnerável (2 min)

Abre `src/Controllers/DemoVulnerabilitiesController.cs` no VS Code.

> "Esse controller tem vulnerabilidades intencionais. SQL Injection aqui (mostra a linha), credenciais hardcoded aqui, Path Traversal aqui. Isso acontece em qualquer empresa. A pergunta não é SE vai ter vulnerabilidade, é QUANDO vocês vão descobrir. Antes ou depois de ir pra produção?"

---

### 2.2 Faz o push (1 min)

No terminal do VS Code:

```powershell
git add -A
git commit -m "feat: add stats endpoint and batch create"
git push
```

> "Código está no GitHub. Agora vamos ver o que acontece automaticamente."

NOTA: Esse push vai triggar o pipeline (que vamos ver no Ato 3) E o CodeQL scan. Perfeito pra mostrar tudo integrado.

---

### 2.3 GitHub Security tab (5 min)

Muda pro browser. Vai na Tab 3 (Security > Code scanning).

IMPORTANTE: Os alertas que você vai mostrar são do scan ANTERIOR (que já rodou durante o setup). O scan do push que você acabou de fazer ainda vai estar rodando. Isso é normal.

Mostra os alertas do CodeQL:
- Clica no alerta de SQL Injection
- Mostra o "Show paths": como o dado vai do input do usuário até a query SQL
- Mostra a severidade e a recomendação de fix

> "O CodeQL não é um grep por padrão. Ele faz análise de DATA FLOW. Rastreia o dado desde o input do usuário, passando por variáveis e funções, até chegar no ponto perigoso. Pega vulnerabilidades que um code review manual dificilmente encontraria."

Mostra Secret Scanning (Security > Secret scanning):

> "Secret Scanning detectou credenciais hardcoded no código. Com Push Protection habilitado, se o dev tentar fazer push de um commit com uma secret, o git push é BLOQUEADO. A credencial nem chega no repositório."

---

### 2.4 Dependency Review (2 min)

Mostra o arquivo `.github/workflows/dependency-review.yaml`:

> "Em toda Pull Request, rodamos o Dependency Review automaticamente. Se alguém adicionar um pacote NuGet com vulnerabilidade conhecida, o PR é bloqueado. Supply chain security automático."

---

### 2.5 Transição

> "A segurança checou o código. Agora vamos pro CI/CD e ver o pipeline que acabou de triggar."

---

## ATO 3: GITHUB ACTIONS (10 min)

**Onde você está:** GitHub (browser, Tab 2)
**Produto:** GitHub Actions
**Mensagem chave:** "CI/CD nativo, sem servidor pra manter, integrado com tudo"

---

### 3.1 Mostra o pipeline rodando (3 min)

Vai na Tab 2 (Actions). O pipeline deve estar rodando (por causa do push do Ato 2).

Clica na run. Mostra os 3 jobs:

> "O pipeline tem 3 estágios:
>
> Primeiro: Security Scan com CodeQL. O GHAS que a gente acabou de ver rodando automaticamente no CI.
>
> Segundo: Build. Compila o .NET, builda a imagem Docker, faz push pro Azure Container Registry, e escaneia a imagem com Trivy pra vulnerabilidades no container.
>
> Terceiro: Deploy no AKS. Aplica os manifests Kubernetes e faz rolling update, zero downtime.
>
> Se qualquer etapa falhar, as próximas não rodam."

---

### 3.2 Mostra o workflow file (3 min)

Volta pro VS Code. Abre `.github/workflows/ci-cd.yaml`.
Navega pelas seções e destaca:

- `on: push/pull_request` → trigger automático
- `needs: security-scan` → dependência entre jobs
- `az acr login` → login seguro no ACR via Service Principal
- `trivy-action` → scan de vulnerabilidades no container
- `environment: production` → protection rules de deploy
- `kubectl rollout status` → validação que o deploy funcionou

> "Tudo é YAML declarativo. Não tem servidor Jenkins pra manter, não tem plugin pra atualizar, não tem agent pra instalar. GitHub-hosted runners, sempre atualizados, pagos por minuto de uso."

---

### 3.3 Environment protection (2 min)

Vai em Settings > Environments > production.

> "O environment de produção tem proteções. Precisa de aprovação manual, só aceita deploy da branch main. Vocês podem adicionar wait timer, deployment branches específicas, secrets que só esse environment acessa."

Se configurou Required Reviewer: mostra a tela de approval no pipeline.

---

### 3.4 Transição

> "O pipeline buildou a imagem e pushed pro registry. Vamos ver onde ela foi parar."

---

## ATO 4: AZURE CONTAINER REGISTRY (5 min)

**Onde você está:** Azure Portal (Tab 4)
**Produto:** ACR
**Mensagem chave:** "Registro privado e seguro, integrado com AKS via Managed Identity"

---

### 4.1 Mostra o ACR no portal (3 min)

Azure Portal > Container Registry > Repositories:
- Clica em `contoso-petstore`
- Mostra as tags (latest + tag com data/SHA)
- Mostra o tamanho da imagem

> "A imagem Docker está armazenada aqui. Multi-stage build, imagem baseada em Alpine, super leve. Cada push gera uma tag única com a data e o SHA do commit. Rastreabilidade total: você sabe exatamente qual commit gerou qual imagem."

---

### 4.2 Integração ACR + AKS (2 min)

> "O AKS tem permissão pra puxar imagens do ACR via Managed Identity. Zero credenciais. Não tem Docker login no cluster, não tem token expirando, não tem secret pra rotacionar. É RBAC nativo do Azure. Zero Trust na prática."

---

### 4.3 Transição

> "A imagem está no registry. Agora vamos ver ela rodando no Kubernetes."

---

## ATO 5: AZURE KUBERNETES SERVICE (10 min)

**Onde você está:** Azure Portal (Tab 5) + Terminal
**Produto:** AKS
**Mensagem chave:** "Kubernetes gerenciado com zero downtime deployment"

---

### 5.1 Portal do AKS (3 min)

Azure Portal > AKS > Workloads:
- Mostra o deployment `petstore-api` com 3/3 pods
- Clica em um pod, mostra os logs

> "3 réplicas rodando. Se um pod morrer, o Kubernetes cria outro automaticamente. O control plane é gerenciado pela Microsoft, vocês não tocam nele. Focus no que importa: a aplicação."

---

### 5.2 Kubectl ao vivo (3 min)

No terminal do VS Code:
```powershell
kubectl get pods -n petstore -o wide
kubectl get svc -n petstore
```

> "Rolling update strategy: quando fazemos deploy de uma nova versão, o Kubernetes sobe pods novos antes de derrubar os antigos. Zero downtime. O cliente nunca percebe."

---

### 5.3 Mostra os manifests (2 min)

Volta pro VS Code. Abre `k8s/deployment.yaml`. Aponta pra cada seção:

- `replicas: 3` → alta disponibilidade
- `resources.requests/limits` → controle de custo, o pod não consome mais do que o alocado
- `livenessProbe` → se a app travar, o K8s reinicia o pod
- `readinessProbe` → se a app não estiver pronta, tira do load balancer
- `secretKeyRef` → connection string do App Insights vem de Kubernetes Secret, não está no código

> "Tudo declarativo. Infrastructure as Code. O que está no Git é o que está rodando. Se alguém mudar algo direto no cluster, o próximo deploy volta ao estado desejado."

---

### 5.4 Testa a API ao vivo (2 min)

```powershell
# Lista pets
Invoke-RestMethod "http://$IP/api/pets" | ConvertTo-Json

# Cria um pet
$body = @{ name="Demo"; species="Dog"; breed="Labrador"; age=2; price=450 } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "http://$IP/api/pets" -Body $body -ContentType "application/json" | ConvertTo-Json

# Health check
Invoke-RestMethod "http://$IP/api/health/ready" | ConvertTo-Json
```

Mostra o Swagger no browser (Tab 7).

> "API rodando em produção, respondendo requests. Vamos ver o que está acontecendo por trás."

---

## ATO 6: APPLICATION INSIGHTS (5 min)

**Onde você está:** Azure Portal (Tab 6)
**Produto:** Azure Monitor / Application Insights
**Mensagem chave:** "Observabilidade completa com uma linha de código"

---

### 6.1 Live Metrics (2 min)

Vai na Tab 6 (App Insights > Live Metrics).
ENQUANTO mostra a tela, gera tráfego no terminal pra aparecer ao vivo:

```powershell
for ($i = 1; $i -le 30; $i++) {
    Invoke-RestMethod "http://$IP/api/pets" | Out-Null
    Start-Sleep -Milliseconds 400
}
```

> "Olha os requests entrando em tempo real. Server response time, request rate, failure rate. Adicionamos UMA LINHA no Program.cs: `AddApplicationInsightsTelemetry()`. Nenhuma outra configuração. Distributed tracing, métricas de performance, detecção de anomalias, alertas, tudo incluso."

---

### 6.2 Transaction Search (2 min)

Gera um request que retorna 404:
```powershell
try { Invoke-RestMethod "http://$IP/api/pets/999" } catch { $_.Exception.Message }
```

Vai em App Insights > Transaction Search. Filtra últimos 30 min.
Mostra o request 404. Clica nele. Mostra os detalhes: status code, duração, logs.

> "Cada request tem um trace completo. Quando algo dá errado em produção às 3 da manhã, vocês sabem exatamente o que aconteceu sem precisar adivinhar."

---

### 6.3 Application Map (1 min)

Vai em App Insights > Application Map.

> "Mapa visual de todas as dependências. Conforme vocês adicionarem banco de dados, filas, outros microservices, tudo aparece aqui com tempo de resposta e taxa de erro por componente."

---

## ATO 7: INFRASTRUCTURE AS CODE COM TERRAFORM (10 min)

**Onde você está:** VS Code + GitHub
**Produto:** Terraform + GitHub Actions
**Mensagem chave:** "Infra declarativa, versionada, com review em PR e apply automático"

NOTA: Esse ato é opcional. Se o público for mais dev que infra, pode pular direto pro Ato 8 ou pro Encerramento.

---

### 7.1 Mostra a estrutura do Terraform (2 min)

No VS Code, abre o Explorer e expande a pasta `terraform/`.

> "Toda a infraestrutura Azure que vocês viram até agora, o AKS, ACR, App Insights, VNet, Key Vault, está definida como código nessa pasta. Terraform com módulos separados por responsabilidade."

Abre `terraform/main.tf` e mostra os module blocks:

> "Cada componente é um módulo independente: networking, ACR, AKS, monitoring, Key Vault. O root module orquestra tudo e passa as dependências entre eles. Por exemplo, o AKS recebe o subnet ID do networking e o ACR ID pra configurar o pull permission."

---

### 7.2 Mostra o networking module (2 min)

Abre `terraform/modules/networking/main.tf`.

> "VNet com 3 subnets: uma pro AKS, uma pra aplicação, uma pra dados. Cada uma com seu NSG. A subnet de dados só aceita tráfego da subnet do AKS. Defense in depth."

---

### 7.3 Pipeline de Terraform no GitHub Actions (3 min)

Abre `.github/workflows/terraform.yaml` no VS Code.

> "O pipeline de infra é separado do pipeline de app. Funciona assim:
>
> Quando alguém abre um PR que toca a pasta terraform/, o GitHub Actions roda `terraform plan` e POSTA o output como comentário no PR. O reviewer vê exatamente o que vai mudar na infra antes de aprovar.
>
> Quando o PR é mergeado na main, roda `terraform apply` automaticamente."

Se tiver tempo, mostra um PR anterior com o plan output como comentário (se já rodou). Se não:

> "Imagina o cenário: um dev quer aumentar os nodes do AKS de 3 pra 5. Ele muda uma linha no tfvars, abre um PR, e o review mostra exatamente: 'vai modificar 1 recurso, o node_count do AKS de 3 pra 5'. Ninguém precisa acessar o portal."

---

### 7.4 Outputs alimentam o app pipeline (2 min)

Abre `terraform/outputs.tf`:

> "Os outputs do Terraform alimentam o pipeline da aplicação. O nome do ACR, o cluster AKS, o App Insights App ID, tudo sai daqui e vai pro GitHub Variables automaticamente. Infra e app conectados pelo código."

---

### 7.5 Transição

> "Infra como código, versionada, com review. Agora vou mostrar o que acontece quando um deploy dá errado em produção."

---

## ATO 8: SRE AUTO-ROLLBACK (10 min)

**Onde você está:** GitHub Actions + Terminal
**Produto:** GitHub Actions + Application Insights (integração SRE)
**Mensagem chave:** "Deploy falhou? O pipeline detecta e rollback automático. Sem precisar de alguém acordar às 3 da manhã."

ESSE É O ATO COM MAIS IMPACTO. Público técnico adora ver coisas quebrando e se recuperando.

---

### 8.1 Explica o conceito (2 min)

> "O pipeline agora tem 4 jobs, não 3. Depois do deploy, tem o Job 4: SRE Health Check. Ele funciona assim:
>
> 1. Gera carga contra a API por 30 segundos pra produzir telemetria fresca
> 2. Espera 30 segundos pro App Insights processar
> 3. Consulta a API do App Insights: latência média e error rate
> 4. Se latência passar de 500ms ou error rate passar de 5%, faz rollback automático pra versão anterior
>
> Nenhum humano precisa intervir."

---

### 8.2 Mostra o workflow (2 min)

Abre `.github/workflows/ci-cd.yaml` no VS Code. Vai até o job `sre-validation`.

Mostra os steps:
- "Generate test load" com `hey`
- "Check health metrics" com query KQL via API do App Insights
- "AUTO-ROLLBACK" condicional
- "Deployment healthy" se tudo OK

> "Olha a lógica: o step de health check seta um output `needs_rollback`. Os próximos steps usam `if` pra decidir se faz rollback ou celebra. E se faz rollback, o pipeline é marcado como FAILED pra forçar investigação."

---

### 8.3 Simula um deploy quebrado ao vivo (5 min)

ESSA É A PARTE MAIS IMPACTANTE. Faça isso AO VIVO:

No terminal:
```powershell
# Troca a imagem do deployment por nginx (que não tem /api/pets, vai dar 404)
kubectl set image deployment/petstore-api `
    petstore-api=nginx:alpine `
    -n petstore

kubectl rollout status deployment/petstore-api -n petstore
```

Testa que está "quebrado":
```powershell
try { Invoke-RestMethod "http://$IP/api/pets" } catch { Write-Host "❌ ERRO: $($_.Exception.Message)" -ForegroundColor Red }
```

> "Pronto, deploy quebrado. Em produção real, isso seria um bug no código que faz a API retornar erros. Agora vou triggar o pipeline."

```powershell
cd C:\Dev\contoso-petstore
git commit --allow-empty -m "ci: trigger sre rollback demo"
git push
```

Vai pro GitHub Actions e acompanha:
- Jobs 1-3 rodam normal
- Job 4 (SRE Health Check) começa
- Mostra o load test rodando nos logs
- Mostra a query do App Insights
- Mostra o ROLLBACK acontecendo
- Pipeline fica VERMELHO (porque rollback = fail)

> "Olha: o pipeline detectou que a latência/error rate estavam fora do threshold, fez rollback automático pra versão anterior, e marcou como failed pra que o time investigue. Ninguém precisou acordar, ninguém precisou fazer SSH, ninguém precisou olhar dashboards. O pipeline resolveu sozinho."

Confirma que voltou:
```powershell
Invoke-RestMethod "http://$IP/api/pets" | ConvertTo-Json
# Deve funcionar de novo
```

> "A API está respondendo normalmente. Rollback completo."

NOTA: Se não quiser fazer ao vivo por risco de timing, pode mostrar o workflow yaml e explicar o conceito. Mas ao vivo é 10x mais impactante.

---

### 8.4 Transição pro encerramento

> "Vocês viram o ciclo completo: do código ao deploy, com segurança, infra como código, e agora auto-recuperação. Vamos recapitular."

---

## ENCERRAMENTO (3 min)

> "Vamos recapitular o que aconteceu:
>
> 1. O dev escreveu código mais rápido com o Copilot, seguindo os padrões do time.
> 2. Fez git push.
> 3. O GitHub Advanced Security encontrou SQL Injection, credenciais no código, e Path Traversal antes de chegar em produção.
> 4. O GitHub Actions buildou, testou, construiu o container e fez push pro Azure Container Registry.
> 5. O deploy no AKS foi feito com zero downtime.
> 6. O Application Insights está monitorando tudo em tempo real.
> 7. Toda a infraestrutura está definida como código no Terraform, com review em PR e apply automático.
> 8. Quando o deploy deu errado, o pipeline detectou e fez rollback automático.
>
> Do código à produção, com segurança, IaC e auto-recuperação em cada etapa. Esse é o poder do ecossistema GitHub + Azure.
>
> Perguntas?"

---

## RESPOSTAS PARA PERGUNTAS DIFÍCEIS

**"A gente já usa Jenkins/GitLab CI, pra que mudar?"**
> "Não precisa mudar tudo de uma vez. Muitos clientes começam adicionando GHAS no GitHub pra security, mantendo o CI no Jenkins. Depois migram o CI quando o contrato vence. O ponto é: com GitHub Actions, vocês eliminam um servidor pra manter e ganham integração nativa com GHAS, Copilot e Azure."

**"GHAS é caro"**
> "No plano Free com repo público, vocês já tem CodeQL, Secret Scanning e Dependency Review de graça. Pra repos privados, o GHAS custa $49/committer/mês. Compare com o custo médio de um data breach que segundo o relatório da IBM gira em torno de US$4.45 milhões. Uma credencial vazada paga a licença do time inteiro por décadas."

**"AKS é complexo demais pro nosso time"**
> "Concordo que Kubernetes tem curva de aprendizado. Mas olha o que mostrei: o dev fez git push e a aplicação foi deployada. Ele nunca tocou em kubectl. O pipeline cuida de tudo. E o control plane é gerenciado pela Microsoft."

**"E se a gente não quiser Kubernetes? Pode ser App Service?"**
> "Total. O fluxo é o mesmo: Copilot, GitHub, GHAS, Actions, ACR, App Service. Muda só o target do deploy. Posso montar esse cenário se preferirem."

**"Copilot não gera código inseguro?"**
> "Pode gerar, assim como qualquer dev pode escrever código inseguro. A diferença é que integramos com GHAS. O Copilot acelera a escrita, o CodeQL valida a segurança. São complementares."

**"Quanto custa tudo isso?"**
> "Depende do tamanho do time, posso montar uma estimativa personalizada. O ponto importante: vocês pagam pelo que usam. AKS cobra só os nodes, ACR pelo storage, Actions tem 2000 min/mês grátis no plano Free."

**"Por que Terraform e não Bicep/ARM?"**
> "Terraform é multi-cloud e tem o maior ecossistema de módulos. Se vocês são 100% Azure, Bicep é ótimo também. O ponto da demo é mostrar que infra deve ser código versionado com review, independente da ferramenta. Posso adaptar pra Bicep se preferirem."

**"Rollback automático é perigoso, e se der rollback errado?"**
> "Boa pergunta. O rollback volta pra versão anterior que JÁ estava rodando em produção, então é uma versão comprovadamente estável. E o pipeline fica vermelho, forçando o time a investigar. Vocês podem ajustar os thresholds (latência, error rate) pro que faz sentido pro ambiente de vocês."

**"A gente já usa Datadog/Grafana, não App Insights"**
> "O conceito é o mesmo: o pipeline consulta a ferramenta de observabilidade via API depois do deploy. App Insights, Datadog, Grafana Cloud, qualquer um que tenha API funciona. O padrão é o que importa."

---

## SE ALGO DER ERRADO DURANTE A DEMO

| Problema | O que fazer |
|----------|------------|
| Copilot não sugere nada | Ctrl+Shift+P > "Reload Window". Se persistir, fecha e reabre o VS Code |
| Pipeline falha | Abre os logs e transforma em oportunidade: "Viu? O pipeline mostra EXATAMENTE onde falhou. Imagina debugar isso sem CI/CD." |
| AKS pods não estão rodando | `kubectl describe pod <nome> -n petstore` e mostra: "O Kubernetes diz exatamente o que deu errado." |
| App Insights sem dados | Gera tráfego manual: "Dados levam ~2 min pra aparecer, é near real-time, não real-time." |
| Browser lento/travou | Tenha os screenshots do passo 18 como backup. Mas tente sempre mostrar ao vivo |
| Qualquer erro inesperado | "Isso é exatamente o tipo de problema que esse conjunto de ferramentas ajuda a diagnosticar. Sem elas, vocês estariam fazendo SSH numa VM procurando logs." |
| Terraform plan falha | Mostra o erro e diz: "Terraform diz exatamente o que está errado. Sem IaC, vocês descobririam esse conflito só quando alguém clicasse no portal." |
| Rollback não triggou | App Insights pode ter demorado mais que 30s. Diz: "Em produção real, vocês ajustariam o wait time e os thresholds. O padrão está demonstrado." |
| API não voltou após rollback | `kubectl rollout undo deployment/petstore-api -n petstore` no terminal. Diz: "Kubernetes mantém histórico de revisões, rollback manual é sempre uma opção." |
