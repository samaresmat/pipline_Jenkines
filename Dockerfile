# ── Stage 1: Build ─────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build --if-present

# ── Stage 2: Run ────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/package*.json ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist ./dist
# If no build step, copy src instead:
# COPY --from=builder /app/src ./src

EXPOSE 8080

CMD ["node", "dist/index.js"]
# Adjust CMD to your entry point, e.g.:
# CMD ["node", "src/server.js"]
# CMD ["python", "app.py"]
# CMD ["./bin/my-app"]

