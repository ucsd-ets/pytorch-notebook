FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04

MAINTAINER Adam Tilghman <acms-consult@ucsd.edu>

ENV TERM linux
ENV DEBIAN_FRONTEND noninteractive

#############################################
# From https://github.com/conda/conda-docker/blob/master/miniconda2/debian/Dockerfile
# Install miniconda first

ENV PATH /opt/conda/bin:$PATH
ENV CONDA_DIR /opt/conda
RUN mkdir -m 0755 /opt/conda

RUN apt-get -qq update && apt-get -qq -y install curl bzip2 \
    && curl -sSL https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp $CONDA_DIR \
    && rm -rf /tmp/miniconda.sh \
    && conda install -y python=2 \
    && conda update conda \
    && apt-get -qq -y remove curl bzip2 \
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
    && conda clean --all --yes

#############################################
# TF dependencies per the TF standard Dockerfile

# Pick up some TF dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libfreetype6-dev \
        libpng12-dev \
        libzmq3-dev \
        pkg-config \
        python \
        python-dev \
        rsync \
        software-properties-common \
        unzip \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip --no-cache-dir install \
        Pillow \
        h5py \
        ipykernel \
        jupyter \
        matplotlib \
        numpy \
        pandas \
        scipy \
        sklearn \
        && \
    python -m ipykernel.kernelspec

########################################################
# Additional packages requested by MUS 206
RUN apt-get -qq update && apt-get -qq -y install \
	less nano vim \
	openssh-client \
	dnsutils iputils-ping \
	wget \
	cuda-core-8-0 \
	cuda-command-line-tools-8-0

########################################################
# Install TensorFlow GPU version from their CI repository
#RUN pip --no-cache-dir install \ 
#	http://ci.tensorflow.org/view/Nightly/job/nightly-matrix-linux-gpu/TF_BUILD_IS_OPT=OPT,TF_BUILD_IS_PIP=PIP,TF_BUILD_PYTHON_VERSION=PYTHON2,label=gpu-linux/lastSuccessfulBuild/artifact/pip_test/whl/tensorflow_gpu-1.head-cp27-cp27mu-manylinux1_x86_64.whl

# Force final 1.4.0 version since anything newer requires CUDA 9.0 (we're at 8.0 as of Spring 2018)
RUN pip install --upgrade https://storage.googleapis.com/tensorflow/linux/gpu/tensorflow_gpu-1.4.0rc1-cp27-none-linux_x86_64.whl

RUN apt-get -qq update && apt-get -qq -y install git

########################################################
# CSE 190 requested PyTorch

# 2/20/18 agt - reconfigure various install commands
# to force conda 4.4.7 per:
# https://github.com/conda/conda/issues/6811
# FIXED 4/2018 agt
RUN conda install --yes pytorch torchvision -c pytorch 

RUN conda install --quiet --yes -c conda-forge pygpu nose theano

RUN apt-get -qq update && apt-get -qq -y install \
	git 

# Requested by Music Fall 2018 - should move to separate image
#libav-tools ffmpeg fluidsynth libgtk2.0-dev

RUN pip install \
	keras

RUN conda install --yes -c menpo opencv

# Requested 11/17/2017 by Utkarsh
RUN conda install --yes nltk spacy

RUN pip install html5lib==1.0b8
RUN apt-get update && apt-get -qq -y install protobuf-compiler python-pil python-lxml
RUN conda install networkx

# To support background jobs
RUN apt-get update &&  apt-get -qq -y install screen tmux
# Fix screen binary permissions for non-setuid execution (so NSS_WRAPPER can funciton)
RUN chmod g-s /usr/bin/screen
RUN chmod 1777 /var/run/screen

# To support incoming SFTP copies
RUN apt-get update && apt-get -qq -y install openssh-sftp-server

# Per cs253 request
RUN apt-get update && apt-get -qq -y install cmake

# Per cg260s request SP18
RUN pip install graphviz && python -c 'import graphviz'
RUN conda install graphviz
RUN conda install pydot && python -c 'import pydot'
RUN apt-get update && apt-get -qq -y install pandoc
RUN apt-get update && apt-get -y install texlive-xetex
# Note: metafont doesn't seem to like using NFS homedir as tmp directory, so point it elsewhere
ENV TEXMFVAR /tmp
RUN apt-get update && apt-get -y install libgtk2.0-0

RUN apt-get update && apt-get -y install opencv

# clean conda cache last to free up space in the image
RUN conda clean --all --yes

# Install entrypoint
COPY run_jupyter.sh /

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:$LD_LIBRARY_PATH
ENV DEBIAN_FRONTEND teletype

# TensorBoard
EXPOSE 6006
# IPython
EXPOSE 8888

# Fear not, root execution won't be possible within our instructional cluster
CMD ["/run_jupyter.sh", "--allow-root"]

