FROM --platform=linux/amd64 debian:trixie-slim

LABEL architecture="amd64" \
      maintainer="github.com/miniradius" \
      desc="RADIUS CLI utilities from FreeRADIUS (eapol_test, radclient, radcrypt, radeapclient, radlast, radperf, radsecret, radsniff, radsqlrelay, radtest, radwho, radzap)"

ARG DEBIAN_FRONTEND=noninteractive
ARG DEBCONF_NOWARNINGS=yes

# Init bind9-utils, dpkg, freeradius-comon (dictionary) freeradius-utils (tools) and others
RUN apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    --no-install-recommends ca-certificates bind9-utils curl freeradius-common freeradius-utils git \
    build-essential pkg-config libssl-dev libnl-3-dev libnl-genl-3-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists

# Build eapol_test from hostap 2.10 using the pinned FreeRADIUS build script.
RUN git init /freeradius-server && \
    git -C /freeradius-server fetch --depth 1 https://github.com/FreeRADIUS/freeradius-server.git 3ded55b6df1a57a46021a62971c8d0ed5a62d942 && \
    git -C /freeradius-server checkout --detach FETCH_HEAD && \
    HOSTAPD_GIT_COMMIT=cff80b4f7d3c0a47c052e8187d671710f48939e4 /freeradius-server/scripts/ci/eapol_test-build.sh && \
    cp /freeradius-server/scripts/ci/eapol_test/eapol_test /usr/bin/ && \
    rm -rf /freeradius-server

# Install radperf
RUN curl --fail --silent --show-error --location --remote-name \
    https://networkradius.com/assets/packages/radperf/radperf_2.0.1_amd64.deb && \
    dpkg -i radperf_2.0.1_amd64.deb && \
    rm -f radperf_2.0.1_amd64.deb && \
    apt-get remove -y curl && \
    apt-get autoremove -y && \
    ln -s /usr/sbin/radperf /usr/bin/radperf && \
    ln -s /usr/share/freeradius/* /usr/share

# CSV (user,password pairs) for radperf
COPY ./accounts-10.csv ./accounts-100.csv ./accounts-1000.csv /accounts/

# Launching a shell for interactive work
CMD ["/bin/bash"]

