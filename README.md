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
| Proxmox VE | 8 | Legacy (end of support, bootstrap only with warning) |

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

## Webstack installation

`webstack_install` installs PHP-FPM and common PHP extensions for general hosting
or Nextcloud prerequisites on vanilla Debian 12/13. It reuses `lib/common.sh`.
Run without arguments for a menu, or use explicit options for automation:

```bash
sudo bash webstack_install install --web nginx --php 8.4 --database mariadb
sudo bash webstack_install install --profile nextcloud --php 8.4 --database mariadb --cache redis
sudo bash webstack_install install --web apache --database postgresql --extras
sudo bash webstack_install install --web none --cache none
bash webstack_install --help
```

Defaults: general profile, Nginx, Debian's default PHP version, no local database,
and Redis. All installations include PHP CLI/FPM, OPcache, APCu, curl, GD, intl,
mbstring, XML and ZIP. Database drivers follow the selected database; with
`--database none`, MySQL, PostgreSQL and SQLite drivers support external databases.
Database CLI clients are explicit: `--db-client auto` (default) installs the
client matching the local server, or both `mariadb-client` and `postgresql-client`
when `--database none` is used. Override with `mariadb`, `postgresql`, `both` or
`none`; this does not change PHP drivers or install a database server.
For example, a remote PostgreSQL database:

```bash
sudo bash webstack_install install --profile nextcloud --php 8.4 --database none --db-client postgresql
```

`--extras` adds BCMath, GMP, Imagick, LDAP, IMAP and SOAP. The Nextcloud profile
includes BCMath, GMP and Imagick and uses 512 MB PHP memory/upload limits.

Select a PHP version compatible with the application release. The Nextcloud
profile currently accepts PHP 8.3–8.5; Debian 12's default PHP 8.2 requires selecting
a newer version from already configured repositories. Missing packages stop the
installation. Use `repo_manage` separately when upstream repositories are needed.

Only `/etc/php/X.Y/mods-available/help24-webstack.ini` is managed; PHP-FPM is
validated and reloaded. Existing FPM pools and `php.ini` are preserved. Apache
is connected to the selected FPM version; Nginx requires a per-site FastCGI
configuration using the socket printed by the script. An installed alternative
web server blocks installation to avoid a default port conflict.

This prepares services, not a finished site: configure virtual hosts, TLS,
database users, Nextcloud's `config.php` caches and cron separately. Web server
upload limits must match PHP. Redis and database settings are left at the
existing distribution configuration. APCu and Redis need application-level
configuration; installing them alone does not activate Nextcloud caching.
APCu is shared by applications in the same FPM pool: use separate pools/users
when hosting unrelated customers.

The bootstrap deploys this script to `/opt/help24/bin/webstack_install`.
Failures return a nonzero exit code. Package installation is not transactional:
if a later step fails, packages installed earlier remain present.

## Administration Scripts

> **Planned:** the `scripts/` directory and `user_admin_create` are not yet part of this repository.

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
