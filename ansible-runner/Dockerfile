FROM ubuntu:latest

RUN apt-get update \
&&  DEBIAN_FRONTEND=noninteractive apt-get install \
    -y \
    curl \
    git \
    openssh-client \
    python \
    python-svn \
    rsync \
    sshpass \
    subversion \
    vim
    
# Install pip
RUN curl -O https://bootstrap.pypa.io/get-pip.py \
&&  python get-pip.py --no-cache-dir

RUN pip --no-cache-dir install \
    'ansible'

ARG UID=1000
ARG GID=1000

RUN groupadd \
    --gid ${GID} \
    --system \
    ansible \
&&  useradd \
    --comment "Ansible User" \
    --create-home \
    --gid ${GID} \
    --uid ${UID} \
    --system \
    ansible

WORKDIR /ansible
VOLUME /ansible
USER ansible
