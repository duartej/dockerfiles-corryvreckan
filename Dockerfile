FROM gitlab-registry.cern.ch/duarte/dockerfiles-eudaqv2/eudaq2:caen-raw-events
LABEL maintainer.name="Jordi Duarte-Campderros"
LABEL maintainer.email="duarte@ifca.unican.es"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

USER 0

# Place at the directory
WORKDIR /analysis

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

# Extract eudaq and boost from eudaq image: PROV (ph2_acf)
COPY --from=gitlab-registry.cern.ch/duarte/dockerfiles-eudaqv2/eudaq2:caen-raw-events /eudaq/eudaq /analysis/eudaq
COPY --from=gitlab-registry.cern.ch/duarte/dockerfiles-eudaqv2/eudaq2:caen-raw-events /eudaq/boost /analysis/boost
COPY --from=gitlab-registry.cern.ch/duarte/dockerfiles-eudaqv2/eudaq2:caen-raw-events /eudaq/root  /rootfr/root

# The c++ standard
ARG CMAKE_CXX_STANDARD=20
ARG CXXFLAGS="-std=c++20"

COPY CMakeLists.txt CMakeLists.txt

ENV ROOTSYS=/rootfr/root
# BE aware of the ROOT libraries
ENV LD_LIBRARY_PATH=/rootfr/root/lib
ENV PYTHONPATH=/rootfr/root/lib

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
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/analysis/corryvreckan/lib:/analysis/eudaq/lib:/analysis/boost/lib"

# The software 
RUN cd /analysis \
    && git clone -b docker-prov --single-branch https://gitlab.cern.ch/duarte/corryvreckan.git \
    && cp CMakeLists.txt /analysis/corryvreckan/ \
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

