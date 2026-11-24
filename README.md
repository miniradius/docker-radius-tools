# RADIUS testing tools in Docker

Includes [FreeRADIUS](https://github.com/FreeRADIUS) testing tools:
- `eapol_test, radclient, radcrypt, radeapclient, radlast, radperf, radsecret, radperf, radsniff, radsqlrelay, radtest, radwho, radzap`

Please note that this repository is only Dockerfile tooling and NO SOFTWARE MENTIONED ABOVE IS DISTRIBUTED IN THIS REPOSITORY. All the software is downloaded from official repositories and built during the Docker build process.

## Install
- Container build
```
git clone git@github.com:miniradius/docker-radius-tools.git
cd docker-radius-tools
docker build --platform linux/amd64 . -t radius-tools
```
- Try `docker run -it radius-tools eapol_test -v`

## Notes
- Based on Debian 13 (Trixie) Slim for `linux/amd64`. On other architectures, specify `--platform linux/amd64`, for example `docker run -it --platform linux/amd64 radius-tools radperf`.
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
- The container includes three pre-generated CSV files (`user,password` pairs) in `/accounts/`: `accounts-10.csv`, `accounts-100.csv` and `accounts-1000.csv`. Each filename indicates the number of rows.
- Radperf source: [Network RADIUS Performance Testing](https://networkradius.com/radius-performance-testing/)

## Examples for RADIUS server on localhost (host.docker.internal)

```
docker run -it radius-tools bash
docker run -it radius-tools cat /etc/os-release | grep PRETTY_NAME | sed 's/PRETTY_NAME=//'
docker run -it radius-tools radtest joe foo host.docker.internal:1812 1 abcd
docker run -it radius-tools bash -c 'echo "Message-Authenticator = 0x00" | radclient -r 1 host.docker.internal status abcd'
docker run -it radius-tools bash -c 'echo "User-Name = joe,User-Password = foo" | radperf -x -s -c 1000 -p 300 host.docker.internal:1812 auth abcd'
docker run -it radius-tools radperf -x -s -f /accounts/accounts-1000.csv -c 1 -p 300 host.docker.internal:1812 auth abcd
```
