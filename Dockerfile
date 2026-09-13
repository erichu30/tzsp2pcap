FROM debian:bookworm-slim AS build-test

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential libpcap-dev git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY Makefile tzsp2pcap.c ./
RUN make

ARG TARGETARCH
# Build both architectures; execute the binary only on arm64.
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        ./tzsp2pcap -h > /tmp/help.txt 2>&1 && \
        cat /tmp/help.txt && \
        grep -F -- '-R BYTES     Request UDP socket receive buffer via SO_RCVBUF' /tmp/help.txt; \
    elif [ "$TARGETARCH" = "amd64" ]; then \
        echo 'amd64 compilation complete; binary verification skipped'; \
    else \
        echo "Unsupported target architecture: $TARGETARCH" >&2; exit 1; \
    fi

FROM scratch AS binary
COPY --from=build-test /src/tzsp2pcap /tzsp2pcap

FROM nixos/nix:2.28.5 AS nix-build
WORKDIR /src
COPY Makefile tzsp2pcap.c COPYING ./
COPY nix ./nix
# Nix runs inside Docker; syscall filtering is unavailable under emulation.
RUN nix-build nix/release.nix --option sandbox false --option filter-syscalls false \
    && mkdir /out && cp result/bin/tzsp2pcap /out/tzsp2pcap

ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        /out/tzsp2pcap -h > /tmp/help.txt 2>&1 && \
        cat /tmp/help.txt && \
        grep -F -- '-R BYTES     Request UDP socket receive buffer via SO_RCVBUF' /tmp/help.txt; \
    else test "$TARGETARCH" = "amd64"; fi

FROM scratch AS release-base
COPY --from=nix-build /out/tzsp2pcap /tzsp2pcap

# Prove arm64 runs with no Nix store, shared libraries, or shell present.
FROM release-base AS release-arm64
RUN ["/tzsp2pcap", "-h"]

FROM release-base AS release-amd64

FROM release-${TARGETARCH} AS release
