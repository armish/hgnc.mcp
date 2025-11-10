# Multi-stage build for HGNC MCP Server using Miniconda
# This approach uses pre-compiled conda packages from conda-forge, avoiding
# cross-compilation issues with QEMU for ARM64 builds
FROM continuumio/miniconda3:latest

# Install mamba for faster package resolution and installation
RUN conda install -n base -c conda-forge mamba -y && \
    conda clean --all -f -y

# Create conda environment with R and dependencies from conda-forge
# Install only packages available in conda-forge; others will be installed via CRAN
RUN mamba create -n hgnc-mcp -c conda-forge -y \
    r-base=4.3.* \
    r-devtools \
    r-remotes \
    r-roxygen2 \
    r-plumber \
    r-httr \
    r-jsonlite \
    r-dplyr \
    r-tidyr \
    r-readr \
    r-stringr \
    r-curl \
    r-testthat \
    git \
    && mamba clean --all -f -y

# Activate conda environment
ENV PATH=/opt/conda/envs/hgnc-mcp/bin:$PATH \
    CONDA_DEFAULT_ENV=hgnc-mcp \
    CONDA_PREFIX=/opt/conda/envs/hgnc-mcp


# Install additional R packages not available in conda-forge via CRAN
# These are typically test/development packages not needed for runtime
RUN Rscript -e "install.packages(c('covr'), repos='https://cloud.r-project.org/', dependencies=TRUE)"

# Set working directory
WORKDIR /build

# Copy the entire package
COPY . .

# Install plumber2mcp from GitHub
RUN Rscript -e "remotes::install_github('armish/plumber2mcp', upgrade = 'never', force = TRUE)"

# Install the hgnc.mcp package and its remaining dependencies
RUN Rscript -e "remotes::install_deps('.', dependencies = TRUE, upgrade = 'never')" && \
    R CMD INSTALL --no-multiarch --with-keep.source .

# Verify the package was installed correctly
RUN Rscript -e "cat('Verifying installation...\n'); library(hgnc.mcp); cat('Version:', as.character(packageVersion('hgnc.mcp')), '\n')"

# Create a non-root user for running the server
RUN useradd -m -s /bin/bash hgnc && \
    mkdir -p /home/hgnc/.cache/hgnc && \
    chown -R hgnc:hgnc /home/hgnc

# Switch to non-root user
USER hgnc
WORKDIR /home/hgnc

# Set environment variables
ENV HGNC_CACHE_DIR=/home/hgnc/.cache/hgnc

# Expose the default port
EXPOSE 8080

# Health check using the conda environment's Rscript
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD ["/opt/conda/envs/hgnc-mcp/bin/Rscript", "-e", "tryCatch(httr::GET('http://localhost:8080/__docs__/'), error = function(e) quit(status=1))"]

# Entry point - run the MCP server using the conda environment's Rscript
CMD ["/opt/conda/envs/hgnc-mcp/bin/Rscript", "-e", "hgnc.mcp::start_hgnc_mcp_server(host='0.0.0.0', port=8080, swagger=TRUE)"]
