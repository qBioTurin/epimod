# epimod-analysis
FROM r-base

ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install -y libcurl4-openssl-dev libssl-dev libssh2-1-dev libxml2-dev libglpk-dev

# Install all required R packages
RUN R -e "install.packages('devtools')"
RUN R -e "install.packages('fdatest')"

# Create scratch directory
RUN mkdir /home/docker/scratch; chmod 777 /home/docker/scratch

# Create data directory
RUN mkdir /home/docker/data; chmod 777 /home/docker/data

RUN apt-get update
RUN apt-get install libc6-dev libglib2.0-dev -y

# date > marker
COPY marker /dev/null
RUN R -e "library(devtools);install_github('qBioTurin/epimod', ref='master',dependencies=TRUE)"

# Dump all packages installed with it's version
RUN dpkg -l > /PKG_LIST

# Define default command.
CMD ["bash"]
