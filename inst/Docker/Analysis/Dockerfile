# epimod-analysis
FROM r-base

ENV DEBIAN_FRONTEND=noninteractive

# Aggiorna i pacchetti di sistema e installa le librerie necessarie
RUN apt update && apt install -y \
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
  libjpeg-dev

# Installa pacchetti R richiesti
RUN R -e "install.packages('fdatest')"
RUN R -e "install.packages('devtools')" 

# Crea directory per scratch e data
RUN mkdir /home/docker/scratch && mkdir /home/docker/data
RUN chown -R 1000:1000 /home/docker/scratch /home/docker/data
RUN chmod -R 777 /home/docker/scratch /home/docker/data

# Installa epimod da GitHub
RUN R -e "devtools::install_github('qBioTurin/epimod', ref='epimod_pFBA', dependencies=TRUE)"

# Dump dei pacchetti installati con le versioni
RUN dpkg -l > /PKG_LIST

# Installa altri pacchetti necessari
RUN apt-get install -y sudo adduser apt-utils

# Definisci il comando predefinito
CMD ["bash"]

