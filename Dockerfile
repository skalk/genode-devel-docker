FROM  ubuntu:24.04
LABEL maintainer="stefan.kalkowski@genode-labs.com"
LABEL version="25.02"
LABEL description="This is a docker image to develop Genode OS components"

ARG DEBIAN_FRONTEND=noninteractive
ARG JOBS=4

ARG QEMU_SHA1=cc63cb748e100d2428e1173e911ab226c6f6ef4f
ARG QEMU_FILE=qemu-8.2.2.tar.xz
ARG QEMU_TARGET_LIST=aarch64-softmmu,arm-softmmu,i386-softmmu,riscv64-softmmu,x86_64-softmmu

ARG GENODE_SHA1=25e914c6ff7f3a4f7be22b9bd9176aaace86a760
ARG GENODE_BRANCH=716579b
ARG GENODE_URL=https://github.com/genodelabs/genode
ARG GENODE_FILE=genode.tgz

ARG CTAGS_SHA1=ff90a8e50537f127089b2d2d163822a76d3cb196
ARG CTAGS_BRANCH=745ac2f
ARG CTAGS_URL=https://github.com/universal-ctags/ctags
ARG CTAGS_FILE=ctags.tgz

ARG OWSM_SHA1=e051e9f630fb4465d46b7c926a622ddcce3f193d
ARG OWSM_URL=https://github.com/Openwsman/openwsman/archive/refs/tags
ARG OWSM_FILE=v2.7.2.tar.gz

ARG WSMC_SHA1=290310205b74f89787dc7bf2edc5d58a9576d453
ARG WSMC_URL=https://github.com/Openwsman/wsmancli/archive/refs/tags
ARG WSMC_FILE=v2.6.2.tar.gz

ARG AMTT_SHA1=429262f643f6f438c756d82c255147d141767c18
ARG AMTT_BRANCH=8925291
ARG AMTT_URL=https://github.com/kraxel/amtterm
ARG AMTT_FILE=amtterm.tgz

#
# Unfortunately, we've to do as few as possible RUN steps  @ @
# to not pollute the docker history, otherwise the image    |
# gets extraordinary large                                 ---
#

#
# Install necessary packages for Genode build system and third party software builds
#
RUN apt update && \
    apt install -y acpica-tools autoconf autoconf2.69 autogen automake bash-completion \
        bc binutils-dev bison build-essential byacc ccache cmake cpio curl \
        dosfstools e2tools ed expect flex gawk gdisk git gnat-13 \
        libc-dev-bin libcurl4-openssl-dev libelf-dev libexpat1-dev libfontconfig1 libglib2.0-dev libgmp-dev \
        libncurses-dev libpixman-1-dev libsdl2-dev libslirp-dev libsoap-lite-perl libtool libxml2-utils libxml2-dev \
        lighttpd lynx mawk mtools ninja-build ovmf patch picocom pip pkg-config \
        python3-minimal python3-venv socat tcl telnet texinfo tidy u-boot-tools unzip vim \
        wget xorriso xsltproc xz-utils yasm && \
    apt clean

#
# Install python3 libraries mainly for sel4
#
RUN python3 -m venv /usr/local && \
    /usr/local/bin/pip install future jinja2 ply six jsonschema pyfdt setuptools pyyaml

#
# Build & install ctags used by DDE Linux portin tools
#
RUN curl -s -L -o ${CTAGS_FILE} ${CTAGS_URL}/tarball/${CTAGS_BRANCH} && \
    echo "${CTAGS_SHA1} ${CTAGS_FILE}" > ${CTAGS_FILE}.sha1          && \
    sha1sum -c ${CTAGS_FILE}.sha1                                    && \
    tar xzf ${CTAGS_FILE}                                            && \
    cd /universal-ctags-ctags-${CTAGS_BRANCH}                        && \
    ./autogen.sh                                                     && \
    ./configure                                                      && \
    make -j${JOBS}                                                   && \
    make install                                                     && \
    cd /                                                             && \
    rm -rf universal-ctags* ${CTAGS_FILE}*

#
# Build & install Openwsman library and client
#
RUN curl -s -L -o ${OWSM_FILE} ${OWSM_URL}/${OWSM_FILE}    && \
    echo "${OWSM_SHA1} ${OWSM_FILE}" > ${OWSM_FILE}.sha1   && \
    sha1sum -c ${OWSM_FILE}.sha1                           && \
    tar xzf ${OWSM_FILE}                                   && \
    cd /openwsman-2.7.2                                    && \
    cmake -S . -B build -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_LIBCIM=NO -DBUILD_EXAMPLES=NO -DBUILD_BINDINGS=NO -DBUILD_PYTHON3=NO -DBUILD_PYTHON=NO -DBUILD_RUBY=NO -DBUILD_PERL=NO -DBUILD_JAVA=NO -DBUILD_CSHARP=NO -DBUILD_SWIG_PLUGIN=NO -DDISABLE_SERVER=YES -DENABLE_EVENTING_SUPPORT=NO -DBUILD_TESTS=NO -DUSE_PAM=NO && \
    cd build                                               && \
    make -j${JOBS}                                         && \
    make install                                           && \
    cd /                                                   && \
    rm -rf openwsman* ${OWSM_FILE}*                        && \
    curl -s -L -o ${WSMC_FILE} ${WSMC_URL}/${WSMC_FILE}    && \
    echo "${WSMC_SHA1} ${WSMC_FILE}" > ${WSMC_FILE}.sha1   && \
    sha1sum -c ${WSMC_FILE}.sha1                           && \
    tar xzf ${WSMC_FILE}                                   && \
    cd /wsmancli-2.6.2                                     && \
    ./bootstrap                                            && \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ./configure   && \
    make install                                           && \
    cd /                                                   && \
    rm -rf wsmancli* ${WSMC_FILE}*                         && \
    ldconfig

#
# Build & install amtterm
#
RUN curl -s -L -o ${AMTT_FILE} ${AMTT_URL}/tarball/${AMTT_BRANCH} && \
    echo "${AMTT_SHA1} ${AMTT_FILE}" > ${AMTT_FILE}.sha1          && \
    sha1sum -c ${AMTT_FILE}.sha1                                  && \
    tar xzf ${AMTT_FILE}                                          && \
    cd /kraxel-amtterm-${AMTT_BRANCH}                             && \
    make SHELL=bash -j${JOBS}                                     && \
    make install                                                  && \
    cd /                                                          && \
    rm -rf kraxel* ${AMTT_FILE}*

#
# Install vanilla Qemu to execute run-scripts for various Qemu platforms
#
RUN curl -s -L -o /${QEMU_FILE} https://download.qemu.org/${QEMU_FILE}  && \
    echo "${QEMU_SHA1} ${QEMU_FILE}" > ${QEMU_FILE}.sha1                && \
    sha1sum -c ${QEMU_FILE}.sha1                                        && \
    tar xJf ${QEMU_FILE}                                                && \
    cd /qemu-8.2.2                                                      && \
    ./configure --target-list=${QEMU_TARGET_LIST}                       && \
    make -j${JOBS}                                                      && \
    make install                                                        && \
    cd /                                                                && \
    rm -r /qemu-8.2.2*

#
# Install Genode specific GNU compiler toolchain + QT5 tools + netperf testing
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
    tool/ports/prepare_port netperf                                     && \
    cd `tool/ports/current netperf`/src/app/netperf                     && \
    ./configure                                                         && \
    make -j${JOBS}                                                      && \
    make install                                                        && \
    cd /                                                                && \
    rm -rf /genode*
