#================================================================================
# Stage 1: build all the GreatSPN modules and their dependencies
#================================================================================
# Set up the base environment
FROM debian:bullseye AS builder

RUN apt-get update && apt-get install -y sudo adduser apt-utils wget

RUN /usr/sbin/adduser --disabled-password --gecos '' docker
RUN /usr/sbin/adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER docker
WORKDIR /home/docker

RUN sudo apt-get install -y gcc g++ libgmp-dev libgmpxx4ldbl libboost-all-dev \
flexc++ ant libglib2.0-dev patch python3 libglpk-dev liblpsolve55-dev \
autoconf automake libtool zip flex byacc time graphviz libsuitesparse-dev \
libmotif-dev make libxml++2.6-dev libglibmm-2.4-dev texlive-font-utils \
openjdk-17-jdk cmake git ghostscript libfl-dev wget
ENV MAKE_ARGS=-j4

# Install Meddly
RUN git clone https://github.com/asminer/meddly.git meddly && \
cd meddly && \
git checkout v0.17.0 && \
./autogen.sh && \
./configure --prefix=/usr/local && \
make ${MAKE_ARGS} && \
sudo make install

# Add Meddly to environment paths
ENV C_INCLUDE_PATH="/usr/local/include:$C_INCLUDE_PATH"
ENV LIBRARY_PATH="/usr/local/lib:$LIBRARY_PATH"
ENV LD_LIBRARY_PATH="/usr/local/lib:$LD_LIBRARY_PATH"

# Install SPOT for now no
#RUN wget http://www.lrde.epita.fr/dload/spot/spot-2.9.6.tar.gz && \
#    tar xzf spot-2.9.6.tar.gz && \
#    cd spot-2.9.6 && \
#    ./configure --disable-python --disable-debug && \
#    make ${MAKE_ARGS} && \
#    sudo make install

# Install OGDF
RUN for i in 1 2 3; do \
git clone https://github.com/ogdf/ogdf.git && break || sleep 5; \
done && \
cd ogdf && \
mkdir build && cd build && \
cmake .. && \
make ${MAKE_ARGS} && \
sudo make install

# Install lp_solve
RUN wget -O lp_solve_5.5.2.11_source.tar.gz "https://downloads.sourceforge.net/project/lpsolve/lpsolve/5.5.2.11/lp_solve_5.5.2.11_source.tar.gz?viasf=1" && \
wget https://raw.githubusercontent.com/LorenzoChiabrando/SOURCES/master/contrib/build_lpsolve.sh && \
tar xzf lp_solve_5.5.2.11_source.tar.gz && \
chmod +x ./build_lpsolve.sh && \
/bin/bash ./build_lpsolve.sh


# Install GreatSPN
RUN mkdir ~/GreatSPN && \
cd ~/GreatSPN && \
for i in {1..5}; do git clone https://github.com/qBioTurin/SOURCESgreatspn.git SOURCES && break || sleep 5; done && \
cd ~/GreatSPN/SOURCES && \
make ${MAKE_ARGS} -k derived_objects && \
make ${MAKE_ARGS} && \
sudo make install

#================================================================================
# Stage 2: prepare the deployment image with the non-devel packages
#================================================================================
FROM r-base:4.2.2 AS deploy_base

RUN apt-get update ; apt-get install -y sudo adduser apt-utils byacc
# RUN /usr/sbin/adduser --disabled-password --gecos '' docker
RUN /usr/sbin/adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER docker
WORKDIR /home/docker

RUN sudo apt-get install -y gcc g++ libgmp10 libgmpxx4ldbl \
flexc++ python3 libglpk40 \
flex time graphviz bison libglpk-dev \
make openjdk-17-jre git ghostscript


#================================================================================
# Stage 3: Update the GreatSPN framework by pulling/remaking the latest changes
#================================================================================
FROM builder AS updater

ARG update_version
RUN cd ~/GreatSPN/SOURCES && \
git pull && \
make ${MAKE_ARGS} -k derived_objects && \
make ${MAKE_ARGS} && \
sudo make install

#================================================================================
# Stage 4: Copy the compiled binaries into the deployment image
#================================================================================
FROM deploy_base

# Copia i binari compilati
COPY --from=updater /usr/local/GreatSPN /usr/local/GreatSPN
COPY --from=updater /usr/local/lib /usr/local/lib
RUN sudo rm -rf /usr/local/lib/*.a /usr/local/lib/*.la

# Aggiungi i percorsi delle librerie e dei binari
RUN echo '/usr/local/lib' | sudo tee /etc/ld.so.conf.d/greatspn.conf && sudo ldconfig
ENV PATH="$PATH:/usr/local/GreatSPN/scripts"

