ARG PYTHON=python3
ARG PYTHON_VERSION=3.9.16
ARG PYTHON_SHORT_VERSION=3.9
ARG MAMBA_VERSION=22.9.0-3

# [20230202] EFA does not support ubuntu22.04 yet.
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04 AS base_image

ENV DEBIAN_FRONTEND=noninteractive \
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/local/lib"

RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get autoremove -y \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

FROM base_image AS common

LABEL maintainer="Verdi March"
LABEL dlc_major_version="1"

ARG PYTHON
ARG PYTHON_VERSION
ARG PYTHON_SHORT_VERSION
ARG MAMBA_VERSION

ARG EFA_PATH=/opt/amazon/efa
ARG CUDA_HOME=/usr/local/cuda

# This arg required to stop docker build waiting for region configuration while installing tz data from ubuntu 20
ARG DEBIAN_FRONTEND=noninteractive

# Python won’t try to write .pyc or .pyo files on the import of source modules
# Force stdin, stdout and stderr to be totally unbuffered. Good for logging
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"
ENV LD_LIBRARY_PATH="/opt/conda/lib:${LD_LIBRARY_PATH}"
ENV PYTHONIOENCODING=UTF-8
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

# This can be queried at runtime from pytorch.
#ENV TORCH_CUDA_ARCH_LIST="3.7 5.0 7.0+PTX 8.0"
#ENV TORCH_NVCC_FLAGS="-Xfatbin -compress-all"

ENV NCCL_VERSION=2.16.2
ENV EFA_VERSION=latest
ENV BRANCH_OFI=1.5.0-aws

ENV CMAKE_PREFIX_PATH="$(dirname $(which conda))/../"
ENV OPEN_MPI_PATH=/opt/amazon/openmpi

ENV RDMAV_FORK_SAFE=1

RUN apt-get update \
 # TODO: Remove systemd upgrade once it is updated in base image
 && apt-get -y upgrade --only-upgrade systemd \
 && apt-get install -y --allow-change-held-packages --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    emacs \
    git \
    hwloc \
    jq \
    libcurl4 \
    libglib2.0-0 \
    libgl1-mesa-glx \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libibverbs-dev \
    libhwloc-dev \
    libnuma1 \
    libnuma-dev \
    libssl3 \
    libssl-dev \
    libtool \
    openssl \
    python3-dev \
    time \
    unzip \
    vim \
    wget \
    zlib1g-dev \
# gdrcopy
check \
pkg-config \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

ENV PATH="$OPEN_MPI_PATH/bin:$PATH"
ENV LD_LIBRARY_PATH=$OPEN_MPI_PATH/lib/:$EFA_PATH/lib/:$LD_LIBRARY_PATH


# for conda ssl verification
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
RUN curl -L -o ~/mambaforge.sh https://github.com/conda-forge/miniforge/releases/download/${MAMBA_VERSION}/Mambaforge-${MAMBA_VERSION}-Linux-x86_64.sh \
 && chmod +x ~/mambaforge.sh \
 && ~/mambaforge.sh -b -p /opt/conda \
 && rm ~/mambaforge.sh \
 && /opt/conda/bin/conda install -y -c conda-forge \
    python=$PYTHON_VERSION \
    cython \
    mkl \
    mkl-include \
    parso \
    typing \
    h5py \
    requests \
    pyopenssl \
    libgcc \
    conda-content-trust \
    charset-normalizer \
 && /opt/conda/bin/conda install -c pytorch -y magma-cuda118 \
 # conda pathy installs dataclasses regardless of py version: https://github.com/conda-forge/pathy-feedstock/blob/1e6da43da5c8e11e09c063c79b09236bbacb7780/recipe/meta.yaml#L29
 # pypi solves this issue: https://github.com/justindujardin/pathy/blob/master/requirements.txt#L3
 # dataclasses package is not needed for py>=37
 && pip uninstall -y dataclasses || true \
 && /opt/conda/bin/conda clean -ya

# Conda installs links for libtinfo.so.6 and libtinfo.so.6.2 both
# Which causes "/opt/conda/lib/libtinfo.so.6: no version information available" warning
# Removing link for libtinfo.so.6. This change is needed only for ubuntu 20.04-conda, and can be reverted
# once conda fixes the issue
RUN rm -rf /opt/conda/lib/libtinfo.so.6

RUN /opt/conda/bin/conda config --set ssl_verify False \
 && pip install --no-cache-dir --upgrade pip --no-cache-dir --trusted-host pypi.org --trusted-host files.pythonhosted.org \
 && ln -s /opt/conda/bin/pip /usr/local/bin/pip3

RUN rm -rf /root/.cache | true

WORKDIR /

CMD ["/bin/bash"]
