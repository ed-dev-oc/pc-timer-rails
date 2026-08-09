#!/usr/bin/env bash

set -Eeuo pipefail

APP_NAME="InternetCafe Server"
APP_VERSION="1.0.0"

DOCKER_IMAGE="eddev42525/pc_timer_rails:1.0.0"

INSTALL_DIR="/opt/internetcafe"
STORAGE_DIR="${INSTALL_DIR}/storage"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_SOURCE="${SCRIPT_DIR}/docker-compose.yml"
COMPOSE_FILE="${INSTALL_DIR}/docker-compose.yml"

REPAIR_INSTALLATION=false


# ========================================
# Output helpers
# ========================================

log() {
  echo
  echo "==> $1"
}

success() {
  echo "✓ $1"
}

error() {
  echo "✗ $1" >&2
}

fail() {
  error "$1"
  exit 1
}


# ========================================
# Basic checks
# ========================================

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    fail "Please run this installer with sudo:

  sudo ./install.sh"
  fi
}

check_linux() {
  if [[ ! -f /etc/os-release ]]; then
    fail "Unable to determine the Linux distribution."
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  case "${ID}" in
    ubuntu|debian)
      success "Supported Linux distribution: ${PRETTY_NAME}"
      ;;
    *)
      fail "Unsupported Linux distribution: ${PRETTY_NAME:-${ID}}"
      ;;
  esac
}

check_architecture() {
  local architecture

  architecture="$(uname -m)"

  case "${architecture}" in
    x86_64)
      success "Supported architecture: amd64"
      ;;
    aarch64|arm64)
      success "Supported architecture: arm64"
      ;;
    *)
      fail "Unsupported architecture: ${architecture}

InternetCafe Server currently supports:
  - amd64
  - arm64"
      ;;
  esac
}

check_command() {
  local command="$1"
  local name="$2"

  if command -v "${command}" >/dev/null 2>&1; then
    success "${name} found"
  else
    fail "${name} is required but was not found."
  fi
}


# ========================================
# Docker checks
# ========================================

check_docker() {
  check_command "docker" "Docker"

  if ! docker info >/dev/null 2>&1; then
    fail "Docker is installed but the Docker daemon is not running."
  fi

  local version
  version="$(docker version --format '{{.Server.Version}}')"

  success "Docker ${version}"
  success "Docker daemon is running"
}

check_compose() {
  if ! docker compose version >/dev/null 2>&1; then
    fail "Docker Compose is required but was not found."
  fi

  local version
  version="$(docker compose version --short)"

  success "Docker Compose ${version}"
}


# ========================================
# Internet
# ========================================

check_internet() {
  if curl \
    --silent \
    --show-error \
    --fail \
    --connect-timeout 5 \
    --max-time 10 \
    https://www.google.com >/dev/null; then

    success "Internet connection available"
  else
    fail "Unable to access the Internet."
  fi
}


# ========================================
# Distribution files
# ========================================

check_distribution_files() {
  if [[ ! -f "${COMPOSE_SOURCE}" ]]; then
    fail "docker-compose.yml was not found next to install.sh.

Expected:

  ${COMPOSE_SOURCE}"
  fi

  success "Distribution files found"
}


# ========================================
# Existing installation
# ========================================

check_existing_installation() {
  log "Checking existing installation"

  if [[ ! -d "${INSTALL_DIR}" ]]; then
    success "No existing installation found"
    return
  fi

  if [[ ! -f "${INSTALL_DIR}/.env" ]] &&
     [[ ! -f "${INSTALL_DIR}/docker-compose.yml" ]] &&
     [[ ! -d "${INSTALL_DIR}/storage" ]]; then

    success "Installation directory exists but is empty"
    return
  fi

  echo
  echo "========================================"
  echo " Existing Installation Detected"
  echo "========================================"
  echo
  echo "An InternetCafe Server installation"
  echo "already exists at:"
  echo
  echo "  ${INSTALL_DIR}"
  echo
  echo "Your configuration and database will"
  echo "be preserved."
  echo

  read -r -p "Continue with repair? [y/N]: " answer

  case "${answer}" in
    y|Y)
      REPAIR_INSTALLATION=true
      success "Repair installation selected"
      ;;
    *)
      echo
      echo "Installation cancelled."
      exit 0
      ;;
  esac
}


stop_existing_installation() {
  log "Stopping existing InternetCafe Server"

  if [[ ! -f "${COMPOSE_FILE}" ]]; then
    success "No existing Docker Compose installation found"
    return
  fi

  compose down

  success "Existing InternetCafe Server stopped"
}


