# Multi-stage build for HGNC MCP Server
FROM r-base:4.3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libsodium-dev \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install remotes package for installing from GitHub
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org/')"

# Set working directory
WORKDIR /build

# Copy the entire package
COPY . .

# First, explicitly install plumber and plumber2mcp since they're causing issues
RUN R -e "\
  options(repos = c(CRAN = 'https://cloud.r-project.org/')); \
  cat('Installing plumber from CRAN...\n'); \
  install.packages('plumber'); \
  cat('Installing plumber2mcp from GitHub...\n'); \
  remotes::install_github('armish/plumber2mcp', upgrade = 'never')"

# Now install all other dependencies
RUN R -e "\
  options(repos = c(CRAN = 'https://cloud.r-project.org/')); \
  cat('Installing remaining dependencies...\n'); \
  remotes::install_deps('.', dependencies = TRUE, upgrade = 'never')"

# Build and install the package itself using R CMD INSTALL
RUN R CMD INSTALL --no-multiarch --with-keep.source .

# Verify the package was installed correctly
RUN R -e "cat('Verifying installation...\n'); library(hgnc.mcp); cat('Version:', as.character(packageVersion('hgnc.mcp')), '\n')"

# Create a non-root user for running the server
RUN useradd -m hgnc && \
    mkdir -p /home/hgnc/.cache/hgnc && \
    chown -R hgnc:hgnc /home/hgnc

# Switch to non-root user
USER hgnc
WORKDIR /home/hgnc

# Set environment variables
ENV HGNC_CACHE_DIR=/home/hgnc/.cache/hgnc

# Expose the default port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD Rscript -e "tryCatch(httr::GET('http://localhost:8080/__docs__/'), error = function(e) quit(status=1))"

# Entry point - run the MCP server
CMD ["Rscript", "-e", "hgnc.mcp::start_hgnc_mcp_server(host='0.0.0.0', port=8080, swagger=TRUE)"]
