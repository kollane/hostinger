# Basic Dockerfile for User Service
# See on lihtne lahendus Harjutusele 1

FROM node:18-alpine

# Seadista töökataloog
WORKDIR /app

# Kopeeri dependency files
COPY package*.json ./

# Paigalda sõltuvused
RUN npm install --production

# Kopeeri rakenduse kood
COPY . .

# Avalda port
EXPOSE 3000

# Käivita rakendus
CMD ["node", "server.js"]
