FROM node:18-alpine

WORKDIR /app

# Kopeeri package failid
COPY package*.json ./

# Paigalda sõltuvused
RUN npm install

# Kopeeri rakenduse failid
COPY . .

EXPOSE 3000

CMD ["npm", "start"]
