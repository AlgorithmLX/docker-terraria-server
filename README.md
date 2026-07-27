# Docker Terraria Server

Docker image for a Terraria dedicated server with an environment-variable UX similar to `itzg/docker-minecraft-server`: automatic install/update at startup, persistent `/data`, generated server config, Vanilla or tModLoader mode, mod handling, healthcheck, and `docker exec` console commands.

## Quick Start

```yaml
services:
  terraria:
    image: algorithmlx/terra-srv:latest
    build: .
    ports:
      - "7777:7777/tcp"
      - "7777:7777/udp"
    environment:
      TYPE: VANILLA
      VERSION: LATEST
      WORLD_NAME: world
      AUTOCREATE: "2"
      DIFFICULTY: "0"
      MAX_PLAYERS: "8"
    volumes:
      - ./data:/data
```

```bash
docker compose up -d --build
docker compose logs -f
```

Worlds, config, bans, and tModLoader mods live under `./data`.

This image targets `linux/amd64`. Upstream tModLoader currently does not support ARM dedicated servers, and the vanilla Linux server package ships x86/x86_64 binaries.

## Server Type

Set `TYPE` to choose the server implementation.

| Variable           | Values                                                            | Default   |
|--------------------|-------------------------------------------------------------------|-----------|
| `TYPE`             | `VANILLA`, `TML`, `TMODLOADER`                                    | `VANILLA` |
| `VERSION`          | `LATEST`, `1.4.4.9`, `1449`, or a direct vanilla zip URL          | `LATEST`  |
| `TERRARIA_VERSION` | Overrides `VERSION` for vanilla                                   | empty     |
| `TML_VERSION`      | empty, `LATEST`, `v2026.05.3.0`, or a direct `tModLoader.zip` URL | empty     |
| `TML_CHANNEL`      | `stable`, `preview` for `TML_VERSION=LATEST`                      | `stable`  |
| `FORCE_REINSTALL`  | `TRUE` to reinstall on next start                                 | `FALSE`   |

Vanilla `LATEST` is resolved from Terraria's dedicated-server API. For TML, `TML_VERSION` falls back to `VERSION`, then to a modpack `tmlversion.txt`, then to `LATEST`.

## Common Settings

These variables render `/data/serverconfig.txt` when it does not exist. Set `OVERRIDE_SERVER_CONFIG=TRUE` to regenerate it on every start.

| Variable                  | Default                                     | Notes                                            |
|---------------------------|---------------------------------------------|--------------------------------------------------|
| `SERVER_CONFIG`           | `/data/serverconfig.txt`                    | Config file passed to the server                 |
| `WORLD_NAME`              | `world`                                     | Name for generated world                         |
| `WORLD`                   | auto                                        | Full `.wld` path                                 |
| `WORLD_PATH`              | `/data/worlds` or `/data/tModLoader/Worlds` | World directory                                  |
| `AUTOCREATE`              | `2`                                         | `1/small`, `2/medium`, `3/large`, `0/off`        |
| `DIFFICULTY`              | `0`                                         | `0/classic`, `1/expert`, `2/master`, `3/journey` |
| `SEED`                    | empty                                       | World seed                                       |
| `MAX_PLAYERS`             | `8`                                         | Terraria supports 1-255                          |
| `PORT`                    | `7777`                                      | Expose matching TCP and UDP ports                |
| `PASSWORD`                | empty                                       | Empty means no password                          |
| `MOTD`                    | `Welcome to Terraria`                       | Join message                                     |
| `LANGUAGE`                | `en-US`                                     | Server language                                  |
| `SECURE`                  | `1`                                         | Terraria anti-cheat setting                      |
| `UPNP`                    | `0`                                         | Usually disabled in containers                   |
| `NPC_STREAM`              | `60`                                        | `npcstream` config                               |
| `PRIORITY`                | `1`                                         | Server process priority                          |
| `WORLD_ROLLBACKS_TO_KEEP` | `2`                                         | Rolling world backups                            |
| `BANLIST`                 | `/data/banlist.txt`                         | Ban list path                                    |

Any environment variable prefixed with `CFG_` is appended as a raw config key. For example:

```yaml
environment:
  CFG_JOURNEYPERMISSION_GODMODE: "false"
  CFG_JOURNEYPERMISSION_TIME_SET_FROZEN: "false"
```

You can also append multiline config with `EXTRA_CONFIG` or mount `/data/serverconfig.extra.txt`.

## tModLoader Mods

Use `TYPE=TML` for mods.

```yaml
environment:
  TYPE: TML
  TML_VERSION: LATEST
  MODS: |
    https://example.com/CalamityMod.tmod
    https://example.com/MagicStorage.tmod
  ENABLED_MODS: |
    CalamityMod
    MagicStorage
```

Supported mod sources:

- `.tmod` files from HTTP(S), `/data`, or absolute container paths
- `.zip` files containing `.tmod`, `enabled.json`, or `install.txt`
- directories containing `.tmod`, `.zip`, `enabled.json`, or `install.txt`
- `/data/mods.txt`, one source per line, comments with `#`
- `MODS_FILE`, same format as `/data/mods.txt`

Relevant variables:

| Variable                    | Default                 | Notes                                                                                 |
|-----------------------------|-------------------------|---------------------------------------------------------------------------------------|
| `TML_SAVE_DIR`              | `/data/tModLoader`      | Passed with `-tmlsavedirectory`                                                       |
| `TML_MOD_PATH`              | `/data/tModLoader/Mods` | Used as `modpath`                                                                     |
| `MODS`                      | empty                   | Comma, semicolon, or newline separated sources                                        |
| `MODS_FILE`                 | empty                   | Source list file                                                                      |
| `MODS_SYNC`                 | `FALSE`                 | Remove previously managed mods not listed now                                         |
| `MODS_FORCE_DOWNLOAD`       | `FALSE`                 | Redownload URL sources                                                                |
| `MODS_ENABLE_ALL`           | `FALSE`                 | Generate `enabled.json` from all `.tmod` filenames                                    |
| `ENABLED_MODS`              | empty                   | Generates `enabled.json`; use internal mod names                                      |
| `ENABLED_MODS_FILE`         | empty                   | Copies an existing `enabled.json`                                                     |
| `MODPACK`                   | empty                   | Adds `modpack=<name>` to server config                                                |
| `TML_INSTALL_WORKSHOP_MODS` | `FALSE`                 | Runs tModLoader's `manage-tModLoaderServer.sh install-mods` when `install.txt` exists |

For Workshop-based modpacks, place `install.txt` and `enabled.json` in `/data`, `/data/mods.txt` sources, or a zip. The container preserves them under `TML_MOD_PATH`. If you enable `TML_INSTALL_WORKSHOP_MODS`, tModLoader's own DedicatedServerUtils script is invoked.

## tModLoader Modpacks

Use `MODPACK_SOURCE` to install a whole modpack automatically before the server starts.

```yaml
environment:
  TYPE: TML
  MODPACK_SOURCE: modpacks/MyModpack.zip
  MODPACK_NAME: MyModpack
  MODPACK_INSTALL_WORKSHOP: "TRUE"
volumes:
  - ./data:/data
```

`MODPACK_SOURCE` can be an HTTP(S) URL, an absolute container path, a `file://` path, or a path relative to `/data`. Supported archives are `.zip`, `.tar.gz`, and `.tgz`.

The expected tModLoader layout is:

```text
MyModpack/
  Mods/
    enabled.json
    install.txt
    localmod.tmod
  Worlds/
    world.wld
    world.twld
  ModConfigs/
  serverconfig.txt
  tmlversion.txt
```

The installer also accepts archives where that folder is nested one level deeper. It copies:

- `Mods/*.tmod`, `Mods/enabled.json`, `Mods/install.txt`, `Mods/tmlversion.txt`, and `Mods/ModPacks/`
- `Worlds/` into `TML_SAVE_DIR/Worlds` when `MODPACK_APPLY_WORLDS=TRUE`
- `ModConfigs/` into `TML_SAVE_DIR/ModConfigs` when `MODPACK_APPLY_CONFIGS=TRUE`
- root `tmlversion.txt`, which is used for `TML_VERSION` when `MODPACK_USE_TML_VERSION=TRUE`
- root `serverconfig.txt` only when `MODPACK_APPLY_SERVER_CONFIG=TRUE`

Relevant variables:

| Variable                      | Default            | Notes                                                         |
|-------------------------------|--------------------|---------------------------------------------------------------|
| `MODPACK_SOURCE`              | empty              | URL, zip/tar archive, or directory to install                 |
| `MODPACK_NAME`                | empty              | Overrides detected modpack name                               |
| `MODPACK_SYNC`                | `FALSE`            | Removes files previously installed by another modpack         |
| `MODPACK_USE_TML_VERSION`     | `TRUE`             | Uses `tmlversion.txt` when `TML_VERSION` is unset or `LATEST` |
| `MODPACK_INSTALL_WORKSHOP`    | `TRUE`             | Runs TML `install-mods` when `install.txt` exists             |
| `MODPACK_APPLY_WORLDS`        | `TRUE`             | Copies worlds from the modpack                                |
| `MODPACK_APPLY_CONFIGS`       | `TRUE`             | Copies mod config files                                       |
| `MODPACK_APPLY_SERVER_CONFIG` | `FALSE`            | Copies root `serverconfig.txt`                                |
| `STEAMCMD_AUTO_INSTALL`       | `TRUE`             | Downloads SteamCMD bootstrap when Workshop mods need it       |
| `STEAMCMD_DIR`                | `/server/steamcmd` | SteamCMD install directory                                    |

To apply a modpack `serverconfig.txt` over an existing generated config:

```yaml
environment:
  MODPACK_APPLY_SERVER_CONFIG: "TRUE"
  OVERRIDE_SERVER_CONFIG: MODPACK
```

There is also a ready-to-edit example in `docker-compose.modpack.yaml`.

## Console Commands

Terraria has no built-in RCON like Minecraft. This image exposes a command FIFO instead:

```bash
docker exec terraria send-command "say Hello from Docker"
docker exec terraria send-command "save"
docker exec terraria send-command "exit"
```

Set `ENABLE_COMMAND_PIPE=FALSE` to run the server directly on container stdin instead.

## Permissions

By default, the server runs as UID/GID `1000:1000`.

```yaml
environment:
  TERRARIA_UID: "1000"
  TERRARIA_GID: "1000"
```

Legacy `UID` and `GID` environment variables are also read by the entrypoint when present.

## Updating

Restart the container to let `VERSION=LATEST` or `TML_VERSION=LATEST` resolve the current upstream release. Set `FORCE_REINSTALL=TRUE` once if you need to reinstall the server files even when the resolved version did not change.
