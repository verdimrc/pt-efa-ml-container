################################################################################
# Based on https://github.com/aws/deep-learning-containers/blob/360925a71d5237aa52be193efd92059989925770/pytorch/training/docker/1.13/py3/cu117/Dockerfile.gpu
# - Commit: [b6302c9](https://github.com/aws/deep-learning-containers/commit/b6302c9ee4ccc60aa7ec11ba4be78454f11ce276)
#
# Think of this template enhancing Amr's version with newer software plus stuffs
# from pytorch training DLC (excluding additional packages such as smddp, dgl,
# horovod, etc.).
#
# For exact changes, please diff to the original version.
#
# Software versions: updated on 20220202.
################################################################################
# Build instruction:
#
#     docker build . -t <tag>
################################################################################
ARG PYTHON=python3
ARG PYTHON_VERSION=3.9.16
ARG PYTHON_SHORT_VERSION=3.9
ARG MAMBA_VERSION=22.9.0-3

# PyTorch Binaries
ARG PT_EC2_TRAINING_URL=https://aws-pytorch-unified-cicd-binaries.s3.us-west-2.amazonaws.com/r1.13.1_ec2/20221219-193736/54406b8eed7fbd61be629cb06229dfb7b6b2954e/torch-1.13.1%2Bcu117-cp39-cp39-linux_x86_64.whl
ARG PT_TORCHVISION_URL=https://download.pytorch.org/whl/cu117/torchvision-0.14.1%2Bcu117-cp39-cp39-linux_x86_64.whl
ARG PT_TORCHAUDIO_URL=https://download.pytorch.org/whl/cu117/torchaudio-0.13.1%2Bcu117-cp39-cp39-linux_x86_64.whl
ARG PT_TORCHDATA_URL=https://download.pytorch.org/whl/test/torchdata-0.5.1-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl

# [20230202] EFA does not support ubuntu22.04 yet.
FROM nvidia/cuda:11.7.1-base-ubuntu20.04 AS base_image

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

ARG CUBLAS_VERSION=11.10.3.66
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

ENV CUDNN_VERSION=8.5.0.96
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
    cuda-command-line-tools-11-7 \
    cuda-cudart-11-7 \
    cuda-libraries-11-7 \
    curl \
    emacs \
    git \
    hwloc \
    jq \
    libcublas-11-7=${CUBLAS_VERSION}-1 \
    libcublas-dev-11-7=${CUBLAS_VERSION}-1 \
    libcudnn8=$CUDNN_VERSION-1+cuda11.7 \
    libcufft-dev-11-7 \
    libcurand-dev-11-7 \
    libcurl4-openssl-dev \
    libcusolver-dev-11-7 \
    libcusparse-dev-11-7 \
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
    libssl1.1 \
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

# Install NVIDIA GDRCopy
RUN git clone https://github.com/NVIDIA/gdrcopy.git /opt/gdrcopy \
    && cd /opt/gdrcopy \
    && make lib_install install \
    && cd /opt/gdrcopy/tests \
    && make \
    && mv copylat copybw sanity apiperf /usr/bin/

# Install NCCL
RUN cd /tmp \
 && git clone https://github.com/NVIDIA/nccl.git -b v${NCCL_VERSION}-1 \
 && cd nccl \
 && /usr/bin/time -o /build-time-nccl.txt make -j src.build BUILDDIR=/usr/local \
 # nvcc to target p3, g4, g5, p4 instances
 NVCC_GENCODE="-gencode=arch=compute_86,code=sm_86 -gencode=arch=compute_80,code=sm_80 -gencode=arch=compute_75,code=sm_75 -gencode=arch=compute_70,code=sm_70" \
 && rm -rf /tmp/nccl

# Install EFA
RUN mkdir /tmp/efa \
 && cd /tmp/efa \
 && curl -O https://s3-us-west-2.amazonaws.com/aws-efa-installer/aws-efa-installer-${EFA_VERSION}.tar.gz \
 && tar -xf aws-efa-installer-${EFA_VERSION}.tar.gz \
 && cd aws-efa-installer \
 && apt-get update \
 && ./efa_installer.sh -y --skip-kmod -g --skip-limit-conf --no-verify \
 && rm -rf /tmp/efa \
 && rm -rf /tmp/aws-efa-installer-${EFA_VERSION}.tar.gz \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

ENV PATH="$OPEN_MPI_PATH/bin:$PATH"
ENV LD_LIBRARY_PATH=$OPEN_MPI_PATH/lib/:$EFA_PATH/lib/:$LD_LIBRARY_PATH

