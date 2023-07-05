# RADIUS testing tools in Docker

Includes FreeRADIUS testing tools: [FreeRADIUS](https://freeradius.org/):
- `eapol_test, radclient, radcrypt, radeapclient, radlast, radperf, radperf, radsniff, radsqlrelay, radtest, radwho, radzap`

Please note that this is a Docker file only and NO SOFTWARE MENTIONED ABOVE IS DISTRIBUTED IN THIS REPOSITORY. All the software is downloaded from official repositories and built during the Docker build process.

## Install

- `git clone git@github.com:miniradius/docker-radius-tools.git`
- `cd docker-radius-tools`
- `docker build . -t radius-tools`
- Try `docker run -it --rm radius-tools eapol_test -v`

## Notes

- If you're going to use tools really often, create yourself Bash aliases.
- Keep the localhost address in mind as we run the utilities from Docker. The localhost address is of course the address of the docker container, not the host. Use either the `host.docker.internal` address or the host's external IP:

```
docker run -it --rm radius-tools radtest joe foo host.docker.internal:1812 1 abcd
```

- If pipes are used in the command, they must be run via `bash c '...|...'`

```
docker run -it --rm radius-tools bash -c 'echo "Message-Authenticator = 0x00" | radclient -r 1 host.docker.internal status abcd'
```

- If radperf reads users from a CSV, watch out for the value of the `-c` parameter, because the value acts as a multiplier of the loaded accounts. For example, if the CSV loads 1000 accounts then `-c 2` will fire 2000 requests
- In the root directory of the container there are three pre-generated CSV files (`user,password` pairs) labeled with the number of lines: `accounts-10.csv`, `accounts-100.csv` and `accounts-1000.csv`. They are available here for radperf or other testing purposes.

## Examples for RADIUS server on localhost (host.docker.internal)

```
docker run -it --rm radius-tools bash
docker run -it --rm radius-tools cat /etc/os-release | grep PRETTY_NAME | sed 's/PRETTY_NAME=//'
docker run -it --rm radius-tools radtest joe foo host.docker.internal:1812 1 abcd
docker run -it --rm radius-tools bash -c 'echo "Message-Authenticator = 0x00" | radclient -r 1 host.docker.internal status abcd'
docker run -it --rm radius-tools bash -c 'echo "User-Name = joe,User-Password = foo" | radperf -x -s -c 1000 -p 300 host.docker.internal:1812 auth abcd'
docker run -it --rm radius-tools radperf -x -s -f /accounts-1000.csv -c 1 -p 300 host.docker.internal:1812 auth abcd
```
