# TODO: Fix this Dockerfile

FROM node:20.14.0-alpine3.20 AS build-stage
# SHELL ["/bin/sh", "-o", "pipefail", "-c"]
RUN apk add git curl bash openssh-client
ARG ssh_key_file

# Create an unprivileged user
RUN adduser --disabled-password user
USER user
WORKDIR /home/user
COPY --chown=user ./bootstrap-config-repos .
RUN ./bootstrap-config-repos ~/.ssh/${ssh_key_file}
