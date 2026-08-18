# InternetCafe Server

> A self-hosted internet café management system with coin-slot billing, PC session control, and ESP32 hardware integration.

![Ruby](https://img.shields.io/badge/Ruby-3.4.5-CC342D?logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-8.1.3-CC0000?logo=rubyonrails&logoColor=white)
![License](https://img.shields.io/badge/License-Internet%20Caf%C3%A9%20Community-blue)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-informational)
![WSL](https://img.shields.io/badge/Windows-Docker%20Desktop%20%2B%20WSL2-0078D4?logo=windows&logoColor=white)
![Docker](https://img.shields.io/badge/Deployment-Docker-2496ED?logo=docker&logoColor=white)

---

## Overview

**InternetCafe Server** is the central management backend for internet café operations. It connects to coin-slot ESP32 hardware over the local network and communicates with a WinForms PC agent installed on every gaming PC. Administrators manage everything through a web-based dashboard — including PCs, coin slots, sessions, and system settings.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Internet Café LAN                    │
│                                                         │
│  ┌──────────────┐      HTTP/JSON      ┌──────────────┐  │
│  │  Admin/Staff │◄───────────────────►│ Rails Server │  │
│  │   Browser    │                     │  (this app)  │  │
│  └──────────────┘                     └──────┬───────┘  │
│                                              │           │
│                          ┌───────────────────┤           │
│                          │                   │           │
│                    ┌─────▼──────┐    ┌───────▼──────┐   │
│                    │ WinForms   │    │  ESP8266 Coin│   │
│                    │ PC Agent   │    │  Slot Device │   │
│                    │ (each PC)  │    │  (each slot) │   │
│                    └────────────┘    └──────────────┘   │
└─────────────────────────────────────────────────────────┘
```

| Component             | Role                                                                               |
| --------------------- | ---------------------------------------------------------------------------------- |
| **Rails Server**      | Central API, admin dashboard, background jobs, session lifecycle                   |
| **WinForms PC Agent** | Runs on each gaming PC; locks/unlocks the PC, sends heartbeats, polls for commands |
| **ESP8266 Coin Slot** | Embedded device that accepts coins and reports coin events to the server           |
| **Admin Dashboard**   | Web UI for operators to manage PCs, sessions, coin slots, and settings             |

---

## Features

- 🖥️ **PC Session Management** — Coin-funded and manual sessions with full lifecycle: start, extend, and stop. Sessions track total time purchased, amount paid, and minutes used.
- 🪙 **Coin-Slot Integration** — Real-time coin event ingestion from ESP8266 devices over HTTP. Each coin insertion creates a `CoinTransaction` with automatically calculated minutes based on the configured rate.
- 🔒 **PC Lock/Unlock Control** — The server remotely commands the WinForms agent on each gaming PC to lock or unlock it. Supports restart and shutdown. Commands are queued and retried on connection failure.
- ⏱️ **Session Expiration & Auto-Shutdown** — Sessions expire automatically via background jobs. After a session ends, PCs are scheduled for shutdown after a configurable grace period.
- 📡 **Device Heartbeat Monitoring** — PC agents and coin-slot devices send periodic heartbeats. Background jobs mark devices offline when heartbeats go stale beyond a configurable threshold.
- 🔐 **HMAC-Authenticated Device API** — All device-to-server communication (registration, heartbeats, coin events) is protected by per-device HMAC signatures with timestamp validation.
- 📺 **Real-Time Admin UI** — The admin dashboard updates live via Turbo Streams (ActionCable). PC status, active sessions, and coin transactions push to the browser without page refreshes.
- 🎛️ **Admin Dashboard** — Overview of online PCs, active sessions, revenue, and hardware status. Includes 7-day revenue charts, hourly session graphs, and recent transaction history.
- 👥 **Role-Based Access** — Two roles: `owner` (full access, single account) and `staff` (restricted access). Destructive actions such as archiving PCs are owner-only.
- 🗄️ **PC Kiosk & Archive Modes** — PCs can be put in `disabled_kiosk` or `archived` states, which are immutable and protected from accidental status changes by background jobs.
- ⚙️ **Configurable Settings** — Adjust billing rates, timeouts, thresholds, and more from the admin UI without deploying code changes.
- 🐳 **Docker Deployment** — One-command installation via a self-contained installer script for both Linux and Windows (Docker Desktop + WSL2).

---

## Requirements

### Server

The server can run on **Linux** or **Windows** (via Docker Desktop with WSL2):

| Platform    | Supported Versions                      | Architecture     |
| ----------- | --------------------------------------- | ---------------- |
| **Linux**   | Ubuntu, Debian                          | `amd64`, `arm64` |
| **Windows** | Windows 10 / 11 (Docker Desktop + WSL2) | `amd64`, `arm64` |

Required on both platforms:

- [Docker Desktop](https://docs.docker.com/get-docker/) (includes Docker Compose)

> **Windows note:** Docker Desktop must be configured to use the **WSL2 backend** (the default since Docker Desktop 4.x). Enable it under _Settings → General → Use the WSL 2 based engine_.

### PC Agent (per gaming PC)

- Windows (WinForms-compatible)
- Network connectivity to the Rails server

### Coin Slot

- ESP32-based device connected to the local network

---

## Getting Started (Docker Deployment)

> [!IMPORTANT]
> Full installation guides, step-by-step instructions, and troubleshooting are maintained in the dedicated installer repository:
>
> **➡️ [ed-dev-oc/internetcafe-system](https://github.com/ed-dev-oc/internetcafe-system)**

The installer repository contains platform-specific guides for:

| Platform                                      | Installer                           | Install Path                  |
| --------------------------------------------- | ----------------------------------- | ----------------------------- |
| 🐧 **Linux** (Ubuntu / Debian, amd64 / arm64) | `install.sh`                        | `/opt/internetcafe`           |
| 🪟 **Windows** (Docker Desktop + WSL2)        | `install.ps1` (PowerShell as Admin) | `C:\ProgramData\InternetCafe` |

Both installers will interactively guide you through:

1. Prerequisites check (OS, architecture, Docker)
2. SMTP configuration
3. Automatic secret/encryption key generation
4. Docker image pull and service startup (`web` + `jobs`)
5. Initial owner account creation

Once installed, access the dashboard at:

```
http://<your-server-ip>:3000
```

> **Tip:** After installation, configure your server's IP as a **static IP** or **DHCP reservation** on your router so PC agents and coin-slot devices can reliably reach the server.

---

## Upgrading / Repair

Re-run the installer from [ed-dev-oc/internetcafe-system](https://github.com/ed-dev-oc/internetcafe-system) — it detects an existing installation and prompts for a repair, preserving your configuration (`.env`) and database.

---

## Local Development Setup

Requires:

- Ruby `3.4.5` (recommend [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com/))
- Node.js `25.2.1` (recommend [fnm](https://github.com/Schniz/fnm) or [nvm](https://github.com/nvm-sh/nvm))
- Yarn
- SQLite3

### Steps

```bash
# Clone the repository
git clone https://github.com/ed-dev-oc/pc-timer-rails.git
cd pc-timer-rails

# Install Ruby dependencies
bundle install

# Install JS dependencies
yarn install

# Set up environment
cp env.example .env
# Fill in at minimum: SECRET_KEY_BASE and ACTIVE_RECORD_ENCRYPTION_* keys

# Set up the database
bin/rails db:create db:migrate db:seed

# Start all dev processes
bin/dev
```

The app will be available at `http://localhost:3000`.

> `bin/dev` runs all processes defined in `Procfile.dev`:
>
> - `web` — Rails server
> - `css` — CSS watcher
> - `worker` — SolidQueue background job worker
> - `js` — JavaScript bundler (watch mode)

### Running Tests

```bash
bin/rails test
bin/rails test:system
```

### Static Analysis

```bash
bundle exec brakeman        # Security audit
bundle exec rubocop         # Style checks
bundle exec bundler-audit   # Dependency vulnerability audit
```

---

## Configuration Reference

All settings are managed in the database and can be adjusted via the **Admin → Settings** UI. Default values are applied on first boot.

### General

| Key                  | Default           | Type    | Description                                     |
| -------------------- | ----------------- | ------- | ----------------------------------------------- |
| `business_name`      | `"Internet Cafe"` | string  | Business display name shown in the UI           |
| `app_name`           | `"iCafe"`         | string  | Application display name                        |
| `minutes_per_credit` | `6`               | integer | Minutes of PC time granted per coin/credit      |
| `minimum_credit`     | `1`               | integer | Minimum peso amount required to start a session |

### Session & Hardware

| Key                           | Default       | Type     | Description                                                       |
| ----------------------------- | ------------- | -------- | ----------------------------------------------------------------- |
| `coin_slot_session_duration`  | `60` seconds  | duration | How long a coin slot session stays open to accept coins           |
| `coin_slot_offline_threshold` | `2` minutes   | integer  | Minutes without a heartbeat before a coin slot is marked offline  |
| `pc_offline_threshold`        | `2` minutes   | integer  | Minutes without a heartbeat before a PC is marked offline         |
| `heartbeat_interval`          | `2` minutes   | integer  | Expected heartbeat frequency from PC agents and coin slots        |
| `pc_shutdown_wait_time`       | `300` seconds | duration | Grace period before scheduling a PC shutdown after a session ends |

### Advanced — ESP32 Connection

| Key                                | Default | Description                                |
| ---------------------------------- | ------- | ------------------------------------------ |
| `esp_connection_open_timeout`      | `2` s   | TCP connection open timeout                |
| `esp_connection_timeout`           | `5` s   | HTTP request timeout                       |
| `esp_command_timeout_retry_wait`   | `3` s   | Wait between retries on timeout            |
| `esp_command_timeout_max_attempts` | `3`     | Max retry attempts on timeout              |
| `esp_connection_failed_retry_wait` | `5` s   | Wait between retries on connection failure |
| `esp_command_max_attempts`         | `3`     | Max retry attempts on connection failure   |

### Advanced — PC Agent Connection

| Key                               | Default | Description                                |
| --------------------------------- | ------- | ------------------------------------------ |
| `pc_connection_open_timeout`      | `2` s   | TCP connection open timeout                |
| `pc_connection_timeout`           | `5` s   | HTTP request timeout                       |
| `pc_command_timeout_retry_wait`   | `3` s   | Wait between retries on timeout            |
| `pc_command_timeout_max_attempts` | `3`     | Max retry attempts on timeout              |
| `pc_connection_failed_retry_wait` | `5` s   | Wait between retries on connection failure |
| `pc_command_max_attempts`         | `3`     | Max retry attempts on connection failure   |

---

## Tech Stack

| Layer           | Technology                                       |
| --------------- | ------------------------------------------------ |
| Framework       | Ruby on Rails 8.1                                |
| Language        | Ruby 3.4.5                                       |
| Database        | SQLite3 (via Active Record)                      |
| Background Jobs | SolidQueue + SolidCable + SolidCache             |
| Frontend        | Hotwire (Turbo + Stimulus), ViewComponent        |
| Asset Pipeline  | Propshaft + cssbundling-rails + jsbundling-rails |
| Authentication  | Devise 5                                         |
| Job Dashboard   | MissionControl::Jobs                             |
| HTTP Client     | Faraday                                          |
| Deployment      | Docker + Kamal + Thruster                        |

---

## License

This project is licensed under the **Internet Café Community License**.
See the [LICENSE](./LICENSE) file for full terms.

Copyright © 2026 Edgardo B. Po Jr.
