# Use the official slim Debian Node.js image
FROM node:lts-slim
# Set the working directory
WORKDIR /app
# Copy the built app into the working directory
COPY . .
# Set the environment to production
ENV NODE_ENV=production
# Install the app's production dependencies
RUN npm ci
# Set the user to the node user
USER node
# Run index.js
CMD ["node", "."]
