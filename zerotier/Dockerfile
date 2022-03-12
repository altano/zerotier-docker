# syntax=docker/dockerfile:1

FROM debian:buster as stage

ARG PACKAGE_BASEURL=https://download.zerotier.com/debian/buster/pool/main/z/zerotier-one/
ARG ARCH=amd64
ARG VERSION

# Make sure VERSION is set
RUN test -n "$VERSION"

LABEL build_version="Alan: version:${VERSION} arch:${ARCH} package_baseurl=${PACKAGE_BASEURL}"
LABEL org.opencontainers.image.authors="Alan Norbauer <altano@gmail.com>"
LABEL org.opencontainers.image.version="${VERSION}"

RUN apt-get update -qq && apt-get install curl -y
RUN curl -sSL -o zerotier-one.deb "${PACKAGE_BASEURL}/zerotier-one_${VERSION}_${ARCH}.deb"

FROM debian:buster

COPY --from=stage zerotier-one.deb .

RUN apt-get update -qq && apt-get install -y openssl jq \
    && rm -rf /var/lib/apt/lists/*
RUN dpkg -i zerotier-one.deb && rm -f zerotier-one.deb
RUN echo "${VERSION}" >/etc/zerotier-version
RUN rm -rf /var/lib/zerotier-one

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

COPY healthcheck.sh /healthcheck.sh
RUN chmod 755 /healthcheck.sh

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=1 CMD [ "./healthcheck.sh" ]

CMD []
ENTRYPOINT ["/entrypoint.sh"]
