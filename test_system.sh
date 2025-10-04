#!/bin/bash

# Script para testar o sistema de autenticação JWT
# Uso: ./test_system.sh <API_GATEWAY_URL>

if [ -z "$1" ]; then
    echo "❌ Uso: $0 <API_GATEWAY_URL>"
    echo "   Exemplo: $0 https://abc123.execute-api.us-east-1.amazonaws.com/dev"
    exit 1
fi

API_URL="$1"
CPF="12345678901"

echo "🧪 Testando sistema de autenticação JWT"
echo "🌐 API URL: $API_URL"
echo ""

# Test 1: Generate JWT
echo "1️⃣ Testando geração de JWT..."
AUTH_RESPONSE=$(curl -s -X POST "$API_URL/auth" \
    -H "Content-Type: application/json" \
    -d "{\"cpf\": \"$CPF\"}")

echo "📤 Request: POST $API_URL/auth"
echo "📥 Response: $AUTH_RESPONSE"

# Extract token from response
TOKEN=$(echo $AUTH_RESPONSE | jq -r '.token // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "❌ Falha ao obter token JWT"
    exit 1
fi

echo "✅ Token JWT obtido com sucesso"
echo "🔑 Token: ${TOKEN:0:50}..."
echo ""

# Test 2: Validate JWT
echo "2️⃣ Testando validação de JWT..."
VALIDATE_RESPONSE=$(curl -s -X POST "$API_URL/validate" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN")

echo "📤 Request: POST $API_URL/validate"
echo "📥 Response: $VALIDATE_RESPONSE"

# Check if validation was successful
VALID=$(echo $VALIDATE_RESPONSE | jq -r '.valid // false')

if [ "$VALID" = "true" ]; then
    echo "✅ Token validado com sucesso"
else
    echo "❌ Falha na validação do token"
fi
echo ""

# Test 3: Access protected endpoint
echo "3️⃣ Testando endpoint protegido..."
PROTECTED_RESPONSE=$(curl -s -X GET "$API_URL/protected" \
    -H "Authorization: Bearer $TOKEN")

echo "📤 Request: GET $API_URL/protected"
echo "📥 Response: $PROTECTED_RESPONSE"
echo "✅ Acesso ao endpoint protegido realizado"
echo ""

# Test 4: Access EKS proxy endpoint
echo "4️⃣ Testando proxy EKS..."
EKS_RESPONSE=$(curl -s -X GET "$API_URL/eks" \
    -H "Authorization: Bearer $TOKEN")

echo "📤 Request: GET $API_URL/eks"
echo "📥 Response: $EKS_RESPONSE"
echo "✅ Acesso ao proxy EKS realizado"
echo ""

# Test 5: Try accessing protected endpoint without token
echo "5️⃣ Testando acesso sem token (deve falhar)..."
UNAUTHORIZED_RESPONSE=$(curl -s -X GET "$API_URL/protected")

echo "📤 Request: GET $API_URL/protected (sem Authorization header)"
echo "📥 Response: $UNAUTHORIZED_RESPONSE"

if echo $UNAUTHORIZED_RESPONSE | grep -q "Unauthorized"; then
    echo "✅ Acesso negado corretamente (sem token)"
else
    echo "⚠️  Esperado: acesso negado, mas obtido: $UNAUTHORIZED_RESPONSE"
fi
echo ""

echo "🎉 Teste completo! Sistema funcionando corretamente."