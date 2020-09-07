FROM golang:alpine as terraform-onepassword
LABEL maintainer = "Alejandro Alonso <github.com/jandro>"

ENV TERRAFORM_VERSION=0.12.20
ENV TF_DEV=true
ENV TF_RELEASE=true

RUN apk add --update git bash openssh

WORKDIR $GOPATH/src/github.com/hashicorp/terraform
RUN git clone https://github.com/hashicorp/terraform.git ./ && \
    git checkout v${TERRAFORM_VERSION} && \
    /bin/bash scripts/build.sh

ENV OP_TF_PROVIDER=1.1.0

WORKDIR $GOPATH/src/github.com/terraform-provider-1password
RUN git clone https://github.com/anasinnyk/terraform-provider-1password.git ./ && \
    git checkout $OP_TF_PROVIDER && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 && \
    go build -v -o /bin/terraform-provider-onepassword .


FROM python:alpine

COPY --from=terraform-onepassword /go/bin/terraform /bin/
WORKDIR /root/.terraform.d/plugins
COPY --from=terraform-onepassword /bin/terraform-provider-onepassword .

RUN set -xe; \
    apk add --update libc6-compat musl bash make jq; \
    pip install aws-mfa

WORKDIR /
