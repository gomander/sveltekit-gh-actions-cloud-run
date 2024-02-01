# Use the official Node.js Debian image and give this container the name "build"
FROM node:lts-slim AS build
# Create app directory and make it the working directory
WORKDIR /app
# Copy application dependency manifests to the container image
COPY package*.json /app/
# Install dependencies
RUN npm ci
# Copy local code to the container image
COPY . .
# Define arguments passed to the build command
ARG PUBLIC_ENV_VAR_ONE
ARG PUBLIC_ENV_VAR_TWO
# Set environment variables
ENV PUBLIC_ENV_VAR_ONE=$PUBLIC_ENV_VAR_ONE
ENV PUBLIC_ENV_VAR_TWO=$PUBLIC_ENV_VAR_TWO
# Build the application
RUN npm run build
# Remove development dependencies
RUN npm prune --production

# Use the official long-term support Node.js Debian image
FROM node:lts-slim
# Use the preconfigured "node" user for security reasons
USER node
# Create app directory and make it the working directory
WORKDIR /app
# Copy built app from the "build" container image
COPY --from=build /app/build build/
COPY --from=build /app/node_modules node_modules/
COPY package.json .
# Set execution environment to production
ENV NODE_ENV=production
# Run index.js in the build folder to start the application
CMD ["node", "build"]
