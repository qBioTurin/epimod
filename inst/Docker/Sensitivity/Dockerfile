# ---------- epimod-sensitivity ----------
FROM r-base

ENV DEBIAN_FRONTEND=noninteractive

# 2) System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev  libssl-dev        libssh2-1-dev  libxml2-dev \
        libglpk-dev           libharfbuzz-dev   libfribidi-dev libfontconfig1-dev \
        libc6-dev             libglib2.0-dev    libfreetype6-dev libpng-dev \
        libtiff5-dev          libjpeg-dev       libudunits2-dev libgdal-dev \
        libcairo2-dev         sudo              adduser         apt-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3) R packages
# Installa il pacchetto 'epimod' da GitHub utilizzando remotes

RUN R -e "\
  install.packages(c('remotes','fdatest','ggplot2','epiR','tidyr'), \
             repos='https://cloud.r-project.org');\
  cat('\n-- Check remotes install: --\n');\
  cat('remotes path:', system.file(package='remotes'), '\\n');\
  remotes::install_github('qBioTurin/epimod', ref='epimod_pFBA', dependencies=TRUE);\
"

# 4) Runtime directories
RUN mkdir -p /home/docker/{scratch,data} && chmod -R 777 /home/docker


# Salva l'elenco dei pacchetti installati (utile per il debug)
RUN dpkg -l > /PKG_LIST

# Installa ulteriori utilità
RUN apt-get update && apt-get install -y --no-install-recommends sudo adduser apt-utils && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y libabsl-dev

RUN R -e "install.packages('epiR');\
  cat('remotes path:', system.file(package='epiR'), '\\n')"

CMD ["bash"]
