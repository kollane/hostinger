# Lihtne Dockerfile User Teenuse (Service) jaoks (Harjutus 1)
FROM node:18-slim

WORKDIR /app

# Kopeeri sõltuvuste (dependency) failid
COPY package*.json ./

# Installi sõltuvused (dependencies)
RUN npm install --production

# Kopeeri rakenduse kood
COPY . .

# Avalda port
EXPOSE 3000

# Käivita
CMD ["node", "server.js"]
