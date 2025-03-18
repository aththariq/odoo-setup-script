# Odoo 18.0 Installation Script for macOS

This script automates the installation and configuration of Odoo 18.0 on macOS systems.

## Prerequisites

The script will check and install these requirements if not present:

- Homebrew
- Python 3.10 or newer (the script will try to install or update Python if needed)
- PostgreSQL
- Node.js
- Git
- wkhtmltopdf

## Installation

Run the following command in Terminal:

```bash
curl -LO https://raw.githubusercontent.com/aththariq/odoo-setup-script/refs/heads/main/setup_odoo.sh && chmod +x setup_odoo.sh && ./setup_odoo.sh
```

## What the Script Does

1. Checks and installs required dependencies
2. Creates Odoo directory at `~/odoo`
3. Clones Odoo 18.0 from official repository
4. Sets up PostgreSQL user and database
5. Configures Odoo with proper settings
6. Creates Python virtual environment
7. Installs all required Python packages
8. Starts Odoo server automatically

## Accessing Odoo

After successful installation:

1. Open your web browser
2. Visit: http://localhost:8069
3. On first access, you'll need to create a database:
   - Choose a database name
   - Set master password
   - Select language
   - Fill in company information

## Running Odoo

The script will automatically start Odoo after installation. For subsequent runs:

```bash
cd ~/odoo/odoo && source ~/odoo/odoo-venv/bin/activate && python3 ./odoo-bin -c ~/odoo/odoo.conf
```

## Default Configuration

- Odoo Web Interface: http://localhost:8069
- PostgreSQL User: openpg (or your system username if automatic creation fails)
- PostgreSQL Password: openpgpwd
- Addons Path:
  - ~/odoo/odoo/addons
  - ~/odoo/custom-addons

## Troubleshooting

If you encounter issues:

1. Ensure PostgreSQL is running:
   ```bash
   brew services list | grep postgresql
   ```
2. Start PostgreSQL if needed:
   ```bash
   brew services start postgresql
   ```
3. Check Odoo logs in the terminal for any error messages
4. Make sure port 8069 is not being used by another application

## Stopping Odoo

To stop the Odoo server, press `Ctrl+C` in the terminal where it's running.

## Support

For issues and contributions, please visit the GitHub repository.

## Quick Start Guide (Setelah Instalasi)

Setelah menjalankan script untuk pertama kalinya, Anda tidak perlu mengunduh dan menjalankan script lagi untuk memulai Odoo di lain waktu. Cukup gunakan perintah berikut:

```bash
cd ~/odoo/odoo && source ~/odoo/odoo-venv/bin/activate && python3 ./odoo-bin -c ~/odoo/odoo.conf
```

Anda juga bisa membuat alias di file `~/.zshrc` atau `~/.bash_profile` untuk memudahkan menjalankan Odoo:

```bash
# Tambahkan baris ini ke file ~/.zshrc atau ~/.bash_profile
alias odoo-start="cd ~/odoo/odoo && source ~/odoo/odoo-venv/bin/activate && python3 ./odoo-bin -c ~/odoo/odoo.conf"
```

Setelah menambahkan alias, jalankan:

```bash
source ~/.zshrc  # atau source ~/.bash_profile
```

Kemudian Anda bisa menjalankan Odoo kapan saja cukup dengan mengetik:

```bash
odoo-start
```