# for conda ssl verification
ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
RUN ompi_info --parsable --all | grep mpi_built_with_cuda_support:value \
 && curl -L -o ~/mambaforge.sh https://github.com/conda-forge/miniforge/releases/download/${MAMBA_VERSION}/Mambaforge-${MAMBA_VERSION}-Linux-x86_64.sh \
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
 && /opt/conda/bin/conda install -c pytorch -y magma-cuda117 \
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

WORKDIR /root

# Remove versions lock
RUN pip install --no-cache-dir -U \
    "awscli" \
    boto3 \
    "click" \
    "cmake" \
    cryptography \
    "ipython" \
    "mpi4py" \
    packaging \
    Pillow \
    "psutil" \
    "pyyaml"

# Removing the cache as it is needed for security verification
RUN rm -rf /root/.cache | true

# Configure Open MPI and configure NCCL parameters
RUN mv $OPEN_MPI_PATH/bin/mpirun $OPEN_MPI_PATH/bin/mpirun.real \
 && echo '#!/bin/bash' > $OPEN_MPI_PATH/bin/mpirun \
 && echo "${OPEN_MPI_PATH}/bin/mpirun.real --allow-run-as-root \"\$@\"" >> $OPEN_MPI_PATH/bin/mpirun \
 && chmod a+x $OPEN_MPI_PATH/bin/mpirun \
 && echo "hwloc_base_binding_policy = none" >> $OPEN_MPI_PATH/etc/openmpi-mca-params.conf \
 && echo "rmaps_base_mapping_policy = slot" >> $OPEN_MPI_PATH/etc/openmpi-mca-params.conf \
 && echo NCCL_DEBUG=INFO >> /etc/nccl.conf \
 && echo NCCL_SOCKET_IFNAME=^docker0 >> /etc/nccl.conf

# Install AWS OFI NCCL plug-in
RUN apt-get update && apt-get install -y autoconf
RUN mkdir /tmp/efa-ofi-nccl \
 && cd /tmp/efa-ofi-nccl \
 && git clone https://github.com/aws/aws-ofi-nccl.git -b v${BRANCH_OFI} \
 && cd aws-ofi-nccl \
 && ./autogen.sh \
 && ./configure --with-libfabric=/opt/amazon/efa \
  --with-mpi=/opt/amazon/openmpi \
  --with-cuda=/usr/local/cuda \
  --with-nccl=/usr/local --prefix=/usr/local \
 && make \
 && make install \
 && rm -rf /tmp/efa-ofi-nccl \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

# Install OpenSSH for MPI to communicate between containers, allow OpenSSH to talk to containers without asking for confirmation
RUN apt-get update \
 && apt-get install -y  --allow-downgrades --allow-change-held-packages --no-install-recommends \
 && apt-get install -y --no-install-recommends openssh-client openssh-server \
 && mkdir -p /var/run/sshd \
 && cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new \
 && echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new \
 && mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config \
 && rm -rf /var/lib/apt/lists/* \
 && apt-get clean

# Configure OpenSSH so that nodes can communicate with each other
RUN mkdir -p /var/run/sshd && \
 sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

RUN rm -rf /root/.ssh/ && \
 mkdir -p /root/.ssh/ && \
 ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa && \
 cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys \
 && printf "Host *\n StrictHostKeyChecking no\n" >> /root/.ssh/config

RUN mkdir -p /etc/pki/tls/certs && cp /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt

# Install AWS-PyTorch and other torch packages
RUN pip install --no-cache-dir -U ${PT_EC2_TRAINING_URL} ${PT_TORCHVISION_URL} ${PT_TORCHAUDIO_URL} ${PT_TORCHDATA_URL} torchnet

# Install Nvidia Apex (needs pytorch)
# Use Amr's way of building apex
RUN git clone https://github.com/NVIDIA/apex && \
    cd apex && \
    # p3, g4, g5, p4
    TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6" \
    /usr/bin/time -o /build-time-apex.txt pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" \
        # Below are Amr's + Nemo-Megatron's flags. Beware that these causes
        # long compilation time. Use judiciously.
        #
        # [20230202] Who uses apex?
        #
        # - HF transformers also doesn't use these flags to build apex (see
        #   their dockerfile) -- HF uses apex for T5 amongst many other things.
        #
        # - PyTorch doesn't use apex's amp.
        #
        # - PyTorch-Lightning deprecates (removes altogether) apex
        #
        # Amr's + Nemo-Megatron's flags:
        # --global-option="--deprecated_fused_adam" \
        # --global-option="--xentropy" \
        # --global-option="--fast_multihead_attn" \
        # --global-option="--fast_layer_norm" \
        # --global-option="--distributed_adam" \
        ./

WORKDIR /

RUN rm -rf /root/.cache | true

# Starts framework
CMD ["/bin/bash"]
