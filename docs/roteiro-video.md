# Roteiro de evidências — gravação real

Tempo sugerido: 15 a 25 minutos de explicação, além das esperas de provisionamento/deploy. O enunciado não fixa duração. Se acelerar esperas, preserve os comandos, o início/fim de execução e resultados legíveis. Resolução mínima 720p, voz audível. Use somente dados fictícios.

## Preparação

- Configure a gravação para não mostrar senhas, tokens, configurações sensíveis ou entrada de login.
- Deixe repositório, Cloud Shell, Actions, App Service, Query Editor, Application Insights e métricas SQL acessíveis.
- Defina nomes/RMs do grupo e verifique o acesso do professor ao repositório e vídeo.
- Faça um ensaio. Para filmar criação desde o zero depois do ensaio, use outro prefixo exclusivo e lembre-se de remover recursos de ensaio que não serão usados.

## 1. Solução e arquitetura

Fala sugerida: “Este DimDim é uma aplicação Java com interface web para clientes e contas. Os dados ficam no Azure SQL Database, um banco PaaS. Usamos Azure CLI para provisionar e GitHub Actions para compilar, testar e publicar. O Application Insights monitora a aplicação e suas chamadas ao banco.”

Mostre o diagrama de implantação, a relação 1:N e as pastas `scripts`, `.github/workflows`, `src` e `docs`. Explique que não é a Sprint 3.

## 2. Provisionamento

Mostre a execução de `01-provisionar.sh`, sem revelar as entradas ocultas ou configurações. Depois mostre os recursos criados no grupo: App Service, plano, servidor SQL/banco, Application Insights e Log Analytics.

Explique que o SQL é PaaS e não está num container. Mostre o DDL com PK/FK e o firewall configurado para o App Service. Não exponha usuários/senhas SQL.

## 3. Deploy automatizado

Mostre a configuração OIDC e as etapas do GitHub Actions. Execute o workflow e mostre os testes, a implantação e o health check aprovados. Abra o app pela URL `azurewebsites.net`. Faça login fora do trecho visível de gravação de credenciais.

## 4. CRUD com SELECT após cada operação

Mantenha aplicativo e editor SQL lado a lado. Mostre o nome do banco e o horário com `SELECT DB_NAME(), SYSUTCDATETIME();`.

| Marque | Ação | O que narrar/mostrar no banco |
|---|---|---|
| [ ] | Criar cliente | Nova linha e ID em Clientes |
| [ ] | Consultar cliente | Campos da tela iguais aos do SELECT |
| [ ] | Editar cliente | Mesmo ID, novo nome/e-mail |
| [ ] | Criar conta | Nova linha em Contas e FK cliente_id |
| [ ] | Consultar conta | Número/saldo e JOIN com o cliente |
| [ ] | Editar conta | Saldo 100 → 250,50, número atualizado |
| [ ] | Recarregar/reiniciar app | Dados continuam no Azure SQL (opcional) |
| [ ] | Tentar excluir cliente com conta | Bloqueio por relacionamento, dados preservados |
| [ ] | Excluir conta | SELECT pelo ID retorna zero linhas |
| [ ] | Excluir cliente | SELECT pelo ID retorna zero linhas |

Execute o SELECT **logo depois de cada ação**. Não mostre somente a resposta HTTP. Não apague cliente antes de conta, exceto para demonstrar o bloqueio.

Realize os testes pela interface e execute uma consulta independente no Query Editor após cada operação. Grave os resultados da aplicação e do banco.

## 5. Monitoramento

Depois de gerar tráfego e aguardar ingestão:

- [ ] Application Insights Live Metrics com tráfego.
- [ ] Requests/Performance com operações CRUD e duração.
- [ ] Dependencies/Application Map com chamadas SQL.
- [ ] Logs com `requests` e `dependencies`, data/hora da execução.
- [ ] Explique 409/404 esperados se aparecerem como falhas.
- [ ] Azure SQL Metrics com CPU, DTU/sessões/armazenamento.
- [ ] Se disponível, Log Analytics `AzureMetrics` com dados do SQL.

Não confunda tabelas vazias/sem ingestão com evidência de monitoramento funcionando. Não invente falhas ou tráfego; realize operações e mostre o resultado real.

## 6. Encerrar

Mostre onde estão README, DDL, scripts CLI, arquitetura e contratos JSON. Atualize o link do vídeo no README. Finalize o PDF com somente grupo, integrantes/RMs e links, conforme o modelo. Não entregue prints, roteiro ou código dentro do PDF final.
