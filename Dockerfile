FROM node:17-alpine3.15

WORKDIR /app

COPY package*.json .

RUN yarn install

COPY . .

CMD ["yarn", "start"]