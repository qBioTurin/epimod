# epimod-analysis
FROM rocker/shiny
# FROM r-base

ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install -y libcurl4-openssl-dev libssl-dev libssh2-1-dev libxml2-dev

# Install all required R packages
RUN R -e "install.packages('devtools')"
RUN R -e "install.packages('ggplot2')"
# RUN R -e "install.packages('shiny')"

# Create data directory
RUN mkdir /srv/shiny-server/display
RUN mkdir /srv/shiny-server/display/data

# date > marker
# COPY marker /dev/null
RUN R -e "library(devtools);install_github('qBioTurin/epimod', ref='master',dependencies=TRUE)"

RUN R -e "library(epimod);file.copy(paste0(path.package(package='epimod'),'/R_scripts/app.R'), '/srv/shiny-server/display')"

# Dump all packages installed with it's version
RUN dpkg -l > /PKG_LIST

# Remove unnecessary apps and pages
RUN rm -rf /srv/shiny-server/sample-apps
RUN rm /srv/shiny-server/index.html

# Define default command.
CMD ["/usr/bin/shiny-server.sh"]
