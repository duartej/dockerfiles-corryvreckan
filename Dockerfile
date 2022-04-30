FROM phusion/baseimage:focal-1.1.0
LABEL author="jorge.duarte.campderros@cern.ch" \ 
    version="v1.0" \ 
    description="Docker image to run the CORRYVRECKAN framework \
    with EUDAQ2"
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
   # Ipbus dependencies... maybe install it directly in eudaqv2
   erlang \
   libpugixml-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Extract eudaq and boost from eudaq image: PROV (ph2_acf)
COPY --from=duartej/eudaqv1:ph2_acf /eudaq/eudaq /analysis/eudaq
COPY --from=duartej/eudaqv1:ph2_acf /eudaq/boost /analysis/boost
COPY --from=duartej/eudaqv1:ph2_acf /rootfr/root /rootfr/root

ENV ROOTSYS /rootfr/root
# BE aware of the ROOT libraries
ENV LD_LIBRARY_PATH /rootfr/root/lib
ENV PYTHONPATH /rootfr/root/lib

# Add analyis user, allow to call sudo without password
# And give previously created folders ownership to the user
RUN useradd -md /home/analyser -ms /bin/bash -G sudo analyser \ 
  && echo "analyser:docker" | chpasswd \
  && echo "analyser ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers \
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
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/analysis/corryvreckan/lib:/analysis/eudaq/lib:/analysis/boost/lib:/analysis/ipbus-software/uhal/uhal/lib:/analysis/cactus/lib"

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

