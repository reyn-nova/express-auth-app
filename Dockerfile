# ---------- Base ----------
FROM node:22-alpine AS base
WORKDIR /usr/src/app
# For native deps (bcrypt/pg build tools if ever needed) + healthcheck curl
RUN apk add --no-cache libc6-compat

# ---------- Dependencies (all, incl. dev) ----------
FROM base AS deps
COPY package.json package-lock.json* ./
RUN npm ci

# ---------- Build ----------
FROM base AS build
COPY package.json package-lock.json* ./
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY . .
RUN npm run build

# ---------- Production dependencies only ----------
FROM base AS prod-deps
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

# ---------- Runtime ----------
FROM node:22-alpine AS runtime
WORKDIR /usr/src/app
ENV NODE_ENV=production

# Run as a non-root user
RUN addgroup -S nodejs && adduser -S expressjs -G nodejs

COPY --from=prod-deps /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/dist ./dist
COPY package.json ./

USER expressjs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/health',res=>process.exit(res.statusCode===200?0:1)).on('error',()=>process.exit(1))"

CMD ["node", "dist/server.js"]
