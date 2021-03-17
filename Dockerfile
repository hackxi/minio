FROM golang:1.16-alpine as builder

LABEL maintainer="MinIO Inc <dev@min.io>"

ENV GOPATH /go
ENV CGO_ENABLED 0
ENV GO111MODULE on

RUN go get github.com/hackxi/s3utils@v1.0.1
RUN go get github.com/hackxi/minio/cmd/gateway@v1.0.2

RUN  \
     apk add --no-cache git && \
#     git clone https://github.com/minio/minio && cd minio && \
     git clone https://github.com/hackxi/minio.git  && cd minio && \
#     cd /opt/git/minio && \
#     go get github.com/hackxi/s3utils@master &&\
#     git checkout master && go install -v -ldflags "$(go run buildscripts/gen-ldflags.go)"
#     go get github.com/hackxi/s3utils \
     git checkout master  && go install -v -ldflags "-s -w -X github.com/hackxi/minio/cmd.Version=2021-03-16T16:53:54Z -X github.com/hackxi/minio/cmd.ReleaseTag=DEVELOPMENT.2021-03-16T16-53-54Z -X github.com/hackxi/minio/cmd.CommitID=fa94682e83ed7c6658d17838cd6c97a3ed725e8f -X github.com/hackxi/minio/cmd.ShortCommitID=fa94682e83ed -X github.com/hackxi/minio/cmd.GOPATH=/go -X github.com/hackxi/minio/cmd.GOROOT="

FROM registry.access.redhat.com/ubi8/ubi-minimal:8.3

ENV MINIO_ACCESS_KEY_FILE=access_key \
    MINIO_SECRET_KEY_FILE=secret_key \
    MINIO_ROOT_USER_FILE=access_key \
    MINIO_ROOT_PASSWORD_FILE=secret_key \
    MINIO_KMS_MASTER_KEY_FILE=kms_master_key \
    MINIO_SSE_MASTER_KEY_FILE=sse_master_key \
    MINIO_UPDATE_MINISIGN_PUBKEY="RWTx5Zr1tiHQLwG9keckT0c45M3AGeHD6IvimQHpyRywVWGbP1aVSGav"

EXPOSE 9000

COPY --from=builder /go/bin/minio /usr/bin/minio
COPY --from=builder /go/minio/CREDITS /licenses/CREDITS
COPY --from=builder /go/minio/LICENSE /licenses/LICENSE
COPY --from=builder /go/minio/dockerscripts/docker-entrypoint.sh /usr/bin/

RUN  \
     microdnf update --nodocs && \
     microdnf install curl ca-certificates shadow-utils util-linux --nodocs && \
     microdnf clean all && \
     echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

VOLUME ["/data"]

CMD ["minio"]
