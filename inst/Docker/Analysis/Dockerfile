# Usa l'immagine ufficiale di R come base
FROM r-base

# Imposta la modalità non interattiva per evitare prompt durante la build
ENV DEBIAN_FRONTEND=noninteractive

# Installa le dipendenze di sistema necessarie
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    pkg-config \
    autoconf \
    automake \
    libtool \
    autopoint \
    file \
    libgit2-dev \
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
    libx11-dev \
    libxt-dev \
    libxext-dev \
    libxrender-dev \
    libxft-dev \
    libicu-dev \
    zlib1g-dev \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Installa i pacchetti R necessari e il pacchetto 'epimod' da GitHub tramite remotes
RUN R -e "\
  install.packages('fdatest', repos='https://cloud.r-project.org');\
  install.packages('remotes', repos='https://cloud.r-project.org', dependencies=c('Depends','Imports'));\
  cat('\n-- Check remotes install: --\n');\
  library(remotes);\
  cat('remotes path:', system.file(package='remotes'), '\\n');\
  remotes::install_github('qBioTurin/epimod', ref='epimod_pFBA', dependencies=TRUE);\
"

# Crea le cartelle necessarie con i permessi adeguati
RUN mkdir -p /home/docker/scratch && chmod 777 /home/docker/scratch
RUN mkdir -p /home/docker/data && chmod 777 /home/docker/data

# Salva l'elenco dei pacchetti installati (utile per debugging)
RUN dpkg -l > /PKG_LIST

# Installa ulteriori utilità
RUN apt-get update && apt-get install -y sudo adduser apt-utils && rm -rf /var/lib/apt/lists/*

# Comando di default
CMD ["bash"]

