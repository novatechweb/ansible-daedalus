FROM alpine:3.7 AS devpi-build

ARG DEVPI_VERSION=4.6.0

WORKDIR /wheels

RUN apk add --no-cache \
    alpine-sdk \
    curl \
    libffi-dev \
    python-dev \
    py-pip \
&&  pip install --upgrade pip setuptools wheel \
&&  pip install devpi_server==${DEVPI_VERSION} \
&&  pip list --format freeze | grep -v '^devpi-server=' > wheels.txt \
&&  pip wheel -r wheels.txt


FROM alpine:3.7

ARG DEVPI_VERSION=4.6.0

COPY --from=devpi-build /wheels /wheels
RUN apk add --no-cache \
    dumb-init \
    python \
    py-pip \
&&  pip install --upgrade pip setuptools \
&&  pip install /wheels/*.whl \
&&  pip install devpi-server==${DEVPI_VERSION} \
&&  rm -r /root/.cache /wheels

WORKDIR /devpi
VOLUME /devpi

ENV HOST=0.0.0.0
ARG PORT=80
ENV PORT=${PORT}
EXPOSE ${PORT}

ENTRYPOINT ["dumb-init"]

CMD /usr/bin/devpi-server \
    --serverdir /devpi \
    --init; \
    /usr/bin/devpi-server \
    --serverdir /devpi \
    --restrict-modify ''\
    --host ${HOST} \
    --port ${PORT}
