FROM nextcloud:33.0-apache@sha256:0b14848e05d19aa25e8a189eb9cfef4215489e0cbf5eb999e8784bf03027c226

USER root

RUN apt-get update && apt-get install -y \
    libsmbclient-dev \
    smbclient \
    && rm -rf /var/lib/apt/lists/*

RUN pecl install smbclient && \
    docker-php-ext-enable smbclient

USER www-data