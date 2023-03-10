#!/bin/bash

./configure \
  $( [[ `arch` == "aarch64" ]] && echo "--arch=armel" ) \
  --target-os=linux \
  --prefix=/usr/local \
  --extra-cflags="-I/usr/local/include -I/opt/vc/include -I/opt/vc/include/IL" \
  --extra-ldflags="-I/usr/local/lib -I/opt/vc/lib" \
  --extra-libs="-lpthread -lm -latomic" \
  --disable-debug \
  --disable-doc \
  --enable-gmp \
  --enable-gpl \
  --enable-hardcoded-tables \
  --enable-libaom \
  --enable-libass \
  --enable-libdav1d \
  --enable-libdrm \
  --enable-libfdk-aac \
  --enable-libfontconfig \
  --enable-libfreetype \
  --enable-libkvazaar \
  --enable-libmp3lame \
  --enable-libopencore-amrnb \
  --enable-libopencore-amrwb \
  --enable-libopenjpeg \
  --enable-libopus \
  --disable-librtmp \
  --enable-libsnappy \
  --enable-libsoxr \
  --enable-libssh \
  --enable-libtheora \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libzimg \
  --enable-libwavpack \
  --enable-libwebp \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libxvid \
  --enable-libxml2 \
  $( [[ `arch` == "aarch64" ]] && echo "--enable-mmal" ) \
  $( [[ `arch` == "aarch64" ]] && echo "--enable-omx" ) \
  $( [[ `arch` == "aarch64" ]] && echo "--enable-omx-rpi" ) \
  --enable-nonfree \
  --enable-openssl \
  --enable-pthreads \
  --enable-static \
  --disable-shared \
  --enable-version3
