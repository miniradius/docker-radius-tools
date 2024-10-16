# RADIUS testing tools in Docker

Includes [FreeRADIUS](https://freeradius.org/) testing tools:
- `eapol_test, radclient, radcrypt, radeapclient, radlast, radperf, radsecret, radperf, radsniff, radsqlrelay, radtest, radwho, radzap`

Please note that this repository is only Dockerfile tooling and NO SOFTWARE MENTIONED ABOVE IS DISTRIBUTED IN THIS REPOSITORY. All the software is downloaded from official repositories and built during the Docker build process.

## Install

- `git clone git@github.com:miniradius/docker-radius-tools.git`
- `cd docker-radius-tools`
- `docker build --platform linux/amd64 . -t radius-tools`
- Try `docker run -it radius-tools eapol_test -v`

## Notes
- Based on Ubuntu 24.04 amdd64 base image. Running on non-amd64 architectures may cause warnings which can be suppressed with `--platform linux/amd64` e.g. `docker run -it --platform linux/amd64 radius-tools radperf`
- If you're going to use tools really often, create yourself shell aliases.
- Keep the localhost address in mind as we run the tools from the Docker network environment. The localhost address as seen by tools is of course the address of the docker container, not the host. Use either the `host.docker.internal` address or the external IP address of the host if you are testing local RADIUS services:

```
docker run -it radius-tools radtest joe foo host.docker.internal:1812 1 abcd
```

- If pipes are used in the command, they must be run via `bash c '...|...'`

```
docker run -it radius-tools bash -c 'echo "Message-Authenticator = 0x00" | radclient -r 1 host.docker.internal status abcd'
```

- If radperf reads users from a CSV, watch out for the value of the `-c` parameter, because the value acts as a multiplier of the loaded accounts. For example, if the CSV loads 1000 accounts then `-c 2` will fire 2000 requests
- In the root directory of the container there are three pre-generated CSV files (`user,password` pairs) labeled with the number of lines: `accounts-10.csv`, `accounts-100.csv` and `accounts-1000.csv`. They are available here for radperf or other testing purposes.

## Examples for RADIUS server on localhost (host.docker.internal)

```
docker run -it radius-tools bash
docker run -it radius-tools cat /etc/os-release | grep PRETTY_NAME | sed 's/PRETTY_NAME=//'
docker run -it radius-tools radtest joe foo host.docker.internal:1812 1 abcd
docker run -it radius-tools bash -c 'echo "Message-Authenticator = 0x00" | radclient -r 1 host.docker.internal status abcd'
docker run -it radius-tools bash -c 'echo "User-Name = joe,User-Password = foo" | radperf -x -s -c 1000 -p 300 host.docker.internal:1812 auth abcd'
docker run -it radius-tools radperf -x -s -f /accounts-1000.csv -c 1 -p 300 host.docker.internal:1812 auth abcd
```
