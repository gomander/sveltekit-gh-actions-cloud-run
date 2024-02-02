FROM node:lts-slim
USER node
WORKDIR /app
COPY . .
ENV NODE_ENV=production
CMD ["node", "."]
