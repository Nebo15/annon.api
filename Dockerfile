FROM nebo15/alpine-elixir:1.6.4 as builder
MAINTAINER Nebo#15 support@nebo15.com

# Always build with production environment
ENV MIX_ENV=prod

# `/opt` is a common place for third-party provided packages that are not part of the OS itself
WORKDIR /opt/app

# Required in elixir_make
RUN apk add --update --no-cache make

# Install and compile project dependencies
# We do this before all other files to make container build faster
# when configuration and dependencies are not changed
COPY mix.* ./
COPY config ./config
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy rest of project files and build an OTP application
COPY . .
RUN mix compile
RUN mix release --verbose

# Release is packaged in a tarball that contains everything the application
# needs to run. We remove all other build artifacts and unarchived tarball
# to a well-known folder
RUN set -xe; \
    RELEASE_TARBALL_PATH=$(find _build/${MIX_ENV}/rel/*/releases -maxdepth 2 -name *.tar.gz) && \
    RELEASE_TARBALL_FILENAME="${RELEASE_TARBALL_PATH##*/}" && \
    RELEASE_APPLICATION_NAME="${RELEASE_TARBALL_FILENAME%%.*}" && \
    cp ${RELEASE_TARBALL_PATH} /opt/${RELEASE_TARBALL_FILENAME} && \
    cd /opt && \
    rm -rf /opt/app/ && \
    mkdir -p /opt/${RELEASE_APPLICATION_NAME} && \
    tar -xzf ${RELEASE_TARBALL_FILENAME} -C ${RELEASE_APPLICATION_NAME} && \
    rm ${RELEASE_TARBALL_FILENAME}

# Build a container for runtime
# We are using Linux Alpine image with pre-installed Erlang,
# pure alpine with ERTS from tarball won't work because Erlang VM
# has lots of native dependencies
FROM nebo15/alpine-erlang:20.2.2
MAINTAINER Nebo#15 support@nebo15.com

ENV \
    # Application name
    APPLICATION_NAME=annon_api \
    # Common that we want to expose from a container,
    # make sure that you change this variables after updating
    # them in config.exs
    GATEWAY_PUBLIC_PORT=4000 \
    GATEWAY_PUBLIC_HTTPS_PORT=4000 \
    GATEWAY_MANAGEMENT_PORT=4001 \
    GATEWAY_PRIVATE_PORT=4443 \
    # Replace ${VAR_NAME} in sys.config (generated with your application configuration)
    # at the start time with actual environment variables values
    REPLACE_OS_VARS=true

# Bash is required by Distillery
RUN apk add --update --no-cache bash

# Copy OTP release from a builder stage
COPY --from=builder /opt/${APPLICATION_NAME} /opt/${APPLICATION_NAME}
# Fix file permissions
RUN set xe; \
    chmod -R 777 /opt/${APPLICATION_NAME}

WORKDIR /opt/${APPLICATION_NAME}

# Change user to "default" to limit runtime privileges
USER default

# Exposes this port from the docker container to the host machine
EXPOSE ${GATEWAY_PUBLIC_PORT} ${GATEWAY_PUBLIC_HTTPS_PORT} ${GATEWAY_MANAGEMENT_PORT} ${GATEWAY_PRIVATE_PORT}

# The command to run when this image starts up
# We start application in foreground mode to keep
# the container running and to redirect logs to the `STDOUT`
CMD bin/${APPLICATION_NAME} foreground
