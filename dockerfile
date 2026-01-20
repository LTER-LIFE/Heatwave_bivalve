FROM rocker/r-base:4.3.2

# System dependencies (add more if your package needs them)
RUN apt-get update && apt-get install -y \
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages needed to install from GitHub
RUN R -e "install.packages(c('remotes', 'devtools'), repos='https://cloud.r-project.org')"

# Install required R packages for TempSED
RUN R -e "install.packages(c('deSolve', 'rootSolve', 'ReacTran', 'plot3D'), repos='https://cloud.r-project.org')"

# Install TempSED package from GitHub
RUN R -e "library(devtools); install_github('TempSED/TempSED', dependencies=TRUE)"

# Set working directory
WORKDIR /work

# Default command
CMD ["R"]
