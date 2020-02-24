FROM alpine:latest
ARG OPENTTD_VERSION="1.9.3"
ARG OPENGFX_VERSION="0.5.5"

RUN mkdir /tmp/build

RUN apk --no-cache add \
    unzip \
    g++ \
    make \
    patch \
    git \
    zlib-dev \
    lzo-dev \
    xz-dev \
    wget  

WORKDIR /tmp/build
RUN git clone https://github.com/OpenTTD/OpenTTD.git
WORKDIR /tmp/build/OpenTTD 
RUN git checkout $OPENTTD_VERSION
RUN ./configure \
    --enable-dedicated \
    --binary-dir=bin \
    --personal-dir=/

RUN make -j$(nproc) \
	&& make install

WORKDIR /usr/share/games/openttd/baseset
ADD https://binaries.openttd.org/extra/opengfx/$OPENGFX_VERSION/opengfx-$OPENGFX_VERSION-all.zip opengfx.zip
RUN unzip opengfx.zip \
    && tar -xf opengfx-$OPENGFX_VERSION.tar -C /usr/local/share/games/openttd/baseset/ \
    && rm -rf opengfx-$OPENGFX_VERSION.tar opengfx.zip

ADD entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh
 
EXPOSE 3979/tcp
EXPOSE 3979/udp
EXPOSE 3977/tcp

RUN apk --no-cache del \ 
	make \
	git \ 
	patch
RUN rm -r /tmp/build

RUN adduser -D -h /openttd -u 911 -s /bin/false openttd \
	&& chown openttd:openttd /openttd -R
USER openttd
WORKDIR /openttd
CMD /usr/local/bin/entrypoint.sh
	
	
