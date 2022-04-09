NOTE: 🚨 Don't use this Docker image 🚨

I created this while the official zerotier Docker image didn't work for a brief period of time so that (a) I had a working Docker image and (b) I could play with alternative ways of implementing the image. Since the official Docker image [was fixed and improved](https://github.com/zerotier/ZeroTierOne/pull/1596) (to be better than this one) there is no point in using this anymore.

----

# zerotier-docker

ZeroTier on Docker with some extra goodies (like healthchecks). Cloned from ZeroTier's official [Dockerfile](https://github.com/zerotier/ZeroTierOne/blob/master/Dockerfile.release) and [entrypoint.sh](https://github.com/zerotier/ZeroTierOne/blob/master/entrypoint.sh.release).

## Usage From Docker Hub

There is a GitHub action that publishes all commits to this repo [directly to Docker Hub](https://hub.docker.com/r/altano/zerotier). You can use these images, e.g. `altano/zerotier:v1.8.6` (which uses ZeroTier v1.8.6).

Example docker-compose.yaml:

```
volumes:
  data:

services:
  zerotier:
    image: altano/zerotier:v1.8.6
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    volumes:
      - data:/var/lib/zerotier-one
    environment:
      ZEROTIER_NETWORKS: "<YOUR_NETWORK_1> <YOUR_NETWORK_2>"
```

## How This Dockerfile Works

This ZeroTier Dockerfile does a few things differently:

1. There is a built-in health check. Your container will remain `unhealthy` until all ZeroTier networks are successfully joined AND the container is authorized to the network.
1. The entrypoint script leans on ZeroTier's cli commands a little more:
   - For each ZT network X, `zerotier-cli join X`
   - For each ZT network, wait for `zerotier-cli -j listnetworks` to have `"status": OK`

The script will tell you if it's waiting on network authorization.

## Building From This Repo

Alternatively you can build your own images using the files in this repo:

```
git clone git@github.com:altano/zerotier-docker.git zerotier-docker
cd zerotier-docker
./build.sh 1.8.6
```

Then tag the built image and/or push it to Docker Hub, whatever you want, e.g. if the build output is `Successfully built 5c3ca44d8448`:

```
docker tag 5c3ca44d8448 you/zerotier:v1.8.6
docker tag 5c3ca44d8448 you/zerotier:latest
docker login
docker image push --all-tags you/zerotier
```

## Known Issues

- `ctrl-c` takes 10 seconds to kill the container.
- The entrypoint script's last line of output won't show up in STDOUT but does show up in `docker logs -f <container>`.
