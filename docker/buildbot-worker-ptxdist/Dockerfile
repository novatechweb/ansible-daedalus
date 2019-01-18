#
# Build the main image
#
FROM        krallin/ubuntu-tini:trusty
WORKDIR /buildbot


#
# Install security updates and required packages
#
RUN apt-get update \
&&  DEBIAN_FRONTEND=noninteractive \
    apt-get -y install -q \
        autoconf \
        bc \
        bison \
        build-essential \
        comerr-dev \
        curl \
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


#
# Install required python packages, and twisted
#
ARG BUILDBOT_VERSION
RUN wget https://bootstrap.pypa.io/get-pip.py \
&&  python get-pip.py --no-cache-dir \
&&  pip --no-cache-dir install \
        'virtualenv' \
        'twisted[tls]' \
        buildbot-worker${BUILDBOT_VERSION:+==${BUILDBOT_VERSION}} \
&&  rm -rf get-pip.py


#
# Create buildbot user
#
ARG BUILDBOT_UID=1000
COPY buildbot/ /home/buildbot/
RUN useradd --comment "Buildbot Server" --home-dir "/home/buildbot" --shell "/bin/bash" --uid ${BUILDBOT_UID} --user-group buildbot \
&&  mkdir -p --mode=0700 "/home/buildbot/.ssh" \
&&  chown -v -R buildbot:buildbot "/buildbot" \
&&  chown -v -R buildbot:buildbot "/home/buildbot" \
&&  useradd --comment "Gnome Display Manager" --home-dir "/var/lib/gdm" --shell "/sbin/nologin" --user-group --system gdm \
&&  mkdir --mode=0777 -p /opt \
&&  chown -R buildbot:buildbot /opt


