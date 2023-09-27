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
RUN swift build -c release --static-swift-stdlib \
    # Workaround for https://github.com/apple/swift/pull/68669
    # This can be removed as soon as 5.9.1 is released, but is harmless if left in.
    -Xlinker -u -Xlinker _swift_backtrace_isThunkFunction


# Specify the command to run your Swift package
CMD ["./.build/debug/LandinhoBot"]