FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    ca-certificates \
    python3-pip \
    && python3 -m pip install --no-cache-dir ansible-core==2.17.14 \
    && ansible-galaxy collection install ansible.posix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/memory
COPY memory/inventory.ini ./
COPY memory/host_vars ./host_vars
COPY memory/group_vars ./group_vars
COPY memory/server ./server
COPY memory/client ./client
COPY docker/memory/entrypoint.sh /usr/local/bin/memory-installer
RUN sed -i 's/\r$//' /usr/local/bin/memory-installer && chmod +x /usr/local/bin/memory-installer

ENTRYPOINT ["/usr/local/bin/memory-installer"]
