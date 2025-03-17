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

# Periksa dan instal wkhtmltopdf
if ! command -v wkhtmltopdf &> /dev/null; then
    echo "Menginstal wkhtmltopdf..."
    brew install wkhtmltopdf
fi

# Tentukan lokasi default untuk direktori Odoo
default_odoo_dir="$HOME/odoo"
echo "Direktori Odoo akan dibuat di: $default_odoo_dir"

# Set konfigurasi PostgreSQL secara statis
db_user="openpg"
db_password="openpgpwd"
echo "Menggunakan nama pengguna PostgreSQL: $db_user"
echo "Menggunakan password PostgreSQL: $db_password"

# Membuat direktori Odoo jika belum ada
mkdir -p "$default_odoo_dir"

# Pindah ke direktori Odoo
cd "$default_odoo_dir" || { echo "Gagal masuk ke direktori $default_odoo_dir"; exit 1; }

# Mengunduh Odoo dari GitHub jika belum ada
if [ ! -d "odoo" ]; then
    echo "Mengunduh Odoo..."
    git clone --depth 1 --branch 18.0 https://github.com/odoo/odoo.git
else
    echo "Direktori Odoo sudah ada, melewati proses unduh..."
fi

# Memastikan PostgreSQL berjalan
echo "Memastikan PostgreSQL berjalan..."
if ! brew services list | grep postgresql | grep started > /dev/null; then
    echo "Menjalankan PostgreSQL..."
    brew services start postgresql
    # Tunggu beberapa detik sampai PostgreSQL siap
    sleep 5
else
    echo "PostgreSQL sudah berjalan"
fi

# Membuat user PostgreSQL dengan penanganan error yang lebih baik
echo "Membuat user PostgreSQL..."
# Mendapatkan username sistem saat ini
current_user=$(whoami)

# Mencoba membuat user PostgreSQL dengan berbagai metode
create_pg_user() {
    # Coba dengan user sistem saat ini
    psql postgres -c "CREATE USER $db_user WITH SUPERUSER PASSWORD '$db_password';" 2>/dev/null || \
    # Coba dengan postgres user
    psql -U postgres -c "CREATE USER $db_user WITH SUPERUSER PASSWORD '$db_password';" 2>/dev/null || \
    # Coba dengan sudo
    sudo -u $current_user createuser -s $db_user 2>/dev/null || \
    sudo -u postgres createuser -s $db_user 2>/dev/null
    
    # Set password
    psql postgres -c "ALTER USER $db_user WITH PASSWORD '$db_password';" 2>/dev/null || \
    psql -U postgres -c "ALTER USER $db_user WITH PASSWORD '$db_password';" 2>/dev/null || \
    sudo -u $current_user psql postgres -c "ALTER USER $db_user WITH PASSWORD '$db_password';" 2>/dev/null
}

# Cek apakah user sudah ada
if ! psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$db_user'" | grep -q 1; then
    echo "Mencoba membuat user PostgreSQL..."
    if create_pg_user; then
        echo "User PostgreSQL berhasil dibuat"
    else
        echo "Gagal membuat user PostgreSQL secara otomatis"
        echo "Mencoba membuat database dengan user sistem saat ini..."
        # Gunakan user sistem saat ini sebagai fallback
        db_user=$current_user
        echo "Menggunakan user sistem: $db_user"
    fi
else
    echo "User PostgreSQL sudah ada"
fi

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
http_port = 8069
http_interface = 0.0.0.0
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
echo "Menjalankan Odoo..."
echo "Setelah server berjalan, akses Odoo melalui browser di: http://localhost:8069"
echo "Tekan Ctrl+C untuk menghentikan server"
echo ""

# Pindah ke direktori Odoo dan jalankan
cd "$default_odoo_dir/odoo" && \
source "$default_odoo_dir/odoo-venv/bin/activate" && \
echo "Virtual environment diaktifkan, menjalankan Odoo..." && \
python3 ./odoo-bin -c "$default_odoo_dir/odoo.conf"