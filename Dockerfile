#build
FROM alpine:latest AS build
ARG OPENTTD_VERSION="1.11.1"
ARG OPENGFX_VERSION="0.6.1"

RUN mkdir /tmp/build

RUN apk --no-cache add \
    unzip \
    g++ \
    cmake \
    make \
    git \
    libpng-dev \
    xz-dev \
    wget  

WORKDIR /tmp/build
RUN git clone -b $OPENTTD_VERSION --depth 1 https://github.com/OpenTTD/OpenTTD.git
WORKDIR /tmp/build/OpenTTD 
RUN mkdir build \
    && cd build \
    && cmake -DOPTION_DEDICATED=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo -DOPTION_USE_ASSERTS=OFF .. \
    && make -j$(nproc) \ 
    && make install  

WORKDIR /usr/local/share/games/openttd/baseset
ADD https://cdn.openttd.org/opengfx-releases/$OPENGFX_VERSION/opengfx-$OPENGFX_VERSION-all.zip opengfx.zip
RUN unzip opengfx.zip \
    && tar -xf opengfx-$OPENGFX_VERSION.tar -C /usr/local/share/games/openttd/baseset \
    && rm -rf opengfx-$OPENGFX_VERSION.tar opengfx.zip

#openttd
FROM alpine:latest AS openttd
COPY --from=build /usr/local/games/openttd /usr/local/games/openttd
COPY --from=build /usr/local/share/games/openttd /usr/local/share/games/openttd
RUN apk --no-cache add \
    libstdc++ \
    libpng-dev \
    xz-dev 

WORKDIR /openttd

ADD entrypoint.sh .

RUN adduser -D -h /openttd openttd \
    && chown openttd -R /openttd \
    && chown openttd -R /usr/local/share/games/openttd \
    && chmod +x entrypoint.sh \
    && chmod +x /usr/local/games/openttd
 
EXPOSE 3979/tcp
EXPOSE 3979/udp
EXPOSE 3977/tcp

USER openttd

CMD ./entrypoint.sh
