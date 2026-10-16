[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/tyler36/ddev-anubis/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/tyler36/ddev-anubis/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/tyler36/ddev-anubis)](https://github.com/tyler36/ddev-anubis/commits)
[![release](https://img.shields.io/github/v/release/tyler36/ddev-anubis)](https://github.com/tyler36/ddev-anubis/releases/latest)

# DDEV Anubis

## Overview

This add-on integrates Anubis into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev add-on get tyler36/ddev-anubis
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and used ports for Anubis |
| `ddev logs -s anubis` | Check Anubis logs |

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.anubis --anubis-docker-image="ddev/ddev-utilities:latest"
ddev add-on get tyler36/ddev-anubis
ddev restart
```

Make sure to commit the `.ddev/.env.anubis` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `ANUBIS_DOCKER_IMAGE` | `--anubis-docker-image` | `ddev/ddev-utilities:latest` |

## Credits

**Contributed and maintained by [@tyler36](https://github.com/tyler36)**
