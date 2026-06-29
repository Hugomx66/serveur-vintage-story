FROM mcr.microsoft.com/dotnet/runtime:10.0-noble

ARG VS_VERSION=1.22.3

ENV VS_VERSION=${VS_VERSION} \
    DEBIAN_FRONTEND=noninteractive \
    VS_HOME=/srv/vintagestory \
    VS_DATA=/repo/data

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        openssh-client \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p ${VS_HOME}

RUN curl -fsSL -o /tmp/vs_server.tar.gz \
        "https://cdn.vintagestory.at/gamefiles/stable/vs_server_linux-x64_${VS_VERSION}.tar.gz" \
    && tar -xzf /tmp/vs_server.tar.gz -C ${VS_HOME} \
    && rm /tmp/vs_server.tar.gz

WORKDIR ${VS_HOME}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 42420/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
