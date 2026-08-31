# Express + TypeScript + TypeORM Auth API

A minimal, production-shaped authentication service: **sign up**, **sign in**, **sign out**, and a protected **me** endpoint.

## Stack

- Node.js 22 (Alpine)
- Express 4 + TypeScript
- TypeORM + PostgreSQL 16
- JWT stored in an `httpOnly` cookie (also returned in the JSON body for API/mobile clients)
- bcryptjs for password hashing
- class-validator for request validation
- Docker + Docker Compose

## Project structure

```
src/
  config/data-source.ts     TypeORM DataSource config
  entities/User.ts          User entity (auto-hashes password on insert)
  dto/auth.dto.ts           Request validation schemas
  services/auth.service.ts  Business logic
  controllers/               HTTP layer
  middlewares/                validation, auth guard, error handler
  routes/auth.routes.ts     /api/auth/* routes
  app.ts                    Express app wiring
  server.ts                 Entry point (DB connect + listen)
```

## Quick start (Docker)

1. Copy the environment file and adjust as needed:
   ```bash
   cp .env.example .env
   ```
2. Build and start everything (app + Postgres 16):
   ```bash
   docker compose up --build
   ```
3. The API is available at `http://localhost:3000`.

For local development with hot reload instead:
```bash
docker compose -f docker-compose.dev.yml up --build
```

## Quick start (without Docker)

Requires Node 22+ and a running PostgreSQL 16 instance.

```bash
npm install
cp .env.example .env   # point DB_HOST etc. at your local Postgres
npm run dev
```

## API docs (Swagger)

Once the server is running, interactive docs are available at:

- **Swagger UI:** `http://localhost:3000/api-docs`
- **Raw OpenAPI JSON:** `http://localhost:3000/api-docs.json` (importable into Postman/Insomnia)

Docs are generated from JSDoc `@openapi` annotations in `src/routes/auth.routes.ts` and `src/app.ts`, defined in `src/config/swagger.ts`. Add a new annotated block above any new route and it'll show up automatically — no separate spec file to keep in sync.

## API

All endpoints are prefixed with `/api/auth`.

| Method | Path      | Auth required | Description                     |
|--------|-----------|:--------------:|----------------------------------|
| POST   | `/signup` | No             | Create an account                |
| POST   | `/signin` | No             | Log in                           |
| POST   | `/signout`| No             | Clear the auth cookie            |
| GET    | `/me`     | Yes            | Return the current user          |

### POST `/api/auth/signup`

```json
{
  "name": "Ada Lovelace",
  "email": "ada@example.com",
  "password": "StrongPass1"
}
```

Password rules: 8+ characters, at least one uppercase letter, one lowercase letter, and one digit.

**Response `201`:**
```json
{
  "status": "success",
  "message": "Account created successfully",
  "data": {
    "user": { "id": "...", "name": "Ada Lovelace", "email": "ada@example.com", "isEmailVerified": false, "createdAt": "...", "updatedAt": "..." },
    "token": "<jwt>"
  }
}
```
An `httpOnly` cookie named `access_token` is also set.

### POST `/api/auth/signin`

```json
{ "email": "ada@example.com", "password": "StrongPass1" }
```

Returns the same shape as sign up (`200`), and sets the auth cookie.

### POST `/api/auth/signout`

No body required. Clears the auth cookie.

### GET `/api/auth/me`

Requires the `access_token` cookie **or** an `Authorization: Bearer <token>` header.

```json
{ "status": "success", "data": { "user": { "...": "..." } } }
```

## Environment variables

See `.env.example` for the full list: app port, Postgres connection, `JWT_SECRET`, `JWT_EXPIRES_IN`, cookie settings, and `CORS_ORIGIN`.

**Important:** change `JWT_SECRET` to a long, random value before deploying, and set `COOKIE_SECURE=true` (or rely on `NODE_ENV=production`) once you're serving over HTTPS.

## Database schema

`synchronize` is enabled outside of `NODE_ENV=production` for convenience, so the `users` table is created automatically on first run. For production, generate and run real migrations instead:

```bash
npm run migration:generate -- src/migrations/InitialSchema
npm run migration:run
```
