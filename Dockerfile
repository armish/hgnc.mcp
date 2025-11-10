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

# Configure R to use RStudio Package Manager for binary packages
# This avoids compilation issues in multi-arch builds with QEMU
RUN echo 'options(repos = c(CRAN = "https://p3m.dev/cran/__linux__/jammy/latest"))' >> /usr/lib/R/etc/Rprofile.site

# Set working directory
WORKDIR /build

# Copy the entire package
COPY . .

# Install all R dependencies in a single step using binary packages
# This is much faster and avoids QEMU emulation issues
RUN R -e "\
  cat('Installing R dependencies...\n'); \
  install.packages('remotes'); \
  cat('Installing plumber from CRAN...\n'); \
  install.packages('plumber'); \
  cat('Installing plumber2mcp from GitHub...\n'); \
  remotes::install_github('armish/plumber2mcp', upgrade = 'never'); \
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
