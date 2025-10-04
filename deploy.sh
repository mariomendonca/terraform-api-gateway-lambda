#!/bin/bash

# Deploy script for JWT Auth System
set -e

echo "🚀 Iniciando deploy do sistema de autenticação JWT..."

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform não encontrado. Por favor instale o Terraform primeiro."
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI não configurado. Por favor configure suas credenciais AWS."
    exit 1
fi

# Navigate to terraform directory
cd terraform

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 Criando terraform.tfvars a partir do exemplo..."
    cp terraform.tfvars.example terraform.tfvars
    echo "⚠️  IMPORTANTE: Edite o arquivo terraform.tfvars com seus valores antes de continuar!"
    echo "   Pressione ENTER para continuar após editar o arquivo..."
    read -r
fi

echo "🔧 Inicializando Terraform..."
terraform init

echo "📋 Validando configuração..."
terraform validate

echo "🔍 Planejando deployment..."
terraform plan

echo "📤 Deseja aplicar as mudanças? (y/N)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "🚢 Aplicando configuração..."
    terraform apply -auto-approve
    
    echo ""
    echo "✅ Deploy concluído com sucesso!"
    echo ""
    echo "📊 Outputs:"
    terraform output
    
    echo ""
    echo "🎯 Endpoints disponíveis:"
    echo "   POST /auth     - Gerar JWT (público)"
    echo "   POST /validate - Validar JWT (público)" 
    echo "   GET /protected - Endpoint protegido (privado)"
    echo "   ANY /eks      - Proxy EKS (privado)"
    echo ""
    echo "📖 Veja o README.md para exemplos de uso!"
    
else
    echo "❌ Deploy cancelado pelo usuário."
fi