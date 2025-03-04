#!/bin/bash

# Fungsi untuk memeriksa apakah aplikasi sudah terinstal
check_installation() {
    local app_name=$1
    local command=$2
    if command -v "$command" &> /dev/null; then
        echo "$app_name sudah terinstal."
        return 0
    else
        echo "$app_name tidak ditemukan."
        return 1
    fi
}

# Fungsi untuk menginstal aplikasi
install_application() {
    local app_name=$1
    local install_command=$2
    read -p "Apakah Anda ingin menginstal $app_name? (y/n): " choice
    if [[ $choice == "y" || $choice == "Y" ]]; then
        echo "Menginstal $app_name..."
        eval "$install_command"
    else
        echo "Lewati instalasi $app_name."
    fi
}

# Periksa Homebrew
if ! check_installation "Homebrew" "brew"; then
    install_application "Homebrew" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
fi

# Periksa Python
if ! check_installation "Python" "python3"; then
    install_application "Python" "brew install python"
fi

# Periksa Node.js
if ! check_installation "Node.js" "node"; then
    install_application "Node.js" "brew install node"
fi

# Periksa PostgreSQL
if ! check_installation "PostgreSQL" "postgres"; then
    install_application "PostgreSQL" "brew install postgresql"
fi

# Periksa Git
if ! check_installation "Git" "git"; then
    install_application "Git" "brew install git"
fi

# Tentukan lokasi default untuk direktori Odoo
default_odoo_dir="$HOME/odoo"
echo "Direktori Odoo akan dibuat di: $default_odoo_dir"

# Meminta input dari pengguna untuk konfigurasi PostgreSQL
echo "Masukkan nama pengguna PostgreSQL (default: odoo):"
read db_user

echo "Masukkan password PostgreSQL:"
read -s db_password

# Membuat direktori Odoo jika belum ada
mkdir -p "$default_odoo_dir"

# Pindah ke direktori Odoo
cd "$default_odoo_dir" || { echo "Gagal masuk ke direktori $default_odoo_dir"; exit 1; }

# Mengunduh Odoo dari GitHub
echo "Mengunduh Odoo..."
git clone --depth 1 --branch 18.0 https://github.com/odoo/odoo.git

# Mengonfigurasi file odoo.conf
echo "Membuat file konfigurasi Odoo..."
config_file="$default_odoo_dir/odoo.conf"
cat <<EOF > "$config_file"
[options]
db_host = localhost
db_port = 5432
db_user = $db_user
db_password = $db_password
addons_path = $default_odoo_dir/odoo/addons,$default_odoo_dir/custom-addons
EOF

# Membuat direktori custom addons
mkdir -p "$default_odoo_dir/custom-addons"

# Menginstal dependensi Python
echo "Menginstal dependensi Python..."
python3 -m venv odoo-venv
source odoo-venv/bin/activate
pip install --upgrade pip
pip install -r "$default_odoo_dir/odoo/requirements.txt"

# Menginstal Node.js dan Less Compiler (jika belum diinstal sebelumnya)
if ! command -v node &> /dev/null; then
    brew install node
fi
npm install -g less less-plugin-clean-css

# Memberikan izin akses ke file konfigurasi
chmod 644 "$config_file"

# Menampilkan pesan sukses
echo "Odoo berhasil diunduh dan dikonfigurasi!"
echo "Anda dapat menjalankan Odoo dengan perintah berikut:"
echo "source $default_odoo_dir/odoo-venv/bin/activate && ./odoo-bin -c $config_file"