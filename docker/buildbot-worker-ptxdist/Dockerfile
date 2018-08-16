FROM        krallin/ubuntu-tini:trusty

ENV PTXDIST_VERSION 2012.09.1

WORKDIR /buildbot

RUN apt-get update \
&&  DEBIAN_FRONTEND=noninteractive \
    apt-get -y install -q wget \
&&  wget -qO /etc/apt/trusted.gpg.d/ptx-archive-key.gpg https://debian.pengutronix.de/debian/ptx-archive-key.gpg \
&&  wget -qO /etc/apt/sources.list.d/pengutronix.list   https://debian.pengutronix.de/debian/pengutronix.list \
&&  apt-get update \
&&  DEBIAN_FRONTEND=noninteractive \
    apt-get -y install -q \
        oselas.toolchain-2011.11.3-armeb-xscale-linux-gnueabi-gcc-4.6.2-glibc-2.14.1-binutils-2.21.1a-kernel-2.6.39-sanitized \
        oselas.toolchain-2012.12.1-arm-cortexa8-linux-gnueabi-gcc-4.7.3-glibc-2.16.0-binutils-2.22-kernel-3.6-sanitized \
        oselas.toolchain-2012.12.1-i686-atom-linux-gnu-gcc-4.7.2-glibc-2.16.0-binutils-2.22-kernel-3.6-sanitized \
&&  rm -rf /var/lib/apt/lists/*

# Install security updates and required packages
RUN apt-get update \
&&  DEBIAN_FRONTEND=noninteractive \
    apt-get -y install -q \
        autoconf \
        bison \
        build-essential \
        ccache \
        comerr-dev \
        default-jre-headless \
        docbook-xml \
        docbook-xsl \
        groff-base \
        libgdk-pixbuf2.0-dev \
        libgtk2.0-bin \
        libicu-dev \
        libncurses5 \
        libncurses5-dev \
        libswitch-perl \
        libxml-simple-perl \
        libxml2-utils \
        lzop \
        flex \
        gawk \
        gcc \
        gconf2 \
        gettext \
        git \
        libtool \
        make \
        python-dev \
        python-libxml2 \
        python-tdb \
        ruby \
        subversion \
        ss-dev \
        texinfo \
        unzip \
        wget \
        xsltproc \
        yasm \
&&  rm -rf /var/lib/apt/lists/*

ARG BUILDBOT_VERSION
# Install required python packages, and twisted
RUN wget https://bootstrap.pypa.io/get-pip.py \
&&  python get-pip.py --no-cache-dir \
&&  pip --no-cache-dir install \
        'virtualenv' \
        'twisted[tls]' \
        buildbot-worker${BUILDBOT_VERSION:+==${BUILDBOT_VERSION}} \
&&  rm -rf get-pip.py

ARG BUILDBOT_UID=1000
COPY buildbot/ /home/buildbot/
RUN useradd --comment "Buildbot Server" --home-dir "/home/buildbot" --shell "/bin/bash" --uid ${BUILDBOT_UID} --user-group buildbot \
&&  chown -v -R buildbot:buildbot "/buildbot" \
&&  chown -v -R buildbot:buildbot "/home/buildbot" \
&&  useradd --comment "Gnome Display Manager" --home-dir "/var/lib/gdm" --shell "/sbin/nologin" --user-group --system gdm

# Install ptxdist, a build system
COPY src /usr/src/ptxdist-${PTXDIST_VERSION}
RUN cd /usr/src/ptxdist-${PTXDIST_VERSION} \
&&  touch ptxdist \
&&  echo "${PTXDIST_VERSION}" > .tarball-version \
&&  ./autogen.sh \
&&  ./configure \
&&  make \
&&  make install \
&&  make distclean

USER buildbot

CMD ["/home/buildbot/start.sh"]
