# RADIUS testing tools in Docker

Container image for testing RADIUS on Debian 13 (Trixie) Slim, targeting `linux/amd64`.

- Debian's [FreeRADIUS utilities](https://packages.debian.org/trixie/freeradius-utils) provide `radclient`, `radcrypt`, `radeapclient`, `radlast`, `radsecret`, `radsniff`, `radsqlrelay`, `radtest`, `radwho` and `radzap`.
- `eapol_test` is compiled from pinned FreeRADIUS and hostap revisions.
- `radperf` 2.0.1 is installed from the [Network RADIUS package](https://networkradius.com/radius-performance-testing/).

## Quick start

```sh
git clone https://github.com/miniradius/docker-radius-tools.git
cd docker-radius-tools
docker build --platform linux/amd64 -t radius-tools .
docker run --rm --platform linux/amd64 radius-tools eapol_test -v
docker run --rm --platform linux/amd64 radius-tools radperf -v
```

An ARM host needs amd64 emulation to build and run this image. The build runs `radperf -v` after installation to verify that the binary starts.

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
docker run --rm --platform linux/amd64 radius-tools \
  radtest joe foo host.docker.internal:1812 1 abcd
```

Send a status request with `radclient` if the server accepts status requests on the specified port. Use `docker run -i` to pass input from the host shell. To run a pipeline entirely inside the container, pass it to `bash -c`.

```sh
printf '%s\n' 'Message-Authenticator = 0x00' |
  docker run --rm -i --platform linux/amd64 radius-tools \
    radclient -r 1 host.docker.internal:1812 status abcd
```

Run an authentication load test with `radperf`. The image includes `accounts-10.csv`, `accounts-100.csv` and `accounts-1000.csv` under `/accounts/`. Each file contains test `user,password` pairs.

```sh
docker run --rm --platform linux/amd64 radius-tools \
  radperf -s -f /accounts/accounts-1000.csv -c 1 -p 300 host.docker.internal:1812 auth abcd
```

- `-c` sends each input request the specified number of times. With 1,000 accounts and `-c 2`, RadPerf sends 2,000 requests before retries.
- `-p` sets the maximum number of requests in flight at once.
- `-n` limits the send rate in packets per second. Add it when you need a rate cap.
- `-s` prints a summary. Use `-x` to debug individual requests.
