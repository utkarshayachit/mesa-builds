FROM debian:7
MAINTAINER Utkarsh Ayachit <utkarsh.ayachit@kitware.com>
RUN apt-get update && \
      apt-get install -y \
        build-essential \
        pkg-config \
        libx11-dev libxext-dev libxdamage-dev x11proto-gl-dev \
        libx11-xcb-dev \
        libdrm-dev \
        libudev-dev \
        bison flex \
        gcc-4.7 \
        python \
        python-mako \
        git \
        wget \
        scons

ENV CC gcc-4.7
ENV CXX g++-4.7

#-------------------------------------------------------------------------------

WORKDIR /opt/tools/src
RUN wget https://cmake.org/files/v3.4/cmake-3.4.1-Linux-x86_64.tar.gz
RUN tar xf cmake-3.4.1-Linux-x86_64.tar.gz

#-------------------------------------------------------------------------------
WORKDIR /opt/tools/src
RUN wget http://llvm.org/releases/3.7.0/llvm-3.7.0.src.tar.xz
RUN tar xf llvm-3.7.0.src.tar.xz
WORKDIR /opt/tools/llvm-3.7.0.build
RUN /opt/tools/src/cmake-3.4.1-Linux-x86_64/bin/cmake \
      -DCMAKE_BUILD_TYPE:STRING=Release \
      -DLLVM_ENABLE_RTTI:BOOL=ON \
      -DLLVM_TARGETS_TO_BUILD:STRING=X86 \
      /opt/tools/src/llvm-3.7.0.src/
RUN make -j 8
ENV PATH /opt/tools/llvm-3.7.0.build/bin:$PATH

#-------------------------------------------------------------------------------
WORKDIR /opt/tools/src
run wget ftp://ftp.freedesktop.org/pub/mesa/11.1.0/mesa-11.1.0.tar.xz
RUN tar xf mesa-11.1.0.tar.xz

WORKDIR /opt/tools/src/mesa-11.1.0
RUN scons build=release texture_float=yes libgl-xlib osmesa

WORKDIR /opt/tools/inst/mesa-llvm
RUN cp /opt/tools/src/mesa-11.1.0/build/linux-x86_64/gallium/targets/libgl-xlib/libGL.so.1.5 . && \
    ln -s libGL.so.1 libGL.so && \
    ln -s libGL.so.1.5 libGL.so.1
RUN cp /opt/tools/src/mesa-11.1.0/build/linux-x86_64/gallium/targets/osmesa/libosmesa.so ./libOSMesa.so.8.0.0 && \
    ln -s libOSMesa.so.8.0.0 libOSMesa.so.8  && \
    ln -s libOSMesa.so.8 libOSMesa.so

#-------------------------------------------------------------------------------
WORKDIR /opt/tools/src/
RUN git clone https://github.com/OpenSWR/openswr-mesa.git mesa-swr-avx -b 11.0-openswr
WORKDIR /opt/tools/src/mesa-swr-avx
RUN scons build=release texture_float=yes swr_arch=avx libgl-xlib osmesa

WORKDIR /opt/tools/inst/mesa-swr-avx
RUN cp /opt/tools/src/mesa-swr-avx/build/linux-x86_64/gallium/targets/libgl-xlib/libGL.so.1.5 . && \
    ln -s libGL.so.1.5 libGL.so.1 && \
    ln -s libGL.so.1 libGL.so
RUN cp /opt/tools/src/mesa-swr-avx/build/linux-x86_64/gallium/targets/osmesa/libosmesa.so ./libOSMesa.so.8.0.0 && \
    ln -s libOSMesa.so.8.0.0 libOSMesa.so.8  && \
    ln -s libOSMesa.so.8 libOSMesa.so

#-------------------------------------------------------------------------------
WORKDIR /opt/tools/src/
RUN git clone https://github.com/OpenSWR/openswr-mesa.git mesa-swr-avx2 -b 11.0-openswr
WORKDIR /opt/tools/src/mesa-swr-avx2
RUN scons build=release texture_float=yes swr_arch=core-avx2 libgl-xlib osmesa

WORKDIR /opt/tools/inst/mesa-swr-avx2
RUN cp /opt/tools/src/mesa-swr-avx2/build/linux-x86_64/gallium/targets/libgl-xlib/libGL.so.1.5 . && \
    ln -s libGL.so.1.5 libGL.so.1 && \
    ln -s libGL.so.1 libGL.so
RUN cp /opt/tools/src/mesa-swr-avx2/build/linux-x86_64/gallium/targets/osmesa/libosmesa.so ./libOSMesa.so.8.0.0 && \
    ln -s libOSMesa.so.8.0.0 libOSMesa.so.8  && \
    ln -s libOSMesa.so.8 libOSMesa.so

#-------------------------------------------------------------------------------

WORKDIR /opt/tools/inst
RUN tar zcvf mesa-llvm.tar.gz mesa-llvm
RUN tar zcvf mesa-swr-avx.tar.gz mesa-swr-avx
RUN tar zcvf mesa-swr-avx2.tar.gz mesa-swr-avx2
CMD bash
