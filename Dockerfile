FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ansible \
    openssh-client \
    sshpass \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/homelab
COPY homelab ./homelab
COPY entrypoint.sh /usr/local/bin/homelab-installer
RUN chmod +x /usr/local/bin/homelab-installer

ENTRYPOINT ["/usr/local/bin/homelab-installer"]
