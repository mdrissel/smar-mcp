# Use the official Node.js 18 LTS image as base
FROM node:18-alpine AS base

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Development stage
FROM base AS development
RUN npm ci
COPY . .
RUN npm run build
CMD ["npm", "run", "dev"]

# Production stage
FROM base AS production

# Copy the rest of the application code first
COPY . .

# Install all dependencies (needed for build)
RUN npm ci && npm cache clean --force

# Build the TypeScript code
RUN npm run build

# Remove dev dependencies after build
RUN npm prune --production

# Create a non-root user to run the application
RUN addgroup -g 1001 -S nodejs && \
    adduser -S smar-mcp -u 1001

# Change ownership of the app directory to the nodejs user
RUN chown -R smar-mcp:nodejs /app
USER smar-mcp

# Expose the port (though MCP typically uses stdio, this is for potential future HTTP transport)
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production

# Command to run the application
CMD ["npm", "start"]

# Default to production stage
FROM production
