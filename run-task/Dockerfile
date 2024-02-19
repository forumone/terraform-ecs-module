FROM node:18 AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY src src
COPY tsconfig.json ./

RUN npm run build

FROM node:18

WORKDIR /app

COPY package*.json ./
RUN npm ci --filter=production

COPY --from=build /app/lib /app/lib

USER node

ENTRYPOINT [ "node", "/app" ]
