FROM node:lts-slim
WORKDIR /app
COPY . .
ENV NODE_ENV=production
RUN npm ci
USER node
CMD ["node", "."]
