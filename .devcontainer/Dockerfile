# Use GitHub's default Ubuntu base for Codespaces
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install Julia (adjust version if needed)
RUN apt-get update && apt-get install -y wget tar \
    && wget https://julialang-s3.julialang.org/bin/linux/x64/1.11/julia-1.11.3-linux-x86_64.tar.gz \
    && tar -xvzf julia-1.11.3-linux-x86_64.tar.gz \
    && mv julia-1.11.3 /usr/local/julia \
    && ln -s /usr/local/julia/bin/julia /usr/local/bin/julia \
    && rm julia-1.11.3-linux-x86_64.tar.gz
