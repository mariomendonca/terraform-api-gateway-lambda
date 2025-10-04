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

// Helper function to generate IAM policy
const generatePolicy = (principalId, effect, resource, context = {}) => {
  return {
    principalId,
    policyDocument: {
      Version: '2012-10-17',
      Statement: [
        {
          Action: 'execute-api:Invoke',
          Effect: effect,
          Resource: resource
        }
      ]
    },
    context
  };
};

exports.handler = async (event) => {
  console.log('Lambda Authorizer event received:', JSON.stringify(event, null, 2));
  
  try {
    // For Lambda Authorizer, token comes in event.authorizationToken
    let token = null;
    
    if (event.type === 'TOKEN') {
      // Lambda Authorizer format
      token = event.authorizationToken;
      if (token && token.startsWith('Bearer ')) {
        token = token.substring(7);
      }
    } else {
      // Direct validation format (for /validate endpoint)
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
    }

    if (!token) {
      if (event.type === 'TOKEN') {
        throw new Error('Unauthorized'); // Lambda Authorizer format
      } else {
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
    }

    // Get JWT secret from Secrets Manager
    const secret = await getSecret(process.env.JWT_SECRET_NAME);

    // Verify token
    const decoded = jwt.verify(token, secret, { algorithms: ["HS256"] });
    
    console.log('Token decoded successfully:', decoded);
    
    if (event.type === 'TOKEN') {
      // Lambda Authorizer response
      return generatePolicy(
        decoded.sub.toString(),
        'Allow',
        event.methodArn,
        {
          userId: decoded.sub.toString(),
          cpf: decoded.cpf,
          name: decoded.name,
          email: decoded.email || ''
        }
      );
    } else {
      // Direct validation response
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
    }
    
  } catch (error) {
    console.error('Token validation error:', error);
    
    if (event.type === 'TOKEN') {
      // Lambda Authorizer - just throw error for unauthorized
      throw new Error('Unauthorized');
    } else {
      // Direct validation - return detailed error
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
  }
};