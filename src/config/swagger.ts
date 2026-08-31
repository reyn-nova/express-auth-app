import swaggerJsdoc from 'swagger-jsdoc';

const PORT = process.env.PORT || 3000;
const COOKIE_NAME = process.env.COOKIE_NAME || 'access_token';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.3',
    info: {
      title: 'Express Auth API',
      version: '1.0.0',
      description:
        'Authentication API built with Express, TypeScript, TypeORM and PostgreSQL. ' +
        'Supports sign up, sign in, sign out, and a protected "me" endpoint. ' +
        `The JWT is set as an httpOnly cookie named \`${COOKIE_NAME}\`, and is also ` +
        'returned in the response body so non-browser clients can send it as a ' +
        '`Authorization: Bearer <token>` header instead.',
      contact: {
        name: 'API Support',
      },
    },
    servers: [
      {
        url: `http://localhost:${PORT}`,
        description: 'Local server',
      },
    ],
    tags: [
      {
        name: 'Auth',
        description: 'Sign up, sign in, sign out, and session endpoints',
      },
      {
        name: 'Health',
        description: 'Service health check',
      },
    ],
    components: {
      securitySchemes: {
        cookieAuth: {
          type: 'apiKey',
          in: 'cookie',
          name: COOKIE_NAME,
        },
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              format: 'uuid',
              example: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
            },
            name: { type: 'string', example: 'Ada Lovelace' },
            email: {
              type: 'string',
              format: 'email',
              example: 'ada@example.com',
            },
            isEmailVerified: { type: 'boolean', example: false },
            createdAt: { type: 'string', format: 'date-time' },
            updatedAt: { type: 'string', format: 'date-time' },
          },
        },
        SignUpRequest: {
          type: 'object',
          required: ['name', 'email', 'password'],
          properties: {
            name: { type: 'string', minLength: 2, maxLength: 100, example: 'Ada Lovelace' },
            email: { type: 'string', format: 'email', example: 'ada@example.com' },
            password: {
              type: 'string',
              format: 'password',
              minLength: 8,
              maxLength: 128,
              example: 'StrongPass1',
              description:
                'At least 8 characters, containing at least one uppercase letter, ' +
                'one lowercase letter, and one number.',
            },
          },
        },
        SignInRequest: {
          type: 'object',
          required: ['email', 'password'],
          properties: {
            email: { type: 'string', format: 'email', example: 'ada@example.com' },
            password: { type: 'string', format: 'password', example: 'StrongPass1' },
          },
        },
        AuthResponse: {
          type: 'object',
          properties: {
            status: { type: 'string', example: 'success' },
            message: { type: 'string', example: 'Signed in successfully' },
            data: {
              type: 'object',
              properties: {
                user: { $ref: '#/components/schemas/User' },
                token: {
                  type: 'string',
                  description: 'JWT access token (also set as an httpOnly cookie).',
                  example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
                },
              },
            },
          },
        },
        MeResponse: {
          type: 'object',
          properties: {
            status: { type: 'string', example: 'success' },
            data: {
              type: 'object',
              properties: {
                user: { $ref: '#/components/schemas/User' },
              },
            },
          },
        },
        MessageResponse: {
          type: 'object',
          properties: {
            status: { type: 'string', example: 'success' },
            message: { type: 'string', example: 'Signed out successfully' },
          },
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            status: { type: 'string', example: 'error' },
            message: { type: 'string', example: 'Invalid email or password' },
          },
        },
        ValidationErrorResponse: {
          type: 'object',
          properties: {
            status: { type: 'string', example: 'error' },
            message: { type: 'string', example: 'Validation failed' },
            errors: {
              type: 'array',
              items: { type: 'string' },
              example: ['A valid email address is required'],
            },
          },
        },
      },
    },
  },
  // Files containing JSDoc @openapi annotations.
  apis: ['./src/routes/*.ts', './src/app.ts', './dist/routes/*.js', './dist/app.js'],
};

export const swaggerSpec = swaggerJsdoc(options);
