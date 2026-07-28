FROM debian:bookworm-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG TARGETARCH
ARG TERRARIA_UID=1000
ARG TERRARIA_GID=1000

RUN if [[ -n "${TARGETARCH}" && "${TARGETARCH}" != "amd64" ]]; then \
      echo "Terraria dedicated server and tModLoader are supported by this image on linux/amd64 only"; \
      exit 1; \
    fi

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      coreutils \
      curl \
      file \
      findutils \
      gosu \
      jq \
      libc6-i386 \
      lib32gcc-s1 \
      lib32stdc++6 \
      libcurl4 \
      libgcc-s1 \
      libgssapi-krb5-2 \
      libicu72 \
      libssl3 \
      libstdc++6 \
      procps \
      tar \
      tzdata \
      unzip \
      xz-utils \
      zlib1g \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid "${TERRARIA_GID}" terraria \
    && useradd --uid "${TERRARIA_UID}" --gid terraria --home-dir /home/terraria --create-home --shell /bin/bash terraria \
    && mkdir -p /data /server /image/scripts /tmp/terraria \
    && chown -R terraria:terraria /data /server /tmp/terraria /home/terraria

COPY --chmod=755 scripts/ /image/scripts/

RUN ln -s /image/scripts/send-command /usr/local/bin/send-command

EXPOSE 7777/tcp 7777/udp
VOLUME ["/data"]
WORKDIR /data
STOPSIGNAL SIGTERM

ENV TYPE=VANILLA \
    VERSION=LATEST \
    TERRARIA_VERSION= \
    TML_VERSION= \
    TML_CHANNEL=stable \
    PORT=7777 \
    WORLD_NAME=world \
    WORLD= \
    WORLD_PATH= \
    AUTOCREATE=2 \
    DIFFICULTY=0 \
    MAX_PLAYERS=8 \
    PASSWORD= \
    MOTD="Welcome to Terraria" \
    LANGUAGE=en-US \
    SECURE=1 \
    UPNP=0 \
    NPC_STREAM=60 \
    PRIORITY=1 \
    WORLD_ROLLBACKS_TO_KEEP=2 \
    BANLIST=/data/banlist.txt \
    SERVER_CONFIG=/data/serverconfig.txt \
    OVERRIDE_SERVER_CONFIG=FALSE \
    FORCE_REINSTALL=FALSE \
    ENABLE_COMMAND_PIPE=TRUE \
    CONSOLE_FIFO=/tmp/terraria/console.fifo \
    MODS= \
    MODS_FILE= \
    MODS_SYNC=FALSE \
    MODS_FORCE_DOWNLOAD=FALSE \
    MODS_ENABLE_ALL=FALSE \
    ENABLED_MODS= \
    ENABLED_MODS_FILE= \
    MODPACK= \
    MODPACK_SOURCE= \
    MODPACK_NAME= \
    MODPACK_SYNC=FALSE \
    MODPACK_USE_TML_VERSION=TRUE \
    MODPACK_INSTALL_WORKSHOP=TRUE \
    MODPACK_APPLY_SERVER_CONFIG=FALSE \
    MODPACK_APPLY_WORLDS=TRUE \
    MODPACK_APPLY_CONFIGS=TRUE \
    VANILLA_INSTALL_DIR=/data/server/vanilla \
    TML_INSTALL_DIR=/data/server/tModLoader \
    TML_MANAGE_SCRIPT_REF=stable \
    TML_MANAGE_SCRIPT_URL= \
    TML_MANAGE_SCRIPT_FORCE_DOWNLOAD=FALSE \
    TML_SAVE_DIR=/data/tModLoader \
    TML_MOD_PATH=/data/tModLoader/Mods \
    TML_INSTALL_WORKSHOP_MODS=FALSE \
    STEAM_LOBBY=NONE \
    STEAM_WORKSHOP_FOLDER= \
    STEAMCMD_AUTO_INSTALL=TRUE \
    STEAMCMD_DIR=/data/server/steamcmd \
    STEAMCMD_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz \
    EXTRA_ARGS= \
    EXTRA_CONFIG=

HEALTHCHECK --start-period=120s --interval=30s --timeout=5s --retries=3 CMD ["/image/scripts/healthcheck"]

ENTRYPOINT ["/image/scripts/entrypoint"]
