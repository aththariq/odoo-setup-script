# Odoo 18.0 Installation Script for macOS

This script automates the installation and configuration of Odoo 18.0 on macOS systems.

## Important Notes

- **Odoo 18.0 strictly requires Python 3.10 or newer**
- The script will automatically install Python 3.10 via Homebrew and configure it for Odoo
- If you have multiple Python versions installed, the script will ensure Python 3.10 is used for Odoo

## Prerequisites

The script will check and install these requirements if not present:

- Homebrew
- Python 3.10 (will be installed automatically regardless of existing Python version)
- PostgreSQL
- Node.js
- Git
- wkhtmltopdf (installed from official website since discontinued in Homebrew)

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

1. Python version issues (most common problem):

   ```bash
   # If you get "Outdated python version detected" error:
   brew install python@3.10
   brew link --force python@3.10
   echo 'export PATH="/usr/local/opt/python@3.10/bin:$PATH"' >> ~/.zshrc
   source ~/.zshrc
   # Then check your Python version:
   python3 --version  # Should show 3.10.x or newer
   # Re-run the setup script
   ```

2. Ensure PostgreSQL is running:
   ```bash
   brew services list | grep postgresql
   ```
3. Start PostgreSQL if needed:
   ```bash
   brew services start postgresql
   ```
4. If wkhtmltopdf installation fails (required for PDF reports):
   ```bash
   # Install wkhtmltopdf manually
   curl -L -o wkhtmltox.pkg "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-2/wkhtmltox-0.12.6-2.macos-cocoa.pkg"
   sudo installer -pkg wkhtmltox.pkg -target /
   ```
5. Check Odoo logs in the terminal for any error messages
6. Make sure port 8069 is not being used by another application
7. If the `odoo-start` command doesn't work:

   ```bash
   # For zsh (default in newer macOS):
   echo 'alias odoo-start="cd ~/odoo/odoo && source ~/odoo/odoo-venv/bin/activate && python3 ./odoo-bin -c ~/odoo/odoo.conf"' >> ~/.zshrc
   source ~/.zshrc

   # For bash:
   echo 'alias odoo-start="cd ~/odoo/odoo && source ~/odoo/odoo-venv/bin/activate && python3 ./odoo-bin -c ~/odoo/odoo.conf"' >> ~/.bash_profile
   source ~/.bash_profile
   ```

## Stopping Odoo

To stop the Odoo server, press `Ctrl+C` in the terminal where it's running.

## Support

For issues and contributions, please visit the GitHub repository.

## Quick Start Guide (Setelah Instalasi)

Setelah menjalankan script untuk pertama kalinya, script secara otomatis menambahkan alias `odoo-start` ke file konfigurasi shell Anda (~/.zshrc atau ~/.bash_profile) dan mengaktifkannya untuk sesi saat ini.

Untuk sesi terminal baru, aktifkan alias dengan:

```bash
# Jika menggunakan zsh (default di macOS terbaru):
source ~/.zshrc

# Jika menggunakan bash:
source ~/.bash_profile
```

Kemudian Anda bisa menjalankan Odoo kapan saja cukup dengan mengetik:

```bash
odoo-start
```

Tidak perlu lagi menjalankan script instalasi atau memasukkan perintah panjang. Cukup ketik `odoo-start` untuk menjalankan Odoo!
