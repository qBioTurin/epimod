# epimod_sensitivity
FROM r-base

ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install -y libcurl4-openssl-dev libssl-dev libssh2-1-dev libxml2-dev

# Create scratch directory
RUN mkdir /root/scratch; chmod 777 /root/scratch

# Create data directory
RUN mkdir /root/data; chmod 777 /root/data

# Install all required R packages
RUN R -e "install.packages('ggplot2')"
RUN R -e "install.packages('devtools')"
COPY marker /dev/null # date > marker
RUN R -e "library(devtools);install_github('qBioTurin/epimod', ref='master',dependencies=TRUE)"

# Dump all packages installed with it's version
RUN dpkg -l > /PKG_LIST

# Define default command.
CMD ["bash"]
