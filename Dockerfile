# syntax = docker/dockerfile:1

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t my-app .
# docker run -d -p 80:80 -p 443:443 --name my-app -e RAILS_MASTER_KEY=<value from config/master.key> my-app

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.5
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

ARG SECRET_KEY_BASE
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    # apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 && \
    # apt-get install -y build-essential libvips curl libjemalloc2 libvips sqlite3 bash bash-completion postgresql-contrib libpq-dev libffi-dev tzdata postgresql nodejs npm yarn && \
    apt-get install -y build-essential libvips bash bash-completion libffi-dev postgresql-contrib libpq-dev tzdata postgresql nodejs npm && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN npm install -g yarn

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .


# Capture Git commit information
RUN if [ -d .git ]; then \
      git rev-parse HEAD > REVISION && \
      git log -1 --format=%cd > REVISION_TIME; \
    else \
      echo "unknown" > REVISION && \
      date > REVISION_TIME; \
    fi

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile


# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Copy Git revision information
COPY --from=build /rails/REVISION /rails/REVISION
COPY --from=build /rails/REVISION_TIME /rails/REVISION_TIME

# Set Git revision environment variables
RUN if [ -f /rails/REVISION ] && [ -f /rails/REVISION_TIME ]; then \
    export GIT_COMMIT_SHA=$(cat /rails/REVISION) && \
    export GIT_COMMIT_TIME=$(cat /rails/REVISION_TIME) && \
    echo "export GIT_COMMIT_SHA=\"$GIT_COMMIT_SHA\"" >> /etc/environment && \
    echo "export GIT_COMMIT_TIME=\"$GIT_COMMIT_TIME\"" >> /etc/environment; \
    fi

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]
