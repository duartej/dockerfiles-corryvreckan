FROM gitlab-registry.cern.ch/duarte/dockerfiles-eudaqv2/eudaq2:caen-raw-events
LABEL maintainer.name="Jordi Duarte-Campderros"
LABEL maintainer.email="duarte@ifca.unican.es"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

USER 0

# Place at the directory
WORKDIR /eudaq

# XXX -- Are all those packages needed?
# Install dependencies
RUN apt-get update && apt-get -y install \
   build-essential \
   libeigen3-dev \
   qtbase5-dev \ 
   git \ 
   cmake \ 
   libusb-dev \ 
   libusb-1.0 \ 
   pkgconf \ 
   vim \ 
   g++ \
   gcc \
   gfortran \
   binutils \
   libxpm4 \ 
   libxft2 \ 
   libtiff6 \ 
   libtbb-dev \ 
   sudo \ 
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# The c++ standard
ARG CMAKE_CXX_STANDARD=20
ARG CXXFLAGS="-std=c++20"

COPY CMakeLists.txt CMakeLists.txt

ENV ROOTSYS=/eudaq/root
# BE aware of the ROOT libraries
ENV LD_LIBRARY_PATH=/eudaq/root/lib
ENV PYTHONPATH=/eudaq/root/lib

# Add analyis user, allow to call sudo without password
# And give previously created folders ownership to the user
RUN mkdir -p /data \
  && chown -R eudaquser:eudaquser /data

# Change to user
USER eudaquser
ENV HOME="/home/eudaquser"
ENV PATH="${PATH}:${HOME}/.local/bin:/eudaq/corryvreckan/bin:/eudaq/eudaq/bin:/eudaq/root/bin:/eudaq/cactus/bin"
ENV PYTHONPATH="${HOME}/.local/lib:${PYTHONPATH}"
ENV EUDAQPATH="/eudaq/eudaq"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/eudaq/corryvreckan/lib:/eudaq/eudaq/lib:/eudaq/boost/lib:/eudaq/cactus/lib"

# The software 
RUN cd /eudaq \
    && git clone -b docker-prov --single-branch https://gitlab.cern.ch/duarte/corryvreckan.git \
    && cp CMakeLists.txt /eudaq/corryvreckan/ \
    && mkdir -p /eudaq/corryvreckan/build \
    && cd /eudaq/corryvreckan/build \ 
    && cmake -DBUILD_EventLoaderEUDAQ2=ON \
           -DROOT_DIR="/eudaq/root/cmake" \
           -DCMAKE_INSTALL_PREFIX=../ \
           -DCMAKE_MODULE_PATH="/usr/share/cmake/Modules/;/usr/share/cmake/Modules/" \
          .. \
    && make -j`grep -c processor /proc/cpuinfo` \
    && make install \
    && rm -rf /eudaq/corryvreckan/build

# Default command for starting the container, executed after the ENTRYPOINT
CMD ["bash"]

