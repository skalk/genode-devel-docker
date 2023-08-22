FROM  ubuntu:22.04
LABEL maintainer="stefan.kalkowski@genode-labs.com"
LABEL version="23.05"
LABEL description="This is a docker image to develop Genode OS components"

ARG DEBIAN_FRONTEND=noninteractive
ARG JOBS=4

ARG QEMU_SHA1=0e87f38890e1317027b23dff2e484f41c0e53493
ARG QEMU_FILE=qemu-6.2.0-rc4.tar.xz
ARG QEMU_TARGET_LIST=aarch64-softmmu,arm-softmmu,i386-softmmu,riscv64-softmmu,x86_64-softmmu

ARG GENODE_SHA1=25e914c6ff7f3a4f7be22b9bd9176aaace86a760
ARG GENODE_BRANCH=716579b
ARG GENODE_URL=https://github.com/genodelabs/genode
ARG GENODE_FILE=genode.tgz


#
# Unfortunately, we've to do as few as possible RUN steps  @ @
# to not pollute the docker history, otherwise the image    |
# gets extraordinary large                                 ---
#

#
# Install necessary packages for Genode build system and third party software builds
#
RUN apt update && \
    apt install -y acpica-tools autoconf autoconf2.69 autogen bash-completion \
        bc binutils-dev bison build-essential byacc ccache cmake cpio curl \
        dosfstools e2tools ed expect flex gawk gdisk gnat-11 git gprbuild \
        libc-dev-bin libelf-dev libexpat1-dev libfontconfig1 libgmp-dev \
        libncurses-dev libpixman-1-dev libsdl1.2-dev libsdl2-dev libxml2-utils \
        lynx mawk mtools ninja-build patch picocom pip python-is-python3 \
        python-six python2-minimal python3-future python3-jinja2 \
        python3-jsonschema python3-minimal python3-ply python3-six \
        python3-tempita socat tcl telnet texinfo tidy u-boot-tools unzip vim \
        wget xorriso xsltproc xz-utils yasm && \
    apt clean \
    pip install pyfdt

#
# Install vanilla Qemu to execute run-scripts for various Qemu platforms
#
RUN curl -s -L -o /${QEMU_FILE} https://download.qemu.org/${QEMU_FILE}  && \
    echo "${QEMU_SHA1} ${QEMU_FILE}" > ${QEMU_FILE}.sha1                && \
    sha1sum -c ${QEMU_FILE}.sha1                                        && \
    tar xJf qemu-6.2.0-rc4.tar.xz                                       && \
    cd /qemu-6.2.0-rc4                                                  && \
    ./configure --target-list=${QEMU_TARGET_LIST}                       && \
    make -j${JOBS}                                                      && \
    make install                                                        && \
    cd /                                                                && \
    rm -r /qemu-6.2.0*

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
