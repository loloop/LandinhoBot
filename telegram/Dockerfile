# Use an official Swift runtime as a parent image
FROM swift:5.9-jammy

# Set the working directory to /app
WORKDIR /app

# Copy the Package.swift and all source files into the container
COPY ./Package.* ./
RUN swift package resolve --skip-update \
        "$([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)"

COPY . .

# Build the Swift package
RUN swift build

# Specify the command to run your Swift package
CMD ["./.build/debug/LandinhoBot"]