# ========================================
# Directories
# ========================================

prepare_directories() {
  log "Preparing installation directory"

  mkdir -p "${INSTALL_DIR}"
  mkdir -p "${STORAGE_DIR}"

  # Rails container runs as UID/GID 1000.
  chown 1000:1000 "${STORAGE_DIR}"
  chmod 700 "${STORAGE_DIR}"

  success "Installation directory: ${INSTALL_DIR}"
  success "Storage directory prepared"
}


# ========================================
# Docker Compose
# ========================================

install_compose_file() {
  log "Installing Docker Compose configuration"

  cp "${COMPOSE_SOURCE}" "${COMPOSE_FILE}"

  chmod 644 "${COMPOSE_FILE}"

  success "Docker Compose configuration installed"
}


compose() {
  docker compose \
    --project-directory "${INSTALL_DIR}" \
    --env-file "${INSTALL_DIR}/.env" \
    -f "${COMPOSE_FILE}" \
    "$@"
}


validate_compose() {
  log "Validating Docker Compose configuration"

  compose config >/dev/null

  success "Docker Compose configuration valid"
}


# ========================================
# Environment configuration
# ========================================

generate_secret() {
  # Generate a random secret using OpenSSL.
  # Accepts an optional argument specifying the number of hex characters.
  # Default is 64 (produces a 256-bit secret). Use 32 for a 128-bit secret.
  local length="${1:-64}"
  openssl rand -hex "$length"
}


prompt_required() {
  local prompt="$1"
  local value=""

  while [[ -z "${value}" ]]; do
    printf "%s: " "${prompt}" >&2
    IFS= read -r value
  done

  printf '%s' "${value}"
}


prompt_default() {
  local prompt="$1"
  local default="$2"
  local value=""

  printf "%s [%s]: " "${prompt}" "${default}" >&2
  IFS= read -r value

  if [[ -z "${value}" ]]; then
    value="${default}"
  fi

  printf '%s' "${value}"
}


prompt_password() {
  local prompt="$1"
  local value=""

  while [[ -z "${value}" ]]; do
    printf "%s: " "${prompt}" >&2
    IFS= read -r -s value
    printf "\n" >&2
  done

  printf '%s' "${value}"
}


prompt_owner_password() {
  local password=""
  local confirmation=""

  while true; do
    password="$(prompt_password "Owner password")"
    confirmation="$(prompt_password "Confirm password")"

    if [[ "${password}" == "${confirmation}" ]]; then
      printf '%s' "${password}"
      return
    fi

    echo "Passwords do not match. Please try again." >&2
  done
}


create_env() {
  log "Configuring InternetCafe Server"

  if [[ -f "${INSTALL_DIR}/.env" ]]; then
    success "Existing .env found; keeping current configuration"
    return
  fi

  echo
  echo "SMTP Configuration"
  echo "------------------"
  echo

  local smtp_address
  local smtp_port
  local smtp_username
  local smtp_password
  local smtp_domain
  local smtp_from

  smtp_address="$(prompt_required "SMTP server")"
  smtp_port="$(prompt_default "SMTP port" "587")"
  smtp_username="$(prompt_required "SMTP username")"
  smtp_password="$(prompt_password "SMTP password")"
  smtp_domain="$(prompt_required "SMTP domain")"
  smtp_from="$(prompt_required "Sender email")"

  local secret_key_base
  local encryption_primary_key
  local encryption_deterministic_key
  local encryption_key_derivation_salt

  # Generate 32‑character (128‑bit) secrets for Rails encryption keys.
  secret_key_base="$(generate_secret)"
  encryption_primary_key="$(generate_secret 32)"
  encryption_deterministic_key="$(generate_secret 32)"
  encryption_key_derivation_salt="$(generate_secret 32)"

  cat > "${INSTALL_DIR}/.env" <<EOF
SECRET_KEY_BASE=${secret_key_base}
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=${encryption_primary_key}
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=${encryption_deterministic_key}
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=${encryption_key_derivation_salt}

SMTP_ADDRESS=${smtp_address}
SMTP_PORT=${smtp_port}
SMTP_USERNAME=${smtp_username}
SMTP_PASSWORD=${smtp_password}
SMTP_DOMAIN=${smtp_domain}
SMTP_FROM=${smtp_from}
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
EOF

  chmod 600 "${INSTALL_DIR}/.env"

  success "Environment configuration created"
}


# ========================================
# Docker image
# ========================================

pull_image() {
  log "Pulling InternetCafe Server image"

  docker pull "${DOCKER_IMAGE}"

  success "Docker image downloaded"
}


