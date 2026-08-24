FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY src ./src

ENV PORT=18081
EXPOSE 18081

CMD ["npm", "start"]
