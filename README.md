# Help24 Debstrap
Bootstrap and administration tools for Debian and Proxmox VE.
**Help24 Debstrap** provides a consistent starting point for preparing Debian-based servers with essential administration tools, diagnostics, repository management and reusable automation scripts.

## Quick Start

On a fresh Debian or Proxmox VE installation, log in as root and execute:

```bash
apt-get update
apt-get install -y git ca-certificates
git clone https://github.com/help24-biz/debstrap.git
cd debstrap
bash debian_bootstrap
```

The bootstrap installs essential administration tools, creates the Help24 directory structure and deploys the available scripts.

## Supported Platforms

| Platform | Version | Support |
|----------|---------|---------|
| Debian | 13 (Trixie) | Primary |
| Debian | 12 (Bookworm) | Legacy |
| Proxmox VE | 9 | Bootstrap and administration |
| Proxmox VE | 8 | Bootstrap and administration |

> **Important:** Repository management is supported exclusively on vanilla Debian and is intentionally disabled on Proxmox VE.

## Installation Structure

The bootstrap prepares the following directory structure:

```text
/opt/help24/
├── bin/
│   ├── debian_bootstrap
│   ├── repo_manage
│   ├── user_admin_create
│   └── lib/
│       └── common.sh
├── etc/
├── log/
└── templates/
```

Available scripts from the repository are installed into `/opt/help24/bin/`.

Shared libraries are installed into `/opt/help24/bin/lib/`.

Selected commands are made available system-wide through symbolic links:

```text
/usr/local/bin/repo_manage -> /opt/help24/bin/repo_manage
```

## Debian Bootstrap

The `debian_bootstrap` script:

- Detects the operating system and supported platform.
- Updates APT package indexes.
- Installs essential administration and diagnostic utilities.
- Creates the standard Help24 directory structure.
- Installs available scripts and shared libraries.
- Creates symbolic links for selected commands.
- Supports repeated execution.

### Installed Packages

**Network and diagnostics**

`curl`, `wget`, `dnsutils`, `net-tools`, `tcpdump`, `iftop`, `htop`, `iotop`

**Administration**

`sudo`, `tmux`, `git`, `vim`, `rsync`, `bash-completion`, `less`, `tree`

**System utilities**

`gnupg`, `ca-certificates`, `lsb-release`, `unzip`, `zip`, `pciutils`, `usbutils`, `lm-sensors`, `smartmontools`

### What Bootstrap Does Not Do

The bootstrap does not:

- Modify APT repositories.
- Perform system upgrades.
- Install kernel headers or DKMS.
- Modify SSH configuration.
- Disable or modify root access.
- Create or modify user accounts.
- Change Proxmox RBAC configuration.
- Automatically remove installed packages.

## Repository Management

`repo_manage` manages selected upstream APT repositories on **vanilla Debian only**.

### Supported Repositories

| Repository | Purpose |
|------------|---------|
| Sury | PHP packages |
| Nginx | Stable and mainline packages |
| MariaDB | Upstream MariaDB packages |
| PostgreSQL PGDG | PostgreSQL packages |

### Interactive Mode

```bash
sudo repo_manage
```

### Command-Line Mode

```bash
sudo repo_manage sury enable
sudo repo_manage nginx enable stable
sudo repo_manage nginx enable mainline
sudo repo_manage postgresql enable
sudo repo_manage all check
sudo repo_manage all update
```

MariaDB repository configuration requires an explicit version and verification of the official repository setup utility.

Enabling a repository does not automatically install or upgrade its associated software.

> **Proxmox VE:** Repository management is explicitly blocked to protect Proxmox package dependencies and repository configuration.

## Administration Scripts

Additional administration scripts are maintained in the `scripts/` directory.

During bootstrap, available scripts are installed into:

```text
/opt/help24/bin/
```

Example:

```bash
sudo /opt/help24/bin/user_admin_create
```

Administration scripts may support both Debian and Proxmox VE, depending on their purpose.

## Shared Libraries

Reusable Bash functions are maintained in:

```text
lib/common.sh
```

The library provides:

- Logging and error reporting.
- Root privilege checks.
- Command availability checks.
- Operating system detection.
- Debian and Proxmox version detection.
- Platform-specific safety checks.

Installed scripts use:

```text
/opt/help24/bin/lib/common.sh
```

## Updating

Update the local Git checkout and rerun the bootstrap:

```bash
cd debstrap
git pull --ff-only
sudo bash debian_bootstrap
```

The bootstrap updates the installed Help24 scripts and libraries while preserving existing configuration directories.

## Design Principles

Help24 Debstrap follows a few simple principles:

- **Predictable:** Consistent tools and directory structure.
- **Idempotent:** Scripts should support repeated execution.
- **Conservative:** Avoid unnecessary changes to existing systems.
- **Modular:** Independent scripts with reusable common functions.
- **Automation-ready:** Suitable for interactive and unattended use.
- **Platform-aware:** Debian and Proxmox are treated differently where required.

### Naming Convention

Bash functions and scripts follow:

```text
object_[context_]action
```

Examples:

```text
root_check
system_detect
platform_debian_check
user_admin_create
repo_manage
repo_key_refresh
```

## License

See the LICENSE file for licensing information.