# ========================================
# Rails server
# ========================================

start_web() {
  log "Starting Rails server"

  compose up -d web

  success "Rails server container started"
}


wait_for_web() {
  log "Waiting for Rails server"

  local attempts=30

  for ((i = 1; i <= attempts; i++)); do

    if curl \
      --silent \
      --fail \
      --max-time 2 \
      http://127.0.0.1:3000/ >/dev/null 2>&1; then

      success "Rails server is responding"
      return 0
    fi

    sleep 2
  done

  error "Rails server did not become ready."

  echo
  echo "Recent Rails logs:"
  echo

  compose logs --tail=100 web

  exit 1
}


# ========================================
# Owner management
# ========================================

owner_exists() {
  compose exec -T web bin/rails installation:owner_exists 2>/dev/null \
    | grep -qx "true"
}


create_owner() {
  log "Creating owner account"

  local owner_email
  local owner_password

  owner_email="$(prompt_required "Owner email")"
  owner_password="$(prompt_owner_password)"

  OWNER_EMAIL="${owner_email}" \
  OWNER_PASSWORD="${owner_password}" \
    compose exec -T \
      -e OWNER_EMAIL \
      -e OWNER_PASSWORD \
      web \
      bin/rails installation:configure_owner

  success "Owner account created"
}


update_owner() {
  log "Updating owner account"

  local current_email
  local owner_email
  local owner_password=""

  current_email="$(
    compose exec -T web bin/rails installation:owner_email
  )"

  echo
  echo "Current owner email:"
  echo "  ${current_email}"
  echo

  printf "New owner email [%s]: " "${current_email}" >&2
  IFS= read -r owner_email

  if [[ -z "${owner_email}" ]]; then
    owner_email="${current_email}"
  fi

  printf "New owner password (leave empty to keep current): " >&2
  IFS= read -r -s owner_password
  printf "\n" >&2

  OWNER_EMAIL="${owner_email}" \
  OWNER_PASSWORD="${owner_password}" \
    compose exec -T \
      -e OWNER_EMAIL \
      -e OWNER_PASSWORD \
      web \
      bin/rails installation:configure_owner

  success "Owner account updated"
}


configure_owner() {
  log "Checking owner account"

  if ! owner_exists; then
    echo
    echo "No owner account exists."
    echo
    echo "An owner account is required to use"
    echo "the InternetCafe Server."
    echo

    create_owner

    return
  fi

  success "Owner account already exists"

  echo
  read -r -p "Would you like to update the owner account? [y/N]: " answer

  case "${answer}" in
    y|Y)
      update_owner
      ;;
    *)
      success "Existing owner account preserved"
      ;;
  esac
}


# ========================================
# Background jobs
# ========================================

start_jobs() {
  log "Starting background jobs"

  compose up -d jobs

  success "Background jobs started"
}


# ========================================
# Final status
# ========================================

get_server_ip() {
  local ip

  ip="$(hostname -I 2>/dev/null | awk '{print $1}')"

  if [[ -n "${ip}" ]]; then
    printf '%s' "${ip}"
  else
    printf '%s' "localhost"
  fi
}


show_success() {
  local server_ip

  server_ip="$(get_server_ip)"

  echo
  echo "========================================"
  echo " InternetCafe Server Installed!"
  echo "========================================"
  echo
  echo "Server URL:"
  echo "  http://${server_ip}:3000"
  echo
  echo "Installation directory:"
  echo "  ${INSTALL_DIR}"
  echo
  echo "Configuration:"
  echo "  ${INSTALL_DIR}/.env"
  echo
  echo "Storage:"
  echo "  ${STORAGE_DIR}"
  echo
  echo "Useful commands:"
  echo
  echo "  cd ${INSTALL_DIR}"
  echo "  sudo docker compose ps"
  echo "  sudo docker compose logs -f"
  echo
}


# ========================================
# Main
# ========================================

main() {
  echo
  echo "========================================"
  echo "       ${APP_NAME} Installer"
  echo "              v${APP_VERSION}"
  echo "========================================"

  log "Checking prerequisites"

  require_root
  check_linux
  check_architecture
  check_docker
  check_compose
  check_command "curl" "curl"
  check_command "openssl" "OpenSSL"
  check_internet
  check_distribution_files

  check_existing_installation

  if [[ "${REPAIR_INSTALLATION}" == "true" ]]; then
    stop_existing_installation
  fi

  prepare_directories
  install_compose_file
  validate_compose
  create_env

  pull_image

  start_web
  wait_for_web

  configure_owner

  start_jobs

  show_success
}


main "$@"
