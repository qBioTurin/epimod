# epimod-calibration
FROM r-base

# Imposta la modalità non interattiva
ENV DEBIAN_FRONTEND=noninteractive

# Installa le dipendenze di sistema necessarie
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    libjpeg-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Installa i pacchetti R richiesti, incluso 'remotes' al posto di 'devtools'
RUN R -e "install.packages(c('fdatest','GenSA','dplyr','tidyr','remotes'), repos='https://cloud.r-project.org')"

# Crea le cartelle necessarie con i permessi corretti
RUN mkdir -p /home/docker/scratch && chmod 777 /home/docker/scratch && \
    mkdir -p /home/docker/data && chmod 777 /home/docker/data

# Installa il pacchetto 'epimod' da GitHub utilizzando remotes
RUN R -e "remotes::install_github('qBioTurin/epimod', ref='epimod_pFBA', dependencies=TRUE)"

# Salva l'elenco dei pacchetti installati (utile per il debug)
RUN dpkg -l > /PKG_LIST

# Installa ulteriori utilità
RUN apt-get update && apt-get install -y --no-install-recommends sudo adduser apt-utils && \
    rm -rf /var/lib/apt/lists/*

# Comando di default
CMD ["bash"]

