FROM rocker/r-base:4.3.2

## ---- system dependencies (adjust if needed) ----
RUN apt-get update && apt-get install -y \
    git \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

## ---- working directory ----
WORKDIR /opt

## ---- clone tempSED from GitHub ----
RUN git clone https://github.com/TempSED/TempSED.git /opt/TempSED

## ---- clean unneeded files from TempSED source ----
# Remove vignettes and build directories to save space
RUN rm -rf /opt/TempSED/vignettes
RUN rm -rf /opt/TempSED/build

# Install all R packages in a single command
RUN R -e "install.packages(c('remotes', 'deSolve', 'rootSolve', 'ReacTran', 'plot3D'), repos='https://cloud.r-project.org', dependencies=TRUE)"

## ---- install TempSED from local source ----
RUN R CMD build --no-build-vignettes /opt/TempSED
RUN R CMD INSTALL TempSED_*.tar.gz

## ---- VERIFY installation ----
RUN R -e "\
cat('Checking TempSED installation...\\n'); \
library(TempSED); \
cat('TempSED loaded successfully\\n'); \
cat('Installed at:\\n'); \
print(find.package('TempSED'))"

# Set working directory
WORKDIR /work

# Default command
CMD ["R"]
