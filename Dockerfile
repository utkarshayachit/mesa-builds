FROM debian:7
MAINTAINER Utkarsh Ayachit <utkarsh.ayachit@kitware.com>
RUN apt-get update && \
      apt-get install -y \
        wget \
        build-essential \
        pkg-config \
        libx11-dev \
        libxext-dev \
        libxdamage-dev \
        x11proto-gl-dev \
        git \
        scons
# x11proto-gl-dev version is 1.4.11 instead of 1.4.13. Let's see.

#----------------------------------------------------------------------------------------------
WORKDIR /opt/tools/src
RUN wget http://mirrors.concertpass.com/gcc/releases/gcc-4.8.5/gcc-4.8.5.tar.gz
RUN tar zxf gcc-4.8.5.tar.gz

# Lets build gcc
WORKDIR /opt/tools/src/gcc-4.8.5
RUN ./contrib/download_prerequisites

WORKDIR  /opt/tools/src/gcc-4.8.5-objdir
RUN /opt/tools/src/gcc-4.8.5-objdir/../gcc-4.8.5/configure --prefix=/opt/tools --enable-languages=c,c++ --with-multilib-list=m64
RUN make -j 24 && make install
ENV PATH /opt/tools/bin:$PATH
ENV CC /opt/tools/bin/gcc
ENV CXX /opt/tools/bin/g++
ENV LD_LIBRARY_PATH /opt/tools/lib64:/opt/tools/lib

#----------------------------------------------------------------------------------------------
WORKDIR /opt/tools/src
RUN wget  --no-check-certificate https://www.python.org/ftp/python/2.7.10/Python-2.7.10.tar.xz
RUN tar Jxf Python-2.7.10.tar.xz

#WORKDIR /opt/tools/src/Python-2.7.10
#RUN ./configure --prefix=/opt/tools --enable-unicode --enable-shared
#RUN make -j 24 && make install
RUN apt-get install -y python

#----------------------------------------------------------------------------------------------
WORKDIR /opt/tools/src
RUN wget --no-check-certificate https://cmake.org/files/v3.3/cmake-3.3.2-Linux-x86_64.tar.gz

WORKDIR /opt/tools
RUN tar zxf src/cmake-3.3.2-Linux-x86_64.tar.gz
#ENV PATH /opt/tools/cmake-3.3.2-Linux-x86_64:$PATH

#----------------------------------------------------------------------------------------------
WORKDIR /opt/tools/src
RUN wget http://llvm.org/releases/3.6.2/llvm-3.6.2.src.tar.xz
RUN tar Jxf llvm-3.6.2.src.tar.xz

WORKDIR /opt/tools/llvm-3.6.2.build
RUN /opt/tools/cmake-3.3.2-Linux-x86_64/bin/cmake \
        -DCMAKE_INSTALL_PREFIX:PATH=/opt/tools\
        -DCMAKE_BUILD_TYPE:STRING=Release \
        -DLLVM_ENABLE_RTTI:BOOL=ON /opt/tools/src/llvm-3.6.2.src/
RUN make -j 25 && make install

#----------------------------------------------------------------------------------------------
RUN apt-get install -y python-mako flex bison libnuma-dev
WORKDIR /opt/tools/src
RUN wget ftp://ftp.freedesktop.org/pub/mesa/11.0.4/mesa-11.0.4.tar.xz
RUN tar Jxf mesa-11.0.4.tar.xz

WORKDIR /opt/tools/src/mesa-11.0.4
RUN scons build=release texture_float=yes libgl-xlib

WORKDIR /opt/tools/mesa-llvm
RUN cp /opt/tools/src/mesa-11.0.4/build/linux-x86_64/gallium/targets/libgl-xlib/libGL.so.1.5 . && \
    ln -s libGL.so.1 libGL.so && \
    ln -s libGL.so.1.5 libGL.so.1
#----------------------------------------------------------------------------------------------
WORKDIR /opt/tools/src/openswr-mesa
RUN git clone https://github.com/OpenSWR/openswr-mesa.git src-avx2 --depth 1 -b 11.0-openswr
WORKDIR /opt/tools/src/openswr-mesa/src-avx2
RUN scons build=release texture_float=yes swr_arch=core-avx2 libgl-xlib

WORKDIR /opt/tools/mesa-swr-avx2
RUN cp /opt/tools/src/openswr-mesa/src-avx2/build/linux-x86_64/gallium/targets/libgl-xlib/libGL.so.1.5 . && \
    ln -s libGL.so.1 libGL.so && \
    ln -s libGL.so.1.5 libGL.so.1

#----------------------------------------------------------------------------------------------
WORKDIR /opt/tools/src/openswr-mesa
RUN git clone https://github.com/OpenSWR/openswr-mesa.git src-avx --depth 1 -b 11.0-openswr

WORKDIR /opt/tools/src/openswr-mesa/src-avx
RUN scons build=release texture_float=yes swr_arch=avx libgl-xlib

WORKDIR /opt/tools/mesa-swr-avx
RUN cp /opt/tools/src/openswr-mesa/src-avx/build/linux-x86_64/gallium/targets/libgl-xlib/libGL.so.1.5 . && \
    ln -s libGL.so.1 libGL.so && \
    ln -s libGL.so.1.5 libGL.so.1

#----------------------------------------------------------------------------------------------
WORKDIR /opt/tools/src/os-mesa
RUN wget ftp://ftp.freedesktop.org/pub/mesa/11.0.4/mesa-11.0.4.tar.xz
RUN tar Jxf mesa-11.0.4.tar.xz

WORKDIR /opt/tools/src/os-mesa/mesa-11.0.4
RUN ./configure \
      --disable-xvmc \
      --disable-glx \
      --disable-dri \
      --with-dri-drivers= \
      --with-gallium-drivers=swrast \
      --enable-texture-float \
      --disable-egl \
      --with-egl-platforms= \
      --enable-gallium-osmesa \
      --enable-gallium-llvm=yes \
      --disable-llvm-shared-libs \
      --with-llvm-prefix=/opt/tools \
      --prefix=/opt/tools/osmesa
RUN make -j 25
RUN make install
#----------------------------------------------------------------------------------------------

WORKDIR /opt/tools
RUN tar zcvf mesa-llvm.tar.gz mesa-llvm
RUN tar zcvf mesa-swr-avx2.tar.gz mesa-swr-avx2
RUN tar zcvf mesa-swr-avx.tar.gz mesa-swr-avx
RUN tar zcvf osmesa.tar.gz osmesa
CMD bash
