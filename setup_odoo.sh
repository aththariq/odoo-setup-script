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

# Periksa versi Python dan update jika perlu
python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
python_required_version="3.10.0"
echo "Versi Python terdeteksi: $python_version"
echo "Versi minimal yang dibutuhkan: $python_required_version"

# Bandingkan versi menggunakan sort -V
if [ "$(printf '%s\n' "$python_required_version" "$python_version" | sort -V | head -n1)" = "$python_required_version" ]; then
    echo "Versi Python sudah memenuhi syarat."
else
    echo "Versi Python terlalu lama. Memperbarui Python..."
    brew update
    brew upgrade python
    # Periksa versi Python lagi setelah update
    python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
    echo "Python diperbarui ke versi: $python_version"
    # Jika masih belum cukup, coba install Python 3.10 secara khusus
    if [ "$(printf '%s\n' "$python_required_version" "$python_version" | sort -V | head -n1)" != "$python_required_version" ]; then
        echo "Mencoba menginstal Python 3.10 secara khusus..."
        brew install python@3.10
        # Tambahkan ke PATH
        export PATH="/usr/local/opt/python@3.10/bin:$PATH"
        # Periksa kembali path python3
        which python3
        python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
        echo "Python path dan versi setelah instalasi khusus: $(which python3) - $python_version"
    fi
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

# Periksa dan instal wkhtmltopdf dengan alternatif karena discontinued di Homebrew
if ! command -v wkhtmltopdf &> /dev/null; then
    echo "Menginstal wkhtmltopdf..."
    # Menggunakan versi terbaru yang tersedia di website resmi
    WKHTML_VERSION="0.12.6-2"
    DOWNLOAD_URL="https://github.com/wkhtmltopdf/packaging/releases/download/${WKHTML_VERSION}/wkhtmltox-${WKHTML_VERSION}.macos-cocoa.pkg"
    
    # Download installer
    echo "Mengunduh wkhtmltopdf dari $DOWNLOAD_URL..."
    curl -L -o wkhtmltox.pkg "$DOWNLOAD_URL"
    
    # Install package
    echo "Menginstal wkhtmltopdf... (mungkin meminta password)"
    sudo installer -pkg wkhtmltox.pkg -target /
    
    # Bersihkan file installer
    rm wkhtmltox.pkg
    
    # Verifikasi instalasi
    if command -v wkhtmltopdf &> /dev/null; then
        echo "wkhtmltopdf berhasil diinstal."
    else
        echo "Peringatan: Instalasi wkhtmltopdf tidak berhasil. Laporan PDF mungkin tidak berfungsi."
        echo "Anda dapat menginstal secara manual dari: https://wkhtmltopdf.org/downloads.html"
    fi
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

# Dapatkan path ke Python 3.10+ yang benar
python_path=$(which python3)
echo "Menggunakan Python dari: $python_path"

# Buat virtual environment dengan Python yang benar
echo "Membuat virtual environment dengan $python_path..."
$python_path -m venv odoo-venv
source odoo-venv/bin/activate

# Verifikasi versi Python dalam virtual environment
python_venv_version=$(python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
echo "Versi Python dalam virtual environment: $python_venv_version"

pip install --upgrade pip
pip install -r "$default_odoo_dir/odoo/requirements.txt"

# Menginstal Node.js dan Less Compiler (jika belum diinstal sebelumnya)
if ! command -v node &> /dev/null; then
    brew install node
fi
npm install -g less less-plugin-clean-css

# Memberikan izin akses ke file konfigurasi
chmod 644 "$config_file"

# Tambahkan alias ke file konfigurasi shell
echo "Menambahkan alias 'odoo-start' ke file konfigurasi shell..."
alias_command="alias odoo-start=\"cd $default_odoo_dir/odoo && source $default_odoo_dir/odoo-venv/bin/activate && python3 ./odoo-bin -c $default_odoo_dir/odoo.conf\""

# Deteksi shell yang digunakan dengan pendekatan yang lebih baik
CURRENT_SHELL=$(basename "$SHELL")
echo "Shell terdeteksi: $CURRENT_SHELL"

if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    shell_config="$HOME/.zshrc"
    echo "Menambahkan alias ke $shell_config"
elif [[ "$CURRENT_SHELL" == "bash" ]]; then
    shell_config="$HOME/.bash_profile"
    echo "Menambahkan alias ke $shell_config"
else
    # Fallback ke zsh karena macOS modern menggunakan zsh sebagai default
    shell_config="$HOME/.zshrc"
    echo "Shell tidak terdeteksi, menggunakan zsh sebagai default. Menambahkan alias ke $shell_config"
fi

# Periksa apakah alias sudah ada di file konfigurasi
if grep -q "alias odoo-start=" "$shell_config" 2>/dev/null; then
    echo "Alias odoo-start sudah ada di $shell_config"
else
    # Tambahkan alias
    echo "" >> "$shell_config"
    echo "# Alias untuk menjalankan Odoo" >> "$shell_config"
    echo "$alias_command" >> "$shell_config"
    echo "Alias berhasil ditambahkan ke $shell_config"
fi

# Aktifkan alias secara otomatis dalam sesi shell saat ini
echo "$alias_command" > /tmp/odoo_alias_temp
source /tmp/odoo_alias_temp
rm /tmp/odoo_alias_temp

echo "Alias sudah ditambahkan dan diaktifkan untuk sesi ini."
echo "Untuk sesi terminal baru, mohon jalankan: source $shell_config"
echo "Selanjutnya Anda bisa langsung menjalankan Odoo dengan mengetik: odoo-start"

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