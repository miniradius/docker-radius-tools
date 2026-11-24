# RADIUS testing tools in Docker

Container image for testing RADIUS on Debian 13 (Trixie) Slim. The default image supports `linux/amd64` and `linux/arm64`.

This Git repository contains the Dockerfiles, release automation, and sample account data. The build downloads the third-party source code and binary packages from the locations listed below.

- Debian's [FreeRADIUS utilities](https://packages.debian.org/trixie/freeradius-utils) provide `radclient`, `radcrypt`, `radeapclient`, `radlast`, `radsecret`, `radsniff`, `radsqlrelay`, `radtest`, `radwho` and `radzap`.
- `eapol_test` is compiled from pinned FreeRADIUS and hostap revisions.
- `radperf` is the executable from the MIT-licensed [radperf-rs v0.1.0 release](https://github.com/miniradius/radperf-rs/releases/tag/v0.1.0).

## Quick start

```sh
git clone https://github.com/miniradius/docker-radius-tools.git
cd docker-radius-tools
docker build -t radius-tools .
docker run --rm radius-tools eapol_test -v
docker run --rm radius-tools radperf -v
```

The build selects and verifies the `radperf-rs` binary for the target architecture. The image includes the FreeRADIUS dictionary and sets `FREERADIUS_DICTIONARY_PATH` to its location.

## Container registry

The [release workflow](.github/workflows/publish-image.yml) builds and checks both architectures. When a GitHub Release is published, it pushes a single OCI image index to `ghcr.io/miniradius/docker-radius-tools` under the release tag. A manual workflow run verifies the build and source collection locally on the runner.

The workflow generates `debian-sources-<index-sha256>.tar` during the release build and uploads it as an asset to the [GitHub Release](https://github.com/miniradius/docker-radius-tools/releases) before pushing the image. The archive contains the OCI index, the package inventory for each architecture and the exact Debian source packages for those inventories. The image contains the copyright notices for the packaged utilities, `eapol_test` and `radperf-rs`.

GHCR packages are private on first publication. To allow anonymous pulls, set the package visibility to public in GitHub Packages.

## Connect to a RADIUS server

Inside the container, `localhost` refers to the container itself. To reach a RADIUS server running on the host, use the address for your container engine.

- **Docker Desktop** resolves `host.docker.internal` automatically. [Docker Desktop networking](https://docs.docker.com/desktop/features/networking/networking-how-tos/)
- **Docker Engine on Linux** can use the same name if you add `--add-host=host.docker.internal:host-gateway` to `docker run` before the image name. [Docker run reference](https://docs.docker.com/reference/cli/docker/container/run/#add-host)
- **Podman** can use `host.containers.internal` when its host gateway is available. Replace `docker` with `podman` in the commands and use that hostname for the server. [Podman run reference](https://docs.podman.io/en/stable/markdown/podman-run.1.html)

The server must listen on an address reachable from the container. For a remote server, use its DNS name or IP address.

## Examples

Replace `joe`, `foo` and `abcd` with your test username, password and RADIUS shared secret. Adjust the port to match the server.

Send an authentication request with `radtest`.

```sh
docker run --rm radius-tools \
  radtest joe foo host.docker.internal:1812 1 abcd
```

Send a status request with `radclient` if the server accepts status requests on the specified port. Use `docker run -i` to pass input from the host shell. To run a pipeline entirely inside the container, pass it to `bash -c`.

```sh
printf '%s\n' 'Message-Authenticator = 0x00' |
  docker run --rm -i radius-tools \
    radclient -r 1 host.docker.internal:1812 status abcd
```

Run an authentication load test with `radperf`. The image includes `accounts-10.csv`, `accounts-100.csv` and `accounts-1000.csv` under `/accounts/`. Each file contains test `user,password` pairs.

```sh
docker run --rm radius-tools \
  radperf -s -f /accounts/accounts-1000.csv -c 1 -p 300 host.docker.internal:1812 auth abcd
```

- `-c` sends each input request the specified number of times. With 1,000 accounts and `-c 2`, RadPerf sends 2,000 requests before retries.
- `-p` sets the maximum number of requests in flight at once.
- `-n` sets the rate for new requests in packets per second. Retransmissions follow their own timeouts.
- `-s` prints a summary. Use `-x` to debug individual requests.

## Original RadPerf from Network RADIUS

`Dockerfile.radperf-non-free` builds an optional `linux/amd64` image with the original proprietary [RadPerf 2.0.1 package from Network RADIUS](https://networkradius.com/radius-performance-testing/). Redistribution of that image requires prior permission from Network RADIUS.

```sh
docker build --platform linux/amd64 -f Dockerfile.radperf-non-free -t radius-tools-non-free .
docker run --rm --platform linux/amd64 radius-tools-non-free radperf -v
```
