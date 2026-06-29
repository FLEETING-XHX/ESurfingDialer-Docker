FROM gradle:8-jdk17 AS builder

WORKDIR /src
COPY . .
RUN gradle clean shadowJar --no-daemon

FROM eclipse-temurin:17-jre-alpine

RUN addgroup -S esurfing \
    && adduser -S esurfing -G esurfing \
    && apk add --no-cache su-exec

WORKDIR /app

COPY --from=builder /src/build/libs/*-all.jar /app/client.jar
COPY docker/entrypoint.sh /app/entrypoint.sh
COPY docker/healthcheck.sh /app/healthcheck.sh

RUN chmod +x /app/entrypoint.sh /app/healthcheck.sh \
    && mkdir -p /data \
    && chown -R esurfing:esurfing /app /data

VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
  CMD ["/app/healthcheck.sh"]

ENTRYPOINT ["/app/entrypoint.sh"]
