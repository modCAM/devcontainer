# This file is part of modCAM, open source software for Computer Aided
# Manufacturing research.
# 
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
# 
# SPDX-FileCopyrightText: Copyright contributors to the modCAM project.
# SPDX-License-Identifier: MPL-2.0

ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}
RUN userdel -r ubuntu

# Software versions
ARG CMAKE_VERSION=4.0.3
ARG GCC_VERSION=13
ARG GIT_LFS_VERSION=3.7.0
ARG LLVM_VERSION=18
ARG UBUNTU_VERSION

# User/group identity
ARG USERNAME=modcam
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

LABEL org.opencontainers.image.authors="Contributors to the modCAM project"
LABEL org.opencontainers.image.description="An image for modCAM development. This image was created to have more control over software versions in the GitHub CI workflow."
LABEL org.opencontainers.image.title="modCAM development container"
LABEL org.opencontainers.image.vendor="modCAM"

SHELL [ "/bin/bash", "-c" ]

RUN groupadd --gid ${USER_GID} ${USERNAME} && \
	useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}

RUN apt-get update && apt-get upgrade -y && \
	apt-get -y install \
	curl doxygen git linux-libc-dev make ninja-build pkg-config \
	software-properties-common tar unzip wget zip

# GCC/G++
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
	apt-get update && \
	apt-get install -y gcc-${GCC_VERSION} g++-${GCC_VERSION} && \
	update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${GCC_VERSION} 30 && \
	update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${GCC_VERSION} 30 && \
	update-alternatives --install /usr/bin/cc cc /usr/bin/gcc 30 && \
	update-alternatives --set cc /usr/bin/gcc && \
	update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 30 && \
	update-alternatives --set c++ /usr/bin/g++

# LLVM/clang
RUN wget https://apt.llvm.org/llvm.sh -q -O /tmp/llvm.sh && \
	chmod +x /tmp/llvm.sh && \
	/tmp/llvm.sh ${LLVM_VERSION} all && \
	rm /tmp/llvm.sh && \
	ln -s /usr/bin/clang-${LLVM_VERSION} /usr/bin/clang && \
	ln -s /usr/bin/clang++-${LLVM_VERSION} /usr/bin/clang++ && \
	ln -s /usr/bin/clang-cl-${LLVM_VERSION} /usr/bin/clang-cl && \
	ln -s /usr/bin/clang-tidy-${LLVM_VERSION} /usr/bin/clang-tidy && \
	ln -s /usr/bin/clangd-${LLVM_VERSION} /usr/bin/clangd

# CMake
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh -q -O /tmp/cmake-install.sh && \
	chmod u+x /tmp/cmake-install.sh && \
	/tmp/cmake-install.sh --skip-license --exclude-subdir --prefix=/usr/local && \
	rm /tmp/cmake-install.sh

# Git Large File Storage
RUN wget https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-amd64-v${GIT_LFS_VERSION}.tar.gz -q -O /tmp/git-lfs.tar.gz && \
	tar -xzf /tmp/git-lfs.tar.gz -C /tmp && \
	/tmp/git-lfs-${GIT_LFS_VERSION}/install.sh && \
	rm -f /tmp/git-lfs.tar.gz && rm -rf /tmp/git-lfs-${GIT_LFS_VERSION}

# Cleanup
RUN apt-get autoremove && apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${USERNAME}

WORKDIR /home/${USERNAME}

RUN git lfs install

# vcpkg
ENV VCPKG_ROOT=/home/${USERNAME}/vcpkg
ENV PATH="${VCPKG_ROOT}:$PATH"
RUN git clone https://github.com/microsoft/vcpkg.git && \
	./vcpkg/bootstrap-vcpkg.sh -disableMetrics
