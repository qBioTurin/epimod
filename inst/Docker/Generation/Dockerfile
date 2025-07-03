# syntax=docker/dockerfile:1.4

###############################################################################
# Stage 1 ─ builder: compila GreatSPN & dipendenze
###############################################################################
FROM debian:bullseye AS builder

# -------- shell + pipefail + apt retry --------------------------------------
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG DEBIAN_FRONTEND=noninteractive
RUN echo 'Acquire::Retries "5";\n\
Acquire::http::Timeout "25";\n\
Acquire::https::Timeout "25";' > /etc/apt/apt.conf.d/80-retries

# -------- pacchetti di sistema ----------------------------------------------
RUN apt-get update && \
    for i in {1..3}; do \
      echo "APT install attempt $i (builder)"; \
      apt-get install -y --no-install-recommends \
        sudo adduser apt-utils wget \
        gcc g++ libgmp-dev libgmpxx4ldbl libboost-all-dev \
        flexc++ ant libglib2.0-dev patch python3 libglpk-dev liblpsolve55-dev \
        autoconf automake libtool zip flex byacc time graphviz libsuitesparse-dev \
        libmotif-dev make libxml++2.6-dev libglibmm-2.4-dev texlive-font-utils \
        openjdk-17-jdk cmake git ghostscript libfl-dev && break; \
      echo "APT failed – retrying…"; sleep 20; apt-get update; \
    done && \
    rm -rf /var/lib/apt/lists/*

# -------- utente non-root ----------------------------------------------------
RUN /usr/sbin/adduser --disabled-password --gecos '' docker && \
    usermod -aG sudo docker && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER docker
WORKDIR /home/docker
ENV MAKE_ARGS=-j4

# -------- Meddly ------------------------------------------------------------
RUN git clone https://github.com/asminer/meddly.git && \
    cd meddly && git checkout v0.17.0 && \
    ./autogen.sh && ./configure --prefix=/usr/local && \
    make ${MAKE_ARGS} && sudo make install

# -------- OGDF --------------------------------------------------------------
RUN for n in {1..3}; do \
      git clone https://github.com/ogdf/ogdf.git && break || sleep 10; \
    done && \
    cd ogdf && mkdir build && cd build && cmake .. && \
    make ${MAKE_ARGS} && sudo make install

# -------- lp_solve ----------------------------------------------------------
RUN wget -O lp_solve.tar.gz \
      https://downloads.sourceforge.net/project/lpsolve/lpsolve/5.5.2.11/lp_solve_5.5.2.11_source.tar.gz && \
    wget https://raw.githubusercontent.com/qBioTurin/SOURCESgreatspn/master/contrib/build_lpsolve.sh && \
    tar xzf lp_solve.tar.gz && \
    chmod +x build_lpsolve.sh && ./build_lpsolve.sh

# -------- GreatSPN ----------------------------------------------------------
RUN mkdir -p ~/GreatSPN && cd ~/GreatSPN && \
    for n in {1..5}; do \
      git clone https://github.com/qBioTurin/SOURCESgreatspn.git SOURCES && break || sleep 10; \
    done && \
    cd SOURCES && \
    make ${MAKE_ARGS} -k derived_objects && \
    make ${MAKE_ARGS} && sudo make install

###############################################################################
# Stage 2 ─ deploy_base: runtime minimale
###############################################################################
FROM r-base:4.2.2 AS deploy_base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ARG DEBIAN_FRONTEND=noninteractive
RUN echo 'Acquire::Retries "5";\n\
Acquire::http::Timeout "25";\n\
Acquire::https::Timeout "25";' > /etc/apt/apt.conf.d/80-retries

RUN apt-get update && \
    for i in {1..3}; do \
      echo "APT install attempt $i (deploy_base)"; \
      apt-get install -y --no-install-recommends \
        sudo adduser apt-utils \
        gcc g++ libgmp10 libgmpxx4ldbl libglpk40 \
        flexc++ python3 flex time graphviz bison libglpk-dev \
        make openjdk-17-jre git ghostscript && break; \
      echo "APT failed – retrying…"; sleep 20; apt-get update; \
    done && \
    rm -rf /var/lib/apt/lists/*

RUN /usr/sbin/adduser docker sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER docker
WORKDIR /home/docker

###############################################################################
# Stage 3 ─ updater
###############################################################################
FROM builder AS updater
ARG UPDATE_VERSION
RUN cd ~/GreatSPN/SOURCES && \
    git pull && \
    make ${MAKE_ARGS} -k derived_objects && \
    make ${MAKE_ARGS} && sudo make install

###############################################################################
# Stage 4 ─ immagine finale di runtime
###############################################################################
FROM deploy_base
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- Copia binari compilati (owner già 1000:1000) ----------------------------
COPY --from=updater --chown=1000:1000 /usr/local/GreatSPN /usr/local/GreatSPN
COPY --from=updater --chown=1000:1000 /usr/local/lib       /usr/local/lib

# --- Permessi & workdir ------------------------------------------------------
USER root
RUN mkdir -p /home && chown -R 1000:1000 /home

RUN find /usr/local/lib -name '*.a' -o -name '*.la' -delete

WORKDIR /home
USER 1000:1000


# --- Linker & PATH -----------------------------------------------------------
USER root
RUN echo '/usr/local/lib' > /etc/ld.so.conf.d/greatspn.conf && ldconfig
USER 1000:1000
ENV PATH="/usr/local/GreatSPN/scripts:${PATH}"

