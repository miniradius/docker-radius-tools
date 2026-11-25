FROM debian:trixie-slim AS build

ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS=yes

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends ca-certificates curl git \
    build-essential pkg-config libssl-dev libnl-3-dev libnl-genl-3-dev && \
    rm -rf /var/lib/apt/lists/*

# Build eapol_test from hostap 2.10 using the pinned FreeRADIUS build script.
RUN git init /freeradius-server && \
    git -C /freeradius-server fetch --depth 1 https://github.com/FreeRADIUS/freeradius-server.git 3ded55b6df1a57a46021a62971c8d0ed5a62d942 && \
    git -C /freeradius-server checkout --detach FETCH_HEAD && \
    mkdir /hostap-build && \
    BUILD_DIR=/hostap-build HOSTAPD_GIT_COMMIT=cff80b4f7d3c0a47c052e8187d671710f48939e4 /freeradius-server/scripts/ci/eapol_test-build.sh && \
    install -m 0755 /freeradius-server/scripts/ci/eapol_test/eapol_test /usr/bin/eapol_test && \
    install -Dm 0644 /hostap-build/hostapd/COPYING /usr/share/doc/eapol_test/copyright

# Install radperf-rs v0.1.1 from the verified release assets.
RUN set -eu; \
    radperf_version=v0.1.1; \
    radperf_asset="radperf-linux-$(dpkg --print-architecture)"; \
    radperf_release="https://github.com/miniradius/radperf-rs/releases/download/${radperf_version}"; \
    radperf_dir="$(mktemp -d)"; \
    cd "$radperf_dir"; \
    curl --fail --silent --show-error --location --remote-name "${radperf_release}/SHA256SUMS"; \
    printf '%s  %s\n' 6a25916d6d3a2e7d52e444098db9f7786c35e267f7d1796cadbbe73a1bed7f50 SHA256SUMS | sha256sum --check; \
    curl --fail --silent --show-error --location --remote-name "${radperf_release}/${radperf_asset}"; \
    sha256sum --check --strict --ignore-missing SHA256SUMS; \
    install -m 0755 "$radperf_asset" /usr/local/bin/radperf; \
    curl --fail --silent --show-error --location --output LICENSE \
        "https://raw.githubusercontent.com/miniradius/radperf-rs/${radperf_version}/LICENSE"; \
    install -Dm 0644 LICENSE /usr/share/doc/radperf-rs/copyright

FROM debian:trixie-slim

LABEL maintainer="github.com/miniradius" \
      org.opencontainers.image.source="https://github.com/miniradius/docker-radius-tools" \
      org.opencontainers.image.description="RADIUS CLI utilities, including eapol_test and radperf-rs"

# Record source versions from the base layers before installing runtime packages.
RUN mkdir -p /usr/share/doc/docker-radius-tools && \
    dpkg-query -W -f='${db:Status-Status} ${source:Package}=${source:Version}\n' | \
        awk '$1 == "installed" { print $2 }' > /usr/share/doc/docker-radius-tools/debian-base-sources.txt && \
    test -s /usr/share/doc/docker-radius-tools/debian-base-sources.txt && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates bind9-utils freeradius-utils libssl3t64 libgcc-s1 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/bin/eapol_test /usr/bin/eapol_test
COPY --from=build /usr/local/bin/radperf /usr/local/bin/radperf
COPY --from=build /usr/share/doc/eapol_test/ /usr/share/doc/eapol_test/
COPY --from=build /usr/share/doc/radperf-rs/ /usr/share/doc/radperf-rs/

ENV FREERADIUS_DICTIONARY_PATH=/usr/share/freeradius

RUN radperf -v

# CSV (user,password pairs) for radperf
COPY ./accounts-10.csv ./accounts-100.csv ./accounts-1000.csv /accounts/

# Launching a shell for interactive work
CMD ["/bin/bash"]

