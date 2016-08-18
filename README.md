Dockerized CORE & EMANE
========================================

To start the container with a specific key and custom network, run the following:

```bash
docker run \
    -d \
    --name <name> \
    -p 22 \
    --privileged \
    -v <public key>:/root/.ssh/authorized_keys:ro \
    -v <imunes network>:/root/network.imn:rw \
    devdkerr/core
```

To launch the container's core user interface locally using X forwarding, run the following:

```bash
ssh \
    -i rsa \
    -p $(docker inspect --format='{{ (index (index .NetworkSettings.Ports "22/tcp") 0).HostPort }}' <name>) \
    -X root@localhost \
    core-gui
```

To stop and remove the container, run the following:

```bash
docker rm -f <name>
```

Citations
----------------------------------------

* Comparison of CORE Network Emulation Platforms, Proceedings of IEEE MILCOM Conference, 2010, pp.864-869.
