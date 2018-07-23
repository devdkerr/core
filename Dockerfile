FROM ubuntu:xenial
LABEL maintainer="Daniel R. Kerr <daniel.r.kerr@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm

# install core dependencies
#---------------------------------------
RUN apt-get update -y \
 && apt-get install -qq -y libev4 \
 && apt-get install -qq -y python python-enum34 \
 && apt-get install -qq -y bridge-utils ebtables iproute2 quagga \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

RUN apt-get update -y \
 && apt-get install -qq -y libtk-img \
 && apt-get install -qq -y tcl tk \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# install core
#---------------------------------------
COPY apt/python-core_systemd_5.1_all.deb /tmp/python-core_systemd_5.1_all.deb
COPY apt/core-gui_5.1_amd64.deb /tmp/core-gui_5.1_amd64.deb
RUN dpkg -i /tmp/python-core_systemd_5.1_all.deb \
 && dpkg -i /tmp/core-gui_5.1_amd64.deb \
 && rm /tmp/python-core_systemd_5.1_all.deb \
 && rm /tmp/core-gui_5.1_amd64.deb

# configure core
#---------------------------------------
COPY icons /usr/local/share/core/icons/cisco

RUN apt-get update -y \
 && apt-get install -qq -y bash curl screen wget xvfb \
 && apt-get install -qq -y apache2 iptables isc-dhcp-server mgen vsftpd \
 && apt-get install -qq -y iputils-ping net-tools scamper tcpdump traceroute \
 && apt-get clean \
 && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# install emanes
#---------------------------------------
# TODO

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

WORKDIR /root
CMD ["/usr/bin/supervisord", "--nodaemon"]
