# Dockerized CORE & EMANE

To start the container with a specific key and custom network, run the following:

```bash
docker run \
    --detach \
    --name <name> \
    --cap-add=ALL \
    --publish 22 \
    --publish 50051 \
    --privileged \
    --volume /lib/modules:/lib/modules \
    devdkerr/core

docker cp <public key> <name>:/root/.ssh/authorized_keys
docker exec <name> chmod 600 /root/.ssh/authorized_keys
docker exec <name> chown root:root /root/.ssh/authorized_keys
```

To launch the container's core user interface locally using X forwarding, run the following:

```bash
ssh \
    -i <private key> \
    -p $(docker inspect --format='{{ (index (index .NetworkSettings.Ports "22/tcp") 0).HostPort }}' <name>) \
    -X root@<docker host> \
    core-gui
```

To stop and remove the container, run the following:

```bash
docker rm -f <name>
```

## Citations

* Comparison of CORE Network Emulation Platforms, Proceedings of IEEE MILCOM Conference, 2010, pp.864-869.
