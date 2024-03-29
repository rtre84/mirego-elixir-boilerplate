# Step 1 - hex dependencies
#
FROM hexpm/elixir:1.12.3-erlang-24.1.2-alpine-3.14.2 AS otp-dependencies

ENV MIX_ENV=prod

WORKDIR /build

# Install Alpine dependencies
RUN apk add --no-cache git   

# Install Erlang dependencies
RUN mix local.rebar --force && \
    mix local.hex --force

# Install hex dependencies
COPY mix.* ./
RUN mix deps.get --only prod

#
# Step 2 - npm dependencies + build the JS/CSS assets
#
FROM node:14.18-alpine3.14 AS js-builder

ENV NODE_ENV=prod

WORKDIR /build

# Install Alpine dependencies
RUN apk update --no-cache && \
    apk upgrade --no-cache && \
    apk add --no-cache git

# Copy hex dependencies
COPY --from=otp-dependencies /build/deps deps

# Install npm dependencies
COPY assets assets
RUN npm ci --prefix assets --no-audit --no-color --unsafe-perm --progress=false --loglevel=error

# Build JS/CSS assets
RUN npm run --prefix assets deploy

#
# Step 3 - build the OTP binary
#
FROM hexpm/elixir:1.12.3-erlang-24.1.2-alpine-3.14.2 AS otp-builder

ARG APP_NAME
ARG APP_VERSION

ENV APP_NAME=${APP_NAME} \
    APP_VERSION=${APP_VERSION} \
    MIX_ENV=prod

WORKDIR /build

# Install Alpine dependencies
RUN apk update --no-cache && \
    apk upgrade --no-cache && \
    apk add --no-cache git

# Install Erlang dependencies
RUN mix local.rebar --force && \
    mix local.hex --force

# Copy hex dependencies
COPY mix.* ./
COPY --from=otp-dependencies /build/deps deps
RUN mix deps.compile

# Compile codebase
COPY config config
COPY lib lib
COPY priv priv
RUN mix compile

# Copy assets from step 1
COPY --from=js-builder /build/priv/static priv/static
RUN mix phx.digest

# Build OTP release
COPY rel rel
RUN mix release

#
# Step 4 - build a lean runtime container
#
FROM alpine:3.14.2

ARG APP_NAME
ARG APP_VERSION

ENV APP_NAME=${APP_NAME} \
    APP_VERSION=${APP_VERSION}

# Install Alpine dependencies
RUN apk update --no-cache && \
    apk upgrade --no-cache && \
    apk add --no-cache bash openssl libgcc libstdc++ ncurses-libs

WORKDIR /opt/mirego_elixir_boilerplate

# Copy the OTP binary from the build step
COPY --from=otp-builder /build/_build/prod/${APP_NAME}-${APP_VERSION}.tar.gz .
RUN tar -xvzf ${APP_NAME}-${APP_VERSION}.tar.gz && \
    rm ${APP_NAME}-${APP_VERSION}.tar.gz

# Copy Docker entrypoint
COPY priv/scripts/docker-entrypoint.sh /usr/local/bin
RUN chmod a+x /usr/local/bin/docker-entrypoint.sh

# Create non-root user
RUN adduser -D mirego_elixir_boilerplate && \
    chown -R mirego_elixir_boilerplate: /opt/mirego_elixir_boilerplate
USER mirego_elixir_boilerplate

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["start"]
