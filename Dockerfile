FROM ubuntu:trusty
MAINTAINER Daniel R. Kerr <daniel.r.kerr@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y \
 && apt-get install -qq -y imagemagick libace-6.0.3 libev-dev libprotobuf8 libreadline-dev libssl-dev libtk-img libxml-libxml-perl libxml-simple-perl \
 && apt-get install -qq -y autoconf automake gcc help2man make pkg-config \
 && apt-get install -qq -y python python-dev python-lxml python-protobuf python-setuptools tcl8.5 tk8.5 \
 && apt-get install -qq -y bash curl git openssh-server supervisor wget \
 && apt-get install -qq -y bridge-utils ebtables iproute isc-dhcp-server tcpdump uml-utilities quagga \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

RUN git clone https://github.com/coreemu/core.git /opt/core \
 && cd /opt/core \
 && git checkout release-4.8 \
 && ./bootstrap.sh && ./configure && make && make install \
 && cd /root \
 && rm -rf /opt/core

RUN wget -O /opt/emane.tgz https://adjacentlink.com/downloads/emane/emane-0.9.2-release-1.ubuntu-14_04.amd64.tar.gz \
 && cd /opt \
 && tar xzf /opt/emane.tgz \
 && cd /opt/emane-0.9.2-release-1/debs/ubuntu-14_04/amd64 \
 && dpkg -i emane*.deb \
 && cd /root \
 && rm -rf /opt/emane.tgz /opt/emane-0.9.2-release-1

RUN mkdir /var/run/sshd \
 && mkdir /root/.ssh \
 && chmod 700 /root/.ssh \
 && touch /root/.ssh/authorized_keys \
 && chmod 600 /root/.ssh/authorized_keys
EXPOSE 22

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

WORKDIR /root
CMD ["/usr/bin/supervisord"]
