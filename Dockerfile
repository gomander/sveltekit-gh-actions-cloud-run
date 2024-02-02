FROM node:lts-slim
WORKDIR /app
COPY . .
CMD ["node", "."]
