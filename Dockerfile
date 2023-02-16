FROM debian:bullseye AS builder

## Initial deps

ENV INITSYSTEM on
ENV FFMPEG_SRC_URL="https://github.com/jjustman/ffmpeg-hls-pts-discontinuity-reclock/archive/f46551d510573b3a132dba0c52adf19101e2223a.tar.gz"
ENV DEBIAN_FRONTEND=noninteractive
ENV CPUCOUNT=4

RUN \
  apt-get update -q &&\
  apt-get install -qy --no-install-recommends apt-utils ca-certificates curl build-essential pkg-config git cmake sudo

## Raspberry Pi userspace libraries -- must be 32-bit!
WORKDIR "/usr/local"
COPY docker/raspi-build.sh .
RUN ./raspi-build.sh

## ffmpeg build

# add deb-multimedia repo
COPY docker/add-deb-multimedia.sh .
RUN ./add-deb-multimedia.sh

# ffmpeg build deps available through Debian
RUN apt-get install -qy --no-install-recommends \
  libaom-dev \
  libass-dev \
  libdav1d-dev \
  libdrm-dev \
  libfontconfig1-dev \
  libfreetype6-dev \
  libgmp-dev \
  libmp3lame-dev \
  libopencore-amrnb-dev \
  libopencore-amrwb-dev \
  libopenjp2-7-dev \
  libopus-dev \
  libomxil-bellagio-dev \
  librtmp-dev \
  libsnappy-dev \
  libsoxr-dev \
  libssh-dev \
  libssl-dev \
  libwebp-dev \
  libxml2-dev \
  libtheora-dev \
  libvorbis-dev \
  libvpx-dev \
  libwavpack-dev \
  libx264-dev \
  libx265-dev \
  libxvidcore-dev \
  nasm \
&& apt-get clean

# ffmpeg build deps available through deb-multimedia (unauthenticated)
RUN apt-get install -qy --no-install-recommends --allow-unauthenticated \
  libfdk-aac-dev \
  libkvazaar-dev \
  libzimg-dev \
&& apt-get clean

# prepare to build
WORKDIR /usr/local/src/ffmpeg

RUN curl -sD /dev/stderr -L ${FFMPEG_SRC_URL} | tar zx --strip-components=1

COPY docker/config-ffmpeg.sh .

RUN ./config-ffmpeg.sh
RUN make -j${CPUCOUNT}
RUN make install

# ensure that this dir exists, so Docker doesn't complain later
RUN mkdir -p /opt/vc/lib

## nginx build

ENV NGINX_SRC_URL="http://nginx.org/download/nginx-1.23.3.tar.gz"
ENV NGINX_SRC_DIR="/usr/local/src/nginx"
ENV RTMP_SRC_DIR="/usr/local/src/rtmp"

WORKDIR ${NGINX_SRC_DIR}
RUN curl -sD /dev/stderr -L ${NGINX_SRC_URL} | tar zx --strip-components=1
RUN git clone --depth 1 https://github.com/arut/nginx-rtmp-module.git ${RTMP_SRC_DIR}

# nginx build deps
RUN apt-get install -qy --no-install-recommends \
  libpcre3-dev \
  libssl-dev \
  zlib1g-dev \
&& apt-get clean

RUN ./configure \
  --prefix=/usr/local/nginx \
  --http-client-body-temp-path=/tmp/nginx-client-body \
  --with-threads \
  --with-ipv6 \
  --with-http_ssl_module \
  --add-module=${RTMP_SRC_DIR} \
&& make -j${CPUCOUNT} \
&& make install

## python deps build

RUN apt-get install -qy --no-install-recommends \
  libffi-dev \
  libmediainfo-dev \
  python3-cryptography \
  python3-dev \
  python3-pip \
  python3-setuptools \
  python3-setuptools-rust/bullseye-backports \
&& apt-get clean

RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir \
  bcrypt==4.0.1 \
  certifi==2022.12.7 \
  cffi==1.15.1 \
  charset-normalizer==3.0.1 \
  fabric==3.0.0 \
  idna==3.4 \
  invoke==2.0.0 \
  paramiko==3.0.0 \
  Pebble==5.0.3 \
  psutil==5.9.4 \
  pycparser==2.21 \
  pymediainfo==6.0.1 \
  PyNaCl==1.5.0 \
  requests==2.28.2 \
  urllib3==1.26.14

# --- install
FROM debian:bullseye AS app

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt-get update -q &&\
  apt-get install -qy --no-install-recommends \
    apt-utils \
    ca-certificates \
    curl \
    build-essential \
&& apt-get clean

# add deb-multimedia repo
WORKDIR /usr/local
COPY docker/add-deb-multimedia.sh .
RUN ./add-deb-multimedia.sh

# ffmpeg deps
RUN apt-get install -qy --no-install-recommends \
  libdrm2 \
  libaom0 \
  libass9 \
  libdav1d4 \
  libfontconfig \
  libmp3lame0 \
  libopencore-amrwb0 \
  libopencore-amrnb0 \
  libopenjp2-7 \
  libopus0 \
  libsnappy1v5 \
  libssh-4 \
  libsoxr0 \
  libtheora0 \
  libx264-160 \
  libx265-192 \
  libvorbis0a \
  libvorbisenc2 \
  libvpx6 \
  libwavpack1 \
  libwebpmux3 \
  libxml2 \
  libxvidcore4 \
&& apt-get clean

# binary libs (from deb-multimedia)
RUN apt-get install -qy --no-install-recommends --allow-unauthenticated \
  libfdk-aac2 \
  libkvazaar6 \
  libzimg2 \
&& apt-get clean

# copy the builds from builder
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/share /usr/local/share
COPY --from=builder /usr/local/nginx /usr/local/nginx
COPY --from=builder /opt/vc/lib /opt/vc/lib
RUN echo "/opt/vc/lib" > /etc/ld.so.conf.d/00-vmcs.conf && ldconfig

# test ffmpeg (fail the build if libs don't all load)
RUN /usr/local/bin/ffmpeg -version

# nginx deps
RUN apt-get install -qy --no-install-recommends \
  libpcre3 \
  libssl1.1 \
  zlib1g \
&& apt-get clean

COPY docker/nginx.conf /usr/local/nginx/conf/nginx.conf
# test nginx (fail the build if config doesn't load)
RUN /usr/local/nginx/sbin/nginx -t

# python deps for Mr. OTCS
RUN apt-get install -qy --no-install-recommends \
  libmediainfo0v5 \
  python3 \
  python3-cryptography \
&& apt-get clean

COPY docker/otcs-start.sh /
# copy OTCS app
COPY mr-otcs /app

ENTRYPOINT ["/otcs-start.sh"]
