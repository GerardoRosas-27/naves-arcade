# Multi-stage: Flutter web build then static serve on Railway (PORT)
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Cache dependencies first
COPY pubspec.yaml pubspec.lock ./
RUN flutter config --enable-web \
  && flutter pub get

COPY . .
RUN flutter build web --release --base-href /

# Serve static files; Railway injects PORT
FROM node:20-alpine

WORKDIR /app
RUN npm install -g serve@14

COPY --from=build /app/build/web ./

ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "serve -s /app -l tcp://0.0.0.0:${PORT}"]
