# epimod_calibration
FROM ubuntu:19.10

ENV DEBIAN_FRONTEND noninteractive

# Install base system and devel tools
RUN apt update && \
  apt -y upgrade && \
  apt install -y r-base &&\
  apt install -y locales

RUN locale-gen en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

# Create scratch directory
RUN mkdir /root/scratch; chmod 777 /root/scratch

# Create data directory
RUN mkdir /root/data; chmod 777 /root/data


# Install all required R packages
RUN R -e "install.packages('GenSA')"

COPY R_scripts /root/scratch/R_scripts
COPY epimod.tar.gz /root/scratch/epimod.tar.gz
COPY Files /root/scratch/Files

RUN R -e "install.packages('/root/scratch/epimod.tar.gz',  repos = NULL)"

# Dump all packages installed with it's version
RUN dpkg -l > /PKG_LIST

# Define default command.
CMD ["bash"]
