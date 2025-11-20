# Lihtne Dockerfile User Service'ile (Harjutus 1)
FROM node:18-slim

WORKDIR /app

# Kopeeri dependency files
COPY package*.json ./

# Installi dependencies
RUN npm install --production

# Kopeeri rakenduse kood
COPY . .

# Avalda port
EXPOSE 3000

# Käivita
CMD ["node", "server.js"]
