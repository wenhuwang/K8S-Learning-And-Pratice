FROM alpine:latest
RUN apk --no-cache add \
  ca-certificates
COPY deployment-inject-env /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/deployment-inject-env"]
