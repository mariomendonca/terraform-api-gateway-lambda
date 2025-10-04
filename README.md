# Sistema de Autenticação JWT com AWS Lambda e API Gateway

Este projeto implementa um sistema completo de autenticação JWT usando AWS Lambda, API Gateway e Secrets Manager, tudo provisionado via Terraform.

## Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Gateway   │    │  Auth Lambda    │    │  Secrets Manager│
│                 │────│                 │────│   (JWT Secret)  │
│  /auth (POST)   │    │  - Recebe CPF   │    └─────────────────┘
│  /validate      │    │  - Busca customer│
│  /protected     │    │  - Gera JWT     │    ┌─────────────────┐
│  /eks           │    └─────────────────┘    │ Validate Lambda │
└─────────────────┘                           │                 │
         │                                    │ - Valida JWT    │
         │            ┌─────────────────┐     │ - Autoriza      │
         └────────────│  JWT Authorizer │─────│   requests      │
                      └─────────────────┘     └─────────────────┘
```

## Funcionalidades

### 1. **Lambda de Autenticação** (`/auth`)
- **Rota:** `POST /auth`
- **Função:** Recebe um CPF, busca o customer (mock por enquanto) e gera um JWT
- **Entrada:** `{"cpf": "12345678901"}`
- **Saída:** `{"token": "jwt_token", "customer": {...}, "expiresIn": "1h"}`

### 2. **Lambda de Validação** (`/validate`) 
- **Rota:** `POST /validate`
- **Função:** Valida tokens JWT
- **Entrada:** Token via header `Authorization: Bearer <token>` ou body `{"token": "..."}`
- **Saída:** `{"valid": true/false, "decoded": {...}}`

### 3. **Rotas Protegidas**
- **`GET /protected`:** Endpoint protegido que requer JWT válido
- **`ANY /eks`:** Proxy para cluster EKS (mock por enquanto)

## Estrutura do Projeto

```
├── terraform/
│   ├── providers.tf       # Configuração do Terraform e AWS Provider
│   ├── variables.tf       # Variáveis do projeto
│   ├── outputs.tf         # Outputs (URLs, ARNs, etc.)
│   ├── secrets.tf         # AWS Secrets Manager
│   ├── iam.tf            # Roles e políticas IAM
│   ├── lambda.tf         # Configuração das Lambdas
│   ├── api_gateway.tf    # API Gateway e rotas
│   └── terraform.tfvars.example
│
├── lambdas/
│   ├── auth-lambda/
│   │   ├── index.js      # Código da Lambda de autenticação
│   │   └── package.json
│   └── validate-lambda/
│       ├── index.js      # Código da Lambda de validação
│       └── package.json
│
└── README.md
```

## Como usar

### 1. Pré-requisitos

- [Terraform](https://terraform.io) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- Credenciais AWS válidas

### 2. Configuração

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
```

Edite o arquivo `terraform.tfvars` com seus valores:

```hcl
aws_region = "us-east-1"
project_name = "jwt-auth-system"
environment = "dev"
jwt_secret = "your-super-secret-jwt-key-change-this-in-production"
lambda_runtime = "nodejs18.x"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Testando o Sistema

Após o deploy, use os endpoints retornados pelo Terraform:

#### Gerar JWT (Rota Pública)
```bash
curl -X POST https://your-api-id.execute-api.us-east-1.amazonaws.com/dev/auth \\
  -H "Content-Type: application/json" \\
  -d '{"cpf": "12345678901"}'
```

#### Validar JWT
```bash
curl -X POST https://your-api-id.execute-api.us-east-1.amazonaws.com/dev/validate \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Acessar Rota Protegida
```bash
curl -X GET https://your-api-id.execute-api.us-east-1.amazonaws.com/dev/protected \\
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

#### Acessar Proxy EKS (Mock)
```bash
curl -X GET https://your-api-id.execute-api.us-east-1.amazonaws.com/dev/eks \\
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Recursos AWS Criados

- **2 Lambda Functions:** auth e validate
- **1 API Gateway:** com rotas públicas e privadas
- **1 Secrets Manager Secret:** para chave JWT
- **IAM Roles e Policies:** para permissões
- **CloudWatch Log Groups:** para logs das Lambdas

## Segurança

- ✅ JWT secret armazenado no AWS Secrets Manager
- ✅ Lambdas com permissões mínimas (principle of least privilege)
- ✅ Tokens JWT com expiração de 1 hora
- ✅ Validação rigorosa de tokens
- ✅ CORS habilitado para desenvolvimento

## Próximos Passos

1. **Integração Real com EKS:** Substituir o mock por chamadas reais para o cluster EKS
2. **Autenticação Externa:** Integrar com sistemas de autenticação existentes
3. **Rate Limiting:** Implementar throttling no API Gateway
4. **Monitoramento:** Adicionar métricas e alertas no CloudWatch
5. **Cache:** Implementar cache para tokens válidos (ElastiCache)

## Limpeza

Para destruir todos os recursos:

```bash
terraform destroy
```

## Troubleshooting

### Erro de Permissão
Se as Lambdas não conseguem acessar o Secrets Manager, verifique se as policies IAM estão corretas.

### Token Inválido
Certifique-se de que o mesmo secret está sendo usado para gerar e validar o token.

### CORS Errors
O projeto já inclui configuração CORS básica. Para produção, configure origins específicos.

## Custos Estimados

- **Lambda:** ~$0.20/1M requests
- **API Gateway:** ~$3.50/1M requests  
- **Secrets Manager:** ~$0.40/month por secret
- **CloudWatch Logs:** ~$0.50/GB

**Estimativa mensal para 100K requests:** ~$2-5 USD