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

exports.handler = async (event) => {
  console.log('Validation event received:', JSON.stringify(event, null, 2));
  
  try {
    // Extract token from different possible sources
    let token = null;
    
    // Check Authorization header
    const authHeader = event.headers?.Authorization || 
                      event.headers?.authorization || 
                      event.headers?.AUTHORIZATION || "";
    
    if (authHeader.startsWith('Bearer ')) {
      token = authHeader.substring(7);
    }
    
    // If not in header, check body
    if (!token && event.body) {
      const body = typeof event.body === "string" ? 
        JSON.parse(event.body) : 
        (event.body || {});
      token = body.token;
    }
    
    // Check query parameters
    if (!token && event.queryStringParameters) {
      token = event.queryStringParameters.token;
    }

    if (!token) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        },
        body: JSON.stringify({ 
          valid: false, 
          error: "Token ausente",
          message: "Token deve ser fornecido no header Authorization (Bearer), body ou query parameter"
        })
      };
    }

    // Get JWT secret from Secrets Manager
    const secret = await getSecret(process.env.JWT_SECRET_NAME);

    // Verify token
    const decoded = jwt.verify(token, secret, { algorithms: ["HS256"] });
    
    console.log('Token decoded successfully:', decoded);
    
    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({ 
        valid: true, 
        decoded: {
          sub: decoded.sub,
          cpf: decoded.cpf,
          name: decoded.name,
          email: decoded.email,
          iat: decoded.iat,
          exp: decoded.exp
        },
        message: "Token válido"
      })
    };
    
  } catch (error) {
    console.error('Token validation error:', error);
    
    let errorMessage = "Token inválido";
    if (error.name === 'TokenExpiredError') {
      errorMessage = "Token expirado";
    } else if (error.name === 'JsonWebTokenError') {
      errorMessage = "Token malformado";
    }
    
    return {
      statusCode: 401,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({ 
        valid: false, 
        error: errorMessage,
        details: error.message
      })
    };
  }
};