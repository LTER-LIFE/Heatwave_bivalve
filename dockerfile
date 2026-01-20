FROM rocker/r-base:4.3.2

# System dependencies (add more if your package needs them)
RUN apt-get update && apt-get install -y \
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages needed to install from GitHub
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org')"

# Install your GitHub R package
# (replace USERNAME and PACKAGENAME)
RUN R -e "remotes::install_github('USERNAME/PACKAGENAME')"

# Set working directory
WORKDIR /work

# Default command
CMD ["R"]
