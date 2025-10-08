# Multi-stage Dockerfile for Auth Service (Node.js)
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy source code
COPY . .

# Production stage
FROM node:18-alpine

# Install wget for health checks
RUN apk add --no-cache wget

# Create non-root user (use different GID to avoid conflicts)
RUN addgroup -g 10001 appuser && \
    adduser -D -u 10001 -G appuser appuser

WORKDIR /app

# Copy from builder
COPY --from=builder /app .

# Change ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

EXPOSE 8082

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8082/health || exit 1

CMD ["node", "src/server.js"]
