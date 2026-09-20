# Stage 1: Build/Asset Preparation
FROM alpine:latest AS builder
RUN apk update && apk upgrade 
WORKDIR /app
COPY index.html .

# Stage 2: Production Lightweight Runner
FROM nginx:1.25-alpine-slim

# Security hardening: Remove default unnecessary HTML files and limit root permissions if needed
RUN rm -rf /usr/share/nginx/html/*

# Copy compiled/prepared application artifact from builder
COPY --from=builder /app/index.html /usr/share/nginx/html/index.html

# Expose standard web port
EXPOSE 80

# Healthcheck instruction for container monitoring
HEALTHCHECK --interval=30s --timeout=3s CMD wget --no-verbose --tries=1 http://localhost/ || exit 1

# Start Nginx in foreground mode for containerized execution
CMD ["nginx", "-g", "daemon off;"]