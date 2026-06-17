# epimod-display
FROM rocker/shiny

ENV DEBIAN_FRONTEND noninteractive

# 2) System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev  libssl-dev        libssh2-1-dev  libxml2-dev \
        libglpk-dev           libharfbuzz-dev   libfribidi-dev libfontconfig1-dev \
        libc6-dev             libglib2.0-dev    libfreetype6-dev libpng-dev \
        libtiff5-dev          libjpeg-dev       libudunits2-dev libgdal-dev \
        libcairo2-dev         sudo              adduser         apt-utils \
        libuv1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install all required R packages (one per layer for easier debugging)
RUN R -e "install.packages('shinyWidgets')"
RUN R -e "install.packages('colourpicker')"
RUN R -e "install.packages('shinyFiles')"
RUN R -e "install.packages('bslib')"
RUN R -e "install.packages('dplyr')"
RUN R -e "install.packages('ggplot2')"
RUN R -e "install.packages('tidyr')"
RUN R -e "install.packages('ggnewscale')"
RUN R -e "install.packages('RColorBrewer')"
RUN R -e "install.packages('ggsci')"
RUN R -e "install.packages('wesanderson')"
RUN R -e "install.packages('MetBrewer')"
RUN R -e "install.packages('scico')"
RUN R -e "install.packages('viridis')"
RUN R -e "install.packages('scales')"
RUN R -e "install.packages('epiR')"


# Create app and data directories
RUN mkdir -p /srv/shiny-server/display/data

# Copy the shinyApp app files
# NOTE: before building, copy server.R, ui.R, R/ and www/ from the
# shinyApp project into this directory (inst/Containers/Display/)
# so they are available in the Docker build context.
COPY shinyApp/server.R /srv/shiny-server/display/
COPY shinyApp/ui.R /srv/shiny-server/display/
COPY shinyApp/R/ /srv/shiny-server/display/R/
COPY shinyApp/www/ /srv/shiny-server/display/www/

# Dump all packages installed with their versions
RUN dpkg -l > /PKG_LIST

# Remove unnecessary default apps
RUN rm -rf /srv/shiny-server/sample-apps
RUN rm /srv/shiny-server/index.html

# Define default command.
CMD ["/init"]
