const jwt = require("jsonwebtoken");
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const sm = new SecretsManagerClient();

const getSecret = async (name) => {
  try {
    const res = await sm.send(new GetSecretValueCommand({ SecretId: name }));
    const secretData = JSON.parse(res.SecretString);
    return secretData.jwt_secret;
  } catch (error) {
    console.error('Error getting secret:', error);
    // Fallback for local testing
    return process.env.JWT_SECRET || 'fallback-secret';
  }
};

const fetchCustomerByCpf = async (cpf) => {
  console.log('fetchCustomerByCpf', cpf);
  
  // Mock implementation - replace with actual EKS API call
  // This simulates fetching customer data from EKS
  if (!cpf || cpf.length !== 11) {
    return null;
  }
  
  // Mock customer data
  return {
    cpf,
    name: "Mario Mendonça",
    id: new Date().getTime(),
    email: "mario@example.com"
  };
};

exports.handler = async (event) => {
  console.log('Event received:', JSON.stringify(event, null, 2));
  
  try {
    // Parse request body
    const body = event.isBase64Encoded ? 
      Buffer.from(event.body, 'base64').toString() : 
      event.body;
    
    console.log('Request body:', body);
    
    const { cpf } = JSON.parse(body || "{}");
    
    if (!cpf) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        body: JSON.stringify({ 
          error: "CPF é obrigatório",
          message: "Campo 'cpf' deve ser fornecido no body da requisição"
        })
      };
    }

    // Fetch customer from EKS (mocked for now)
    const customer = await fetchCustomerByCpf(cpf);

    if (!customer) {
      return {
        statusCode: 404,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        body: JSON.stringify({ 
          error: "Customer não encontrado",
          message: `Nenhum customer encontrado para o CPF: ${cpf}`
        })
      };
    }

    // Get JWT secret from Secrets Manager
    const secret = await getSecret(process.env.JWT_SECRET_NAME);

    // Generate JWT token
    const token = jwt.sign(
      { 
        sub: customer.id, 
        cpf: customer.cpf,
        name: customer.name,
        email: customer.email,
        iat: Math.floor(Date.now() / 1000)
      },
      secret,
      {
        algorithm: "HS256",
        expiresIn: "1h"
      }
    );

    const response = {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({ 
        token,
        customer: {
          id: customer.id,
          name: customer.name,
          cpf: customer.cpf
        },
        expiresIn: "1h"
      })
    };

    console.log('Response:', JSON.stringify(response, null, 2));
    return response;

  } catch (err) {
    console.error('Error in auth lambda:', err);
    
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({ 
        error: "Erro interno do servidor",
        message: err.message
      })
    };
  }
};