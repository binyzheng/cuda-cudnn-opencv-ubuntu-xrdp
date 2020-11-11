FROM ubuntu:18.04 as builder
MAINTAINER Daniel Guerra

# Install packages

ENV DEBIAN_FRONTEND noninteractive
RUN sed -i "s/# deb-src/deb-src/g" /etc/apt/sources.list
RUN apt-get -y update
RUN apt-get -yy upgrade
ENV BUILD_DEPS="git autoconf pkg-config libssl-dev libpam0g-dev \
    libx11-dev libxfixes-dev libxrandr-dev nasm xsltproc flex \
    bison libxml2-dev dpkg-dev libcap-dev"
RUN apt-get -yy install  sudo apt-utils software-properties-common $BUILD_DEPS


# Build xrdp

WORKDIR /tmp
RUN apt-get source pulseaudio
RUN apt-get build-dep -yy pulseaudio
WORKDIR /tmp/pulseaudio-11.1
RUN dpkg-buildpackage -rfakeroot -uc -b
WORKDIR /tmp
RUN git clone --branch v0.9.7 --recursive https://github.com/neutrinolabs/xrdp.git
WORKDIR /tmp/xrdp
RUN ./bootstrap
RUN ./configure
RUN make
RUN make install
WORKDIR /tmp/xrdp/sesman/chansrv/pulse
RUN sed -i "s/\/tmp\/pulseaudio\-10\.0/\/tmp\/pulseaudio\-11\.1/g" Makefile
RUN make
RUN mkdir -p /tmp/so
RUN cp *.so /tmp/so

FROM nvidia/cuda:10.2-cudnn8-devel-ubuntu18.04
ARG OPENCV_VERSION=4.5.0

RUN apt-get update && apt-get upgrade -y &&\
    # Install build tools, build dependencies and python
    apt-get install -y \
	    python-pip \
        build-essential \
        cmake \
        git \
        wget \
        unzip \
        yasm \
        pkg-config \
        libswscale-dev \
        libtbb2 \
        libtbb-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libavformat-dev \
        libpq-dev \
        libxine2-dev \
        libglew-dev \
        libtiff5-dev \
        zlib1g-dev \
        libjpeg-dev \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libpostproc-dev \
        libswscale-dev \
        libeigen3-dev \
        libtbb-dev \
        libgtk2.0-dev \
        pkg-config \
        ## Python
        python-dev \
        python-numpy \
        python3-dev \
        python3-numpy \
    && rm -rf /var/lib/apt/lists/*

RUN cd /opt/ &&\
    # Download and unzip OpenCV and opencv_contrib and delte zip files
    wget https://github.com/opencv/opencv/archive/$OPENCV_VERSION.zip &&\
    unzip $OPENCV_VERSION.zip &&\
    rm $OPENCV_VERSION.zip &&\
    wget https://github.com/opencv/opencv_contrib/archive/$OPENCV_VERSION.zip &&\
    unzip ${OPENCV_VERSION}.zip &&\
    rm ${OPENCV_VERSION}.zip &&\
    # Create build folder and switch to it
    mkdir /opt/opencv-${OPENCV_VERSION}/build && cd /opt/opencv-${OPENCV_VERSION}/build &&\
    # Cmake configure
    cmake \
        -DOPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib-${OPENCV_VERSION}/modules \
        -DWITH_CUDA=ON \
        -DCMAKE_BUILD_TYPE=RELEASE \
        # Install path will be /usr/local/lib (lib is implicit)
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        .. &&\
    # Make
    make -j"$(nproc)" && \
    # Install to /usr/local/lib
    make install && \
    ldconfig &&\
    # Remove OpenCV sources and build folder
rm -rf /opt/opencv-${OPENCV_VERSION} && rm -rf /opt/opencv_contrib-${OPENCV_VERSION}

ARG ADDITIONAL_PACKAGES=""
ENV ADDITIONAL_PACKAGES=${ADDITIONAL_PACKAGES}
ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install -y \
  ca-certificates \
  crudini \
  firefox \
  less \
  locales \
  openssh-server \
  pepperflashplugin-nonfree \
  pulseaudio \
  sudo \
  supervisor \
  uuid-runtime \
  vim \
  wget \
  xauth \
  xautolock \
  xfce4 \
  xfce4-clipman-plugin \
  xfce4-cpugraph-plugin \
  xfce4-netload-plugin \
  xfce4-screenshooter \
  xfce4-taskmanager \
  xfce4-terminal \
  xfce4-xkb-plugin \
  xorgxrdp \
  xprintidle \
  xrdp \
  $ADDITIONAL_PACKAGES \
  && \
  rm -rf /var/cache/apt /var/lib/apt/lists && \
  mkdir -p /var/lib/xrdp-pulseaudio-installer
COPY --from=builder /tmp/so/module-xrdp-source.so /var/lib/xrdp-pulseaudio-installer
COPY --from=builder /tmp/so/module-xrdp-sink.so /var/lib/xrdp-pulseaudio-installer
ADD bin /usr/bin
ADD etc /etc
ADD autostart /etc/xdg/autostart
#ADD pulse /usr/lib/pulse-10.0/modules/

# Configure
RUN mkdir /var/run/dbus && \
  cp /etc/X11/xrdp/xorg.conf /etc/X11 && \
  sed -i "s/console/anybody/g" /etc/X11/Xwrapper.config && \
  sed -i "s/xrdp\/xorg/xorg/g" /etc/xrdp/sesman.ini && \
  locale-gen en_US.UTF-8 && \
  echo "xfce4-session" > /etc/skel/.Xclients && \
  cp -r /etc/ssh /ssh_orig && \
  rm -rf /etc/ssh/* && \
  rm -rf /etc/xrdp/rsakeys.ini /etc/xrdp/*.pem

# Docker config
VOLUME ["/etc/ssh","/home"]
EXPOSE 3389 22 9001
ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]
CMD ["supervisord"]
