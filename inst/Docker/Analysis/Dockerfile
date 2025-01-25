# Usa una base R su Debian 11 "Bullseye" (stabile)
FROM r-base:4.2.2

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends --fix-missing \
        libcurl4-openssl-dev \
        libssl-dev \
        libssh2-1-dev \
        libxml2-dev \
        libglpk-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libfontconfig1-dev \
        libc6-dev \
        libglib2.0-dev \
        libfreetype6-dev \
        libpng-dev \
        libtiff5-dev \
        libjpeg-dev \
        libudunits2-dev \
        libgdal-dev \
        libcairo2-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install all required R packages (in un solo RUN per vedere meglio i log)
RUN R -e "install.packages(c('devtools','fdatest','ggplot2','epiR','tidyr'), repos='https://cloud.r-project.org')"

# Create scratch directory
RUN mkdir -p /home/docker/scratch && chmod 777 /home/docker/scratch

# Create data directory
RUN mkdir -p /home/docker/data && chmod 777 /home/docker/data

# Installa epimod da GitHub
RUN R -e "devtools::install_github('qBioTurin/epimod', ref='epimod_pFBA', dependencies=TRUE)"

# Dump all packages installed with their version
RUN dpkg -l > /PKG_LIST

# Installa qualche utility (se ti serve)
RUN apt-get update && apt-get install -y sudo adduser apt-utils && rm -rf /var/lib/apt/lists/*

# Define default command
CMD ["bash"]

