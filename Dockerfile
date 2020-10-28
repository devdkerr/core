FROM ubuntu:bionic
LABEL maintainer "Daniel R. Kerr <daniel.r.kerr@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm

# install core dependencies
#---------------------------------------
RUN apt-get update -y \
 && apt-get install -qq -y libev-dev libpcap-dev libreadline-dev libtk-img libtool \
 && apt-get install -qq -y python3 python3-dev python3-pip python3-setuptools python3-tk \
 && apt-get install -qq -y autoconf automake gawk g++ gcc git pkg-config tk \
 && apt-get install -qq -y bridge-utils ebtables ethtool iproute2 radvd \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# install ospf mdf
#---------------------------------------
RUN git clone https://github.com/USNavalResearchLaboratory/ospf-mdr.git /opt/ospf-mdr \
 && cd /opt/ospf-mdr \
 && ./bootstrap.sh \
 && ./configure \
    --disable-doc \
    --enable-group=root \
    --enable-user=root \
    --enable-vtysh \
    --localstatedir=/var/run/quagga \
    --sysconfdir=/usr/local/etc/quagga \
    --with-cflags=-ggdb \
 && make \
 && make install \
 && cd \
 && rm -rf /opt/ospf-mdr

# install core
#---------------------------------------
RUN pip3 install dataclasses fabric grpcio==1.27.2 grpcio-tools==1.27.2 lxml mako netaddr netifaces Pillow poetry psutil pyproj pyyaml

RUN git clone -b release-7.2.1 https://github.com/coreemu/core.git /opt/core \
 && cd /opt/core \
 && ./bootstrap.sh \
 && ./configure --prefix=/usr/local \
 && make -j$(nproc) \
 && make install \
 && mkdir -p /etc/core \
 && cp -n /opt/core/daemon/data/core.conf /etc/core \
 && cp -n /opt/core/daemon/data/logging.conf /etc/core \
 && cp /opt/core/daemon/scripts/core-cleanup /usr/local/bin/core-cleanup \
 && cp /opt/core/daemon/scripts/core-cli /usr/local/bin/core-cli \
 && cp /opt/core/daemon/scripts/core-daemon /usr/local/bin/core-daemon \
 && cp /opt/core/daemon/scripts/core-imn-to-xml /usr/local/bin/core-imn-to-xml \
 && cp /opt/core/daemon/scripts/core-manage /usr/local/bin/core-manage \
 && cp /opt/core/daemon/scripts/core-pygui /usr/local/bin/core-pygui \
 && cp /opt/core/daemon/scripts/core-route-monitor /usr/local/bin/core-route-monitor \
 && cp /opt/core/daemon/scripts/core-service-update /usr/local/bin/core-service-update \
 && cp /opt/core/daemon/scripts/coresendmsg /usr/local/bin/coresendmsg \
 && cd /opt/core/daemon \
 && poetry build -f wheel \
 && pip3 install /opt/core/daemon/dist/* \
 && cd \
 && rm -rf /opt/core

ENV PYTHONPATH "${PYTHONPATH}:/usr/local/lib/python3.6/site-packages"

# configure core
#---------------------------------------
COPY icons /usr/share/core/icons/cisco

RUN apt-get update -y \
 && apt-get install -qq -y bash curl psmisc screen wget xvfb \
 && apt-get install -qq -y apache2 iptables isc-dhcp-client isc-dhcp-server mgen vsftpd \
 && apt-get install -qq -y iputils-ping moreutils net-tools scamper tcpdump traceroute tshark \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# install emanes
#---------------------------------------
#RUN wget -O /opt/emane.tgz https://adjacentlink.com/downloads/emane/emane-1.2.5-release-1.ubuntu-18_04.amd64.tar.gz \
# && cd /opt \
# && tar xzf /opt/emane.tgz \
# && cd /opt/emane-1.2.5-release-1/debs/ubuntu-18_04/amd64 \
# && dpkg -i *.deb \
# && apt-get install -f \
# && cd /root \
# && rm -rf /opt/emane.tgz /opt/emane-1.2.5-release-1

# install and configure ssh
#---------------------------------------
RUN apt-get update -y \
 && apt-get install -qq -y openssh-server \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

RUN mkdir /var/run/sshd \
 && mkdir /root/.ssh \
 && chmod 700 /root/.ssh \
 && chown root:root /root/.ssh \
 && touch /root/.ssh/authorized_keys \
 && chmod 600 /root/.ssh/authorized_keys \
 && chown root:root /root/.ssh/authorized_keys \
 && echo "\nX11UseLocalhost no\n" >> /etc/ssh/sshd_config

# install and configure supervisord
#---------------------------------------
RUN apt-get update -y \
 && apt-get install -qq -y supervisor \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

COPY supervisord.conf /etc/supervisor/conf.d/core.conf

# startup configuration
#---------------------------------------
EXPOSE 22
EXPOSE 50051

WORKDIR /root
CMD ["/usr/bin/supervisord", "--nodaemon"]