#
# Build PTXdist release 2011.11.0
#
COPY ptxdist /tmp
RUN PTXDIST_REPO=https://git.novatech-llc.com/Orion-ptxdist/ptxdist.git \
&&  PTXDIST_BRANCH=stable/ptxdist-2011.11.x \
&&  PTXDIST_VERSION=2011.11.0 \
&&  git clone --branch ${PTXDIST_BRANCH} ${PTXDIST_REPO} ptxdist-${PTXDIST_VERSION} \
&&  cd ptxdist-${PTXDIST_VERSION} \
&&  git config user.name "Buildbot" \
&&  git config user.email "buildbot@novatech-llc.com" \
&&  git am /tmp/ptxdist-${PTXDIST_VERSION}/*.patch \
&&  git tag -f -a -m"Tag updated version of ${PTXDIST_VERSION}" "ptxdist-${PTXDIST_VERSION}" \
&&  ./autogen.sh \
&&  ./configure \
&&  make \
&&  make install \
&&  cd .. && rm -r ptxdist-${PTXDIST_VERSION}


#
# Build PTXdist release 2012.12.1
#
RUN PTXDIST_REPO=https://git.novatech-llc.com/Orion-ptxdist/ptxdist.git \
&&  PTXDIST_BRANCH=stable/ptxdist-2012.12.x \
&&  PTXDIST_VERSION=2012.12.1 \
&&  git clone --branch ${PTXDIST_BRANCH} ${PTXDIST_REPO} ptxdist-${PTXDIST_VERSION} \
&&  cd ptxdist-${PTXDIST_VERSION} \
&&  ./autogen.sh \
&&  ./configure \
&&  make \
&&  make install \
&&  cd .. && rm -r ptxdist-${PTXDIST_VERSION}


#
# Build PTXdist release 2012.09.1
#
RUN PTXDIST_REPO=https://git.novatech-llc.com/Orion-ptxdist/ptxdist.git \
&&  PTXDIST_BRANCH=master \
&&  PTXDIST_VERSION=2012.09.1 \
&&  git clone --branch ${PTXDIST_BRANCH} ${PTXDIST_REPO} ptxdist-${PTXDIST_VERSION} \
&&  cd ptxdist-${PTXDIST_VERSION} \
&&  git config user.name "Buildbot" \
&&  git config user.email "buildbot@novatech-llc.com" \
&&  touch ptxdist \
&&  echo "${PTXDIST_VERSION}" > .tarball-version \
&&  git tag -f -a -m"Tag custom ${PTXDIST_VERSION} build" "ptxdist-${PTXDIST_VERSION}" \
&&  ./autogen.sh \
&&  ./configure \
&&  make \
&&  make install \
&&  cd .. && rm -r ptxdist-${PTXDIST_VERSION}


#
# Switch to buildbot user
#   (ptxdist refuses to run as root)
#
USER buildbot


#
# Build OSELAS Toolchain 2011.11.3 for armeb-xscale
#
RUN PTXDIST=/usr/local/bin/ptxdist-2011.11.0 \
&&  TOOLCHAIN_REPO=https://git.novatech-llc.com/Orion-ptxdist/OSELAS.Toolchain \
&&  TOOLCHAIN_ARCH=armeb-xscale \
&&  TOOLCHAIN_BRANCH=OSELAS.Toolchain-2011.11.x \
&&  TOOLCHAIN_CONFIG=armeb-xscale-linux-gnueabi_gcc-4.6.4_glibc-2.14.1_binutils-2.21.1a_kernel-2.6.39-sanitized.ptxconfig \
&&  git clone --branch ${TOOLCHAIN_BRANCH} ${TOOLCHAIN_REPO} toolchain-${TOOLCHAIN_ARCH} \
&&  cd toolchain-${TOOLCHAIN_ARCH} \
&&  ${PTXDIST} select ptxconfigs/${TOOLCHAIN_CONFIG} \
&&  ${PTXDIST} go \
&&  cd .. && rm -r toolchain-${TOOLCHAIN_ARCH}


#
# Build OSELAS Toolchain 2012.12.1 for arm-cortexa8
#
RUN PTXDIST=/usr/local/bin/ptxdist-2012.12.1 \
&&  TOOLCHAIN_REPO=https://git.novatech-llc.com/Orion-ptxdist/OSELAS.Toolchain \
&&  TOOLCHAIN_ARCH=am335x \
&&  TOOLCHAIN_BRANCH=OSELAS.Toolchain-2012.12.x \
&&  TOOLCHAIN_CONFIG=arm-cortexa8-linux-gnueabi_gcc-4.7.3_glibc-2.16.0_binutils-2.22_kernel-3.6-sanitized.ptxconfig \
&&  git clone --branch ${TOOLCHAIN_BRANCH} ${TOOLCHAIN_REPO} toolchain-${TOOLCHAIN_ARCH} \
&&  cd toolchain-${TOOLCHAIN_ARCH} \
&&  ${PTXDIST} select ptxconfigs/${TOOLCHAIN_CONFIG} \
&&  ${PTXDIST} go \
&&  cd .. && rm -r toolchain-${TOOLCHAIN_ARCH}


#
# Build OSELAS Toolchain 2012.12.1 for i686
#
RUN PTXDIST=/usr/local/bin/ptxdist-2012.12.1 \
&&  TOOLCHAIN_REPO=https://git.novatech-llc.com/Orion-ptxdist/OSELAS.Toolchain \
&&  TOOLCHAIN_ARCH=i686 \
&&  TOOLCHAIN_BRANCH=OSELAS.Toolchain-2012.12.x \
&&  TOOLCHAIN_CONFIG=i686-atom-linux-gnu_gcc-4.7.4_glibc-2.16.0_binutils-2.22_kernel-3.6-sanitized.ptxconfig \
&&  git clone --branch ${TOOLCHAIN_BRANCH} ${TOOLCHAIN_REPO} toolchain-${TOOLCHAIN_ARCH} \
&&  cd toolchain-${TOOLCHAIN_ARCH} \
&&  ${PTXDIST} select ptxconfigs/${TOOLCHAIN_CONFIG} \
&&  ${PTXDIST} go \
&&  cd .. && rm -r toolchain-${TOOLCHAIN_ARCH}


#
# Final image settings
#
USER buildbot
CMD ["/home/buildbot/start.sh"]
