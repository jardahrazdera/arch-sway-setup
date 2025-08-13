# arch-sway-setup

Automated installation script for Arch Linux with Sway window manager

## ⚠️ Warning
**Early development stage** - Not recommended for production use. Test in VM first.

## What it does
- Installs base Arch Linux system
- Sets up Sway (Wayland compositor)
- Configures essential packages and dotfiles

## Requirements
- UEFI system
- 20GB+ disk space
- Internet connection
- Arch Linux installation media

## Installation
```bash
# Boot from Arch ISO, then:
curl -L https://github.com/yourusername/arch-sway-setup/raw/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

## Configuration
Edit `config` file before running:
- Hostname
- Username
- Timezone
- Locale
- Additional packages

## Structure
```
arch-sway-setup/
├── install.sh       # Main script
├── config          # Configuration
└── modules/        # Installation modules
```

## TODO
- [ ] Encryption support
- [ ] AUR helper integration
- [ ] Better error handling
- [ ] Multi-monitor setup

## License
MIT

---
**Use at your own risk. Always backup your data.**
