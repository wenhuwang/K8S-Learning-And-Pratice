FROM golang:1.22-bullseye AS builder
# RUN apt update && apt install -y libsystemd-dev
WORKDIR /tmp/src
COPY go.mod .
COPY go.sum .
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GO111MODULE=on GOOS=linux GOARCH=amd64 go build -o inject-topology-spread .

FROM alpine:latest
RUN apk --no-cache add \
  ca-certificates
COPY --from=builder /tmp/src/inject-topology-spread /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/inject-topology-spread"]
