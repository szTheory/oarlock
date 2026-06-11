FROM elixir:1.19

# Install debian packages
RUN apt-get update && \
  apt-get install -y postgresql-client inotify-tools curl && \
  rm -rf /var/lib/apt/lists/*

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /app

# Set environment
ENV MIX_ENV=dev

# By default, run the phoenix server. Dependencies will be installed via docker-compose command or entrypoint
CMD ["mix", "phx.server"]
