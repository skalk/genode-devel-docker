FROM  ubuntu:20.04
LABEL maintainer="stefan.kalkowski@genode-labs.com"
LABEL version="1.0"
LABEL description="This is a docker image to develop Genode OS components"

ARG DEBIAN_FRONTEND=noninteractive
ARG JOBS=4

ARG QEMU_SHA1=03d221806203a32795042279e0a21413a0c5ffc3
ARG QEMU_FILE=qemu-4.2.1.tar.xz
ARG QEMU_TARGET_LIST=aarch64-softmmu,arm-softmmu,i386-softmmu,riscv64-softmmu,x86_64-softmmu

ARG GENODE_SHA1=f913db7882deab799c98bcaf0be2671e2c1bdd18
ARG GENODE_BRANCH=2491eee
ARG GENODE_URL=https://github.com/genodelabs/genode
ARG GENODE_FILE=genode.tgz

ARG GNAT_URL=https://community.download.adacore.com/v1
ARG GNAT_SHA1=0cd3e2a668332613b522d9612ffa27ef3eb0815b
ARG GNAT_FILE=gnat-community-2019-20190517-x86_64-linux-bin
ARG GNAT_GIT_URL=https://github.com/AdaCore/gnat_community_install_script
ARG GNAT_GIT_BRANCH=f74ecb0
ARG GNAT_GIT_SHA1=b700e32f72ed2f9337cb45a69aa8cc3a23fdd0e1

ARG SPIKE_FES_URL=https://github.com/ssumpf/riscv-fesvr
ARG SPIKE_FES_BRANCH=0b85715
ARG SPIKE_FES_SHA1=66a2d0d28d2a6223e0e2830f4cfcc5af300d788c
ARG SPIKE_ISA_URL=https://github.com/ssumpf/riscv-isa-sim
ARG SPIKE_ISA_BRANCH=f38dcde
ARG SPIKE_ISA_SHA1=ca467006bd6327a58fe8308f64466cd0ed03f152


#
# Unfortunately, we've to do as few as possible RUN steps  @ @
# to not pollute the docker history, otherwise the image    |
# gets extraordinary large                                 ---
#

#
# Install necessary packages for Genode build system and third party software builds
#
RUN apt update && \
    apt install -y acpica-tools autoconf autoconf2.64 autogen bash-completion \
                   binutils-dev bison build-essential byacc ccache cpio curl \
                   dosfstools e2tools expect flex gawk gdisk gnat git gprbuild \
                   libc-dev-bin libexpat1-dev libfontconfig1 libncurses-dev \
                   libpixman-1-dev libsdl1.2-dev libsdl2-dev libxml2-utils \
                   mawk mtools patch picocom python-is-python3 python-six \
                   python2-minimal python3-future python3-minimal python3-ply \
                   python3-six python3-tempita socat tcl telnet texinfo tidy \
                   u-boot-tools unzip vim wget xorriso xsltproc xz-utils yasm && \
    apt clean

#
# Install vanilla Qemu to execute run-scripts for various Qemu platforms
#
RUN curl -s -L -o /${QEMU_FILE} https://download.qemu.org/${QEMU_FILE}  && \
    echo "${QEMU_SHA1} ${QEMU_FILE}" > ${QEMU_FILE}.sha1                && \
    sha1sum -c ${QEMU_FILE}.sha1                                        && \
    tar xJf qemu-4.2.1.tar.xz                                           && \
    cd /qemu-4.2.1                                                      && \
    ./configure --target-list=${QEMU_TARGET_LIST}                       && \
    make -j${JOBS}                                                      && \
    make install                                                        && \
    cd /                                                                && \
    rm -r /qemu-4.2.1*

#
# Install Genode specific GNU compiler toolchain + QT5 tools
#
RUN curl -s -L -o ${GENODE_FILE} ${GENODE_URL}/tarball/${GENODE_BRANCH} && \
    echo "${GENODE_SHA1} ${GENODE_FILE}" > ${GENODE_FILE}.sha1          && \
    sha1sum -c ${GENODE_FILE}.sha1                                      && \
    tar xzf ${GENODE_FILE}                                              && \
    cd /genodelabs-genode-${GENODE_BRANCH}                              && \
    tool/tool_chain     x86      SUDO= MAKE_JOBS=${JOBS}                && \
    tool/tool_chain     arm      SUDO= MAKE_JOBS=${JOBS}                && \
    tool/tool_chain     aarch64  SUDO= MAKE_JOBS=${JOBS}                && \
    tool/tool_chain     riscv    SUDO= MAKE_JOBS=${JOBS}                && \
    tool/tool_chain_qt5 build    SUDO= MAKE_JOBS=${JOBS}                && \
    tool/tool_chain_qt5 install  SUDO= MAKE_JOBS=${JOBS}                && \
    cd /                                                                && \
    rm -rf /genode*

#
# Install AdaCore Community toolchain to build Muen separation kernel
#
RUN curl -s -L -o gnat_install.tgz ${GNAT_GIT_URL}/tarball/${GNAT_GIT_BRANCH}  && \
    echo "${GNAT_GIT_SHA1}  gnat_install.tgz" > gnat_install.tgz.sha1          && \
    sha1sum -c gnat_install.tgz.sha1                                           && \
    curl -s -L -o ${GNAT_FILE} ${GNAT_URL}/${GNAT_SHA1}?filename=${GNAT_FILE}  && \
    echo "${GNAT_SHA1}  ${GNAT_FILE}" > ${GNAT_FILE}.sha1                      && \
    sha1sum -c ${GNAT_FILE}.sha1                                               && \
    tar xzf gnat_install.tgz                                                   && \
    sh /AdaCore-gnat_community_install_script-${GNAT_GIT_BRANCH}/install_package.sh /${GNAT_FILE} \
       /opt/GNAT/2019 com.adacore.gnat,com.adacore.spark2014_discovery         && \
    rm -rf /AdaCore-* /gnat*

#
# Install Spike emulator for RiscV testing
#
RUN curl -s -L -o fesvr.tgz ${SPIKE_FES_URL}/tarball/${SPIKE_FES_BRANCH} && \
    echo "${SPIKE_FES_SHA1} fesvr.tgz" > fesvr.tgz.sha1                  && \
    sha1sum -c fesvr.tgz.sha1                                            && \
    tar xzf fesvr.tgz                                                    && \
    cd /ssumpf-riscv-fesvr-${SPIKE_FES_BRANCH}                           && \
    ./configure                                                          && \
    make -j${JOBS}                                                       && \
    make install                                                         && \
    cd /                                                                 && \
    curl -s -L -o isa.tgz ${SPIKE_ISA_URL}/tarball/${SPIKE_ISA_BRANCH}   && \
    echo "${SPIKE_ISA_SHA1} isa.tgz" > isa.tgz.sha1                      && \
    sha1sum -c isa.tgz.sha1                                              && \
    tar xzf isa.tgz                                                      && \
    cd /ssumpf-riscv-isa-sim-${SPIKE_ISA_BRANCH}                         && \
    export CXXFLAGS="-Wno-catch-value -Wno-switch-unreachable"           && \
    ./configure                                                          && \
    make -j${JOBS}                                                       && \
    make install                                                         && \
    cd /                                                                 && \
    rm -rf /ssumpf-* fesvr.* isa.*
