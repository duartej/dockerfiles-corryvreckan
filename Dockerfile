FROM phusion/baseimage:focal-1.2.0
LABEL author="jorge.duarte.campderros@cern.ch" \ 
    version="2.0" \ 
    description="Docker image to run the CORRYVRECKAN framework \
    with EUDAQ and with C++17 support"
MAINTAINER Jordi Duarte-Campderros jorge.duarte.campderros@cern.ch

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Place at the directory
WORKDIR /analysis

# XXX -- Are all those packages needed?
# Install dependencies
RUN apt-get update \ 
  && install_clean --no-install-recommends software-properties-common \ 
  && install_clean --no-install-recommends \ 
   build-essential \
   libeigen3-dev \
   libpugixml1v5 \
   qt5-default \
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
   libtiff5 \ 
   libtbb-dev \ 
   sudo \ 
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Extract eudaq and boost from eudaq image: PROV (ph2_acf)
COPY --from=gitlab-registry.cern.ch/duarte/dockerfiles-eudaqv2/eudaq2:master /eudaq/eudaq /analysis/eudaq
COPY --from=gitlab-registry.cern.ch/duarte/dockerfiles-eudaqv2/eudaq2:master /eudaq/boost /analysis/boost
COPY --from=gitlab-registry.cern.ch/duarte/dockerfiles-eudaqv2/eudaq2:master /opt/cactus /analysis/cactus
COPY --from=gitlab-registry.cern.ch/duarte/dockerfiles-eudaqv2/eudaq2:master /rootfr/root /rootfr/root

ENV ROOTSYS /rootfr/root
# BE aware of the ROOT libraries
ENV LD_LIBRARY_PATH /rootfr/root/lib
ENV PYTHONPATH /rootfr/root/lib

# Add analyis user, allow to call sudo without password
# And give previously created folders ownership to the user
RUN useradd -md /home/analyser -ms /bin/bash -G sudo analyser \ 
  && echo "analyser:docker" | chpasswd \
  && echo "analyser ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers \
  # Create a soft link for eudaq compatibilty
  && ln -s /analysis /eudaq \
  # Recovering permissions
  && mkdir -p /data \
  && chown -R analyser:analyser /data \
  && chown -R analyser:analyser /analysis

# Change to user
USER analyser
ENV HOME="/home/analyser"
ENV PATH="${PATH}:${HOME}/.local/bin:/analysis/corryvreckan/bin:/analysis/eudaq/bin:/rootfr/root/bin:/analysis/cactus/bin"
ENV PYTHONPATH="${HOME}/.local/lib:${PYTHONPATH}"
ENV EUDAQPATH="/analysis/eudaq"
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/analysis/corryvreckan/lib:/analysis/eudaq/lib:/analysis/boost/lib:/analysis/cactus/lib"

# The software 
RUN cd /analysis \
    && git clone -b docker-prov --single-branch https://gitlab.cern.ch/duarte/corryvreckan.git \
    && mkdir -p /analysis/corryvreckan/build \
    && cd /analysis/corryvreckan/build \
    && cmake -DBUILD_EventLoaderEUDAQ2=ON \
           -DROOT_DIR="/rootfr/root/cmake" \
           -DCMAKE_INSTALL_PREFIX=../ \
           -DCMAKE_MODULE_PATH="/usr/share/cmake/Modules/;/usr/share/cmake/Modules/" \
          .. \
    && make -j`grep -c processor /proc/cpuinfo` \
    && make install \
    && rm -rf /analysis/corryvreckan/build

# Default command for starting the container, executed after the ENTRYPOINT
CMD ["bash"]

