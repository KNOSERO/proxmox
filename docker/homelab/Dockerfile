FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    openssh-client \
    ca-certificates \
    && python3 -m pip install --no-cache-dir ansible-core==2.17.14 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/homelab
COPY homelab ./homelab
COPY docker/homelab/entrypoint.sh /usr/local/bin/homelab-installer
RUN sed -i 's/\r$//' /usr/local/bin/homelab-installer \
    && chmod +x /usr/local/bin/homelab-installer

ENTRYPOINT ["/usr/local/bin/homelab-installer"]
