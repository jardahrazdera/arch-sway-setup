#!/bin/bash
# Arch + Sway Complete Setup Script
# Version: 1.0
# Author: Arch Sway Setup

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/arch-sway-setup-$(date +%Y%m%d-%H%M%S).log"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

# Logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root!"
    fi
}

# Backup existing configs
backup_configs() {
    log "Backing up existing configurations..."
    
    local configs=(
        "$HOME/.config/sway"
        "$HOME/.config/waybar"
        "$HOME/.config/mako"
        "$HOME/.config/rofi"
        "$HOME/.config/kitty"
        "$HOME/.config/swaylock"
        "$HOME/.config/cava"
        "$HOME/.config/gtk-3.0"
    )
    
    for config in "${configs[@]}"; do
        if [[ -d "$config" ]]; then
            mkdir -p "$BACKUP_DIR"
            cp -r "$config" "$BACKUP_DIR/" 2>/dev/null || true
            info "Backed up: $config"
        fi
    done
}

# Install packages
install_packages() {
    log "Installing packages..."
    
    # Core packages
    local packages=(
        # Sway and Wayland
        sway swaylock swayidle swaybg
        xdg-utils xdg-desktop-portal xdg-desktop-portal-wlr
        qt5-wayland qt6-wayland
        
        # Font rendering
        fontconfig freetype2 cairo pango harfbuzz
        
        # AMD Graphics
        mesa vulkan-radeon libva-mesa-driver mesa-vdpau
        
        # Display and brightness
        way-displays brightnessctl
        
        # Screenshots
        grim slurp
        
        # Audio
        pipewire pipewire-pulse pipewire-alsa wireplumber
        pipewire-screenaudio pipewire-zeroconf
        pavucontrol cava
        
        # Network and Bluetooth
        networkmanager
        bluez bluez-utils blueman bluetui
        
        # Security
        fprintd libfprint
        gnome-keyring seahorse
        polkit polkit-gnome
        
        # System utilities
        tlp tlp-rdw
        udisks2 udiskie
        zip unzip p7zip unrar
        wl-clipboard cliphist
        base-devel git curl wget
        btop htop
        nautilus
        ufw
        
        # UI Components
        waybar mako rofi-wayland kitty wlsunset
        
        # Applications
        zathura zathura-pdf-poppler imv neovimi nwg-look
        
        # Fonts
        ttf-font-awesome ttf-jetbrains-mono-nerd noto-fonts ttf-dejavu
        
        # Display manager
        greetd greetd-tuigreet
        
        # Icons
        papirus-icon-theme
    )
    
    info "Installing from official repositories..."
    sudo pacman -S --needed --noconfirm "${packages[@]}" 2>&1 | tee -a "$LOG_FILE"
}

# Install AUR packages
install_aur_packages() {
    log "Installing AUR packages..."
    
    # Install yay if not present
    if ! command -v yay &> /dev/null; then
        info "Installing yay AUR helper..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd - > /dev/null
        rm -rf /tmp/yay
    fi
    
    # AUR packages
    local aur_packages=(
        catppuccin-gtk-theme-mocha
        catppuccin-cursors-mocha
        waybar-cava
    )
    
    info "Installing from AUR..."
    yay -S --needed --noconfirm "${aur_packages[@]}" 2>&1 | tee -a "$LOG_FILE"
}

# Create directory structure
create_directories() {
    log "Creating configuration directories..."
    
    mkdir -p ~/.config/{sway,waybar,waybar/scripts,mako,rofi,kitty,swaylock,environment.d,systemd/user,way-displays,cava,gtk-3.0}
    mkdir -p ~/Pictures
}

# Install configurations
install_configs() {
    log "Installing configuration files..."
    
    # Environment variables
    cat > ~/.config/environment.d/envvars.conf << 'EOF'
# Wayland
MOZ_ENABLE_WAYLAND=1
QT_QPA_PLATFORM=wayland
QT_WAYLAND_DISABLE_WINDOWDECORATION=1
SDL_VIDEODRIVER=wayland
_JAVA_AWT_WM_NONREPARENTING=1

# XDG
XDG_CURRENT_DESKTOP=sway
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=sway

# GTK
GTK_THEME=Catppuccin-Mocha-Standard-Mauve-Dark

# Editor
EDITOR=nvim
VISUAL=nvim
EOF

    # Sway config
    cat > ~/.config/sway/config << 'EOF'
# Logo key. Use Mod1 for Alt.
set $mod Mod4

# Home row direction keys, like vim
set $left h
set $down j
set $up k
set $right l

# Terminal a launcher
set $term kitty
set $menu rofi -show drun

# Wallpaper
output * bg ~/Pictures/wallpaper.jpg fill

### Video synchronization
output * adaptive_sync on

### Input configuration
input type:keyboard {
    xkb_layout "us,cz"
    xkb_variant ",qwerty"
    xkb_options "grp:alt_shift_toggle"
    repeat_delay 400
    repeat_rate 60
}

input type:touchpad {
    dwt enabled
    tap enabled
    natural_scroll enabled
    middle_emulation enabled
}

### Key bindings
# Základní
bindsym $mod+Return exec $term
bindsym $mod+q kill
bindsym $mod+d exec $menu
bindsym $mod+Shift+c reload
bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit sway?' -b 'Yes' 'swaymsg exit'

# Screen locking
bindsym $mod+l exec swaylock

# Screenshots
bindsym Print exec grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
bindsym $mod+Print exec grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

# Audio controls
bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle

# Media controls
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous

# Brightness controls
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86MonBrightnessUp exec brightnessctl set +5%

### Window management
# Fullscreen
bindsym $mod+f fullscreen

# Floating toggle
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle

# Parent focus
bindsym $mod+a focus parent

# Layout modes
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

### Focus movement
bindsym $mod+$left focus left
bindsym $mod+$down focus down
bindsym $mod+$up focus up
bindsym $mod+$right focus right

# Arrow keys
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

### Window movement
bindsym $mod+Shift+$left move left
bindsym $mod+Shift+$down move down
bindsym $mod+Shift+$up move up
bindsym $mod+Shift+$right move right

# Arrow keys
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

### Workspaces
# Switch
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+6 workspace number 6
bindsym $mod+7 workspace number 7
bindsym $mod+8 workspace number 8
bindsym $mod+9 workspace number 9
bindsym $mod+0 workspace number 10

# Move to workspace
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+Shift+6 move container to workspace number 6
bindsym $mod+Shift+7 move container to workspace number 7
bindsym $mod+Shift+8 move container to workspace number 8
bindsym $mod+Shift+9 move container to workspace number 9
bindsym $mod+Shift+0 move container to workspace number 10

### Scratchpad
bindsym $mod+Shift+minus move scratchpad
bindsym $mod+minus scratchpad show

### Resize mode
mode "resize" {
    bindsym $left resize shrink width 10px
    bindsym $down resize grow height 10px
    bindsym $up resize shrink height 10px
    bindsym $right resize grow width 10px
    
    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px
    
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

### Utility shortcuts
bindsym $mod+n exec $term -e nmtui
bindsym $mod+Shift+b exec $term -e bluetui
bindsym $mod+k exec seahorse
bindsym $mod+t exec $term -e btop
bindsym $mod+v exec cliphist list | rofi -dmenu | cliphist decode | wl-copy
bindsym $mod+shift+r exec pkill wlsunset || wlsunset

### Floating rules
for_window [app_id="pavucontrol"] floating enable
for_window [app_id="blueman-manager"] floating enable
for_window [app_id="nm-connection-editor"] floating enable
for_window [app_id="gnome-calculator"] floating enable
for_window [app_id="seahorse"] floating enable
for_window [title="File Operation Progress"] floating enable

### Window appearance
default_border pixel 2
default_floating_border pixel 2
smart_borders on

# Gaps
gaps inner 5
gaps outer 2

# Colors (Catppuccin Mocha)
client.focused          #cba6f7 #cba6f7 #11111b #f5c2e7   #cba6f7
client.focused_inactive #45475a #45475a #cdd6f4 #6c7086   #45475a
client.unfocused        #313244 #313244 #a6adc8 #6c7086   #313244
client.urgent           #f38ba8 #f38ba8 #11111b #f5c2e7   #f38ba8

### Autostart
exec --no-startup-id waybar
exec --no-startup-id mako
exec --no-startup-id way-displays > /tmp/way-displays.${XDG_VTNR}.${USER}.log 2>&1
exec --no-startup-id udiskie
exec --no-startup-id wlsunset
exec --no-startup-id gnome-keyring-daemon --start --components=secrets,ssh,pkcs11
exec --no-startup-id /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# Clipboard manager
exec wl-paste --type text --watch cliphist store
exec wl-paste --type image --watch cliphist store

# Swayidle
exec swayidle -w \
    timeout 300 'swaylock' \
    timeout 600 'swaymsg "output * power off"' \
    resume 'swaymsg "output * power on"' \
    timeout 900 'systemctl suspend' \
    before-sleep 'swaylock' \
    after-resume 'swaymsg "output * power on"' \
    lock 'swaylock'

include /etc/sway/config.d/*
EOF

    # Waybar config
    cat > ~/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["sway/workspaces", "sway/mode", "custom/cava"],
    "modules-center": ["sway/window"],
    "modules-right": ["tray", "cpu", "memory", "custom/tlp", "pulseaudio", "network", "battery", "clock"],
    
    "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{index}",
        "persistent_workspaces": {
            "1": [],
            "2": [],
            "3": [],
            "4": [],
            "5": []
        }
    },
    
    "sway/mode": {
        "format": "<span style=\"italic\">{}</span>"
    },
    
    "sway/window": {
        "max-length": 50,
        "tooltip": false
    },
    
    "custom/cava": {
        "exec": "waybar-cava",
        "format": "{}",
        "tooltip": false
    },
    
    "custom/tlp": {
        "format": "{}",
        "exec": "~/.config/waybar/scripts/tlp-status.sh",
        "on-click": "~/.config/waybar/scripts/tlp-toggle.sh",
        "interval": 5,
        "tooltip": true,
        "return-type": "json"
    },
    
    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%Y-%m-%d %H:%M:%S}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "on-click-right": "kitty -e cal -y"
    },
    
    "cpu": {
        "format": "{usage}% ",
        "tooltip": true,
        "on-click": "kitty -e btop"
    },
    
    "memory": {
        "format": "{}% ",
        "tooltip-format": "Memory: {used:0.1f}G/{total:0.1f}G",
        "on-click": "kitty -e btop"
    },
    
    "tray": {
        "icon-size": 18,
        "spacing": 10,
        "show-passive-items": true
    },
    
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
        "format-icons": ["", "", "", "", ""],
        "tooltip-format": "{timeTo}"
    },
    
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ifname}: {ipaddr}/{cidr} ",
        "format-disconnected": "Disconnected ⚠",
        "tooltip-format": "{ifname}: {ipaddr}",
        "on-click": "kitty -e nmtui"
    },
    
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-bluetooth": "{volume}% {icon}",
        "format-bluetooth-muted": " {icon}",
        "format-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol",
        "on-click-right": "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    }
}
EOF

    # Waybar style
    cat > ~/.config/waybar/style.css << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", "Font Awesome";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(17, 17, 27, 0.95);
    color: #cdd6f4;
    transition-property: background-color;
    transition-duration: .5s;
}

#workspaces button {
    padding: 0 8px;
    background-color: #313244;
    color: #cdd6f4;
    margin: 4px 2px;
    transition: all 0.3s ease;
}

#workspaces button:hover {
    background-color: #45475a;
    color: #cdd6f4;
}

#workspaces button.focused {
    background-color: #cba6f7;
    color: #11111b;
}

#workspaces button.urgent {
    background-color: #f38ba8;
    color: #11111b;
}

#mode {
    background-color: #f38ba8;
    color: #11111b;
    padding: 0 10px;
    margin: 4px;
}

#custom-cava {
    color: #cba6f7;
    padding: 0 10px;
    margin: 4px 0;
}

#clock, #battery, #network, #pulseaudio, #cpu, #memory, #custom-tlp {
    padding: 0 10px;
    margin: 4px 2px;
    background-color: #313244;
    color: #cdd6f4;
}

#custom-tlp {
    background-color: #313244;
}

#custom-tlp.active {
    background-color: #a6e3a1;
    color: #11111b;
}

#window {
    margin: 4px 10px;
    color: #a6adc8;
}

#tray {
    background-color: #313244;
    padding: 0 10px;
    margin: 4px 2px;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: #f38ba8;
}

#battery.charging {
    color: #a6e3a1;
}

#battery.critical:not(.charging) {
    background-color: #f38ba8;
    color: #11111b;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#network.disconnected {
    background-color: #f38ba8;
    color: #11111b;
}

#pulseaudio.muted {
    background-color: #45475a;
    color: #7f849c;
}

@keyframes blink {
    to {
        background-color: #11111b;
        color: #f38ba8;
    }
}
EOF

    # Waybar TLP scripts
    cat > ~/.config/waybar/scripts/tlp-status.sh << 'EOF'
#!/bin/bash

# Check if TLP is active
if systemctl is-active --quiet tlp; then
    # Get current power profile
    MODE=$(tlp-stat -s | grep "Mode" | awk '{print $3}')
    if [ "$MODE" = "AC" ]; then
        echo '{"text": " AC", "tooltip": "TLP: AC mode", "class": "active"}'
    else
        echo '{"text": " BAT", "tooltip": "TLP: Battery mode", "class": "active"}'
    fi
else
    echo '{"text": " OFF", "tooltip": "TLP: Disabled", "class": "inactive"}'
fi
EOF

    cat > ~/.config/waybar/scripts/tlp-toggle.sh << 'EOF'
#!/bin/bash

# Toggle TLP service
if systemctl is-active --quiet tlp; then
    pkexec systemctl stop tlp
    notify-send "TLP" "Power management disabled" -i battery
else
    pkexec systemctl start tlp
    notify-send "TLP" "Power management enabled" -i battery-charging
fi
EOF

    chmod +x ~/.config/waybar/scripts/tlp-status.sh
    chmod +x ~/.config/waybar/scripts/tlp-toggle.sh

    # Kitty config
    cat > ~/.config/kitty/kitty.conf << 'EOF'
# Fonts
font_family      JetBrainsMono Nerd Font
bold_font        JetBrainsMono Nerd Font Bold
italic_font      JetBrainsMono Nerd Font Italic
bold_italic_font JetBrainsMono Nerd Font Bold Italic
font_size 11.0

# Window layout
remember_window_size  yes
initial_window_width  1024
initial_window_height 768
window_padding_width 10

# Background opacity
background_opacity 0.95

# Tab bar
tab_bar_edge bottom
tab_bar_style powerline
tab_powerline_style slanted
tab_bar_min_tabs 2

# Colors (Catppuccin Mocha)
foreground #cdd6f4
background #1e1e2e

# Black
color0 #45475a
color8 #585b70

# Red
color1 #f38ba8
color9 #f38ba8

# Green
color2 #a6e3a1
color10 #a6e3a1

# Yellow
color3 #f9e2af
color11 #f9e2af

# Blue
color4 #89b4fa
color12 #89b4fa

# Magenta
color5 #cba6f7
color13 #cba6f7

# Cyan
color6 #94e2d5
color14 #94e2d5

# White
color7 #bac2de
color15 #a6adc8

# Cursor
cursor #f5e0dc
cursor_text_color #1e1e2e

# Selection
selection_foreground #cdd6f4
selection_background #45475a

# Tab bar colors
active_tab_foreground   #11111b
active_tab_background   #cba6f7
inactive_tab_foreground #cdd6f4
inactive_tab_background #45475a

# URL color
url_color #89b4fa

# Window borders
active_border_color #cba6f7
inactive_border_color #45475a
window_border_width 2px

# Key mappings
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+plus change_font_size all +2.0
map ctrl+minus change_font_size all -2.0
map ctrl+0 change_font_size all 0

# Window/Tab management
map ctrl+shift+enter new_window
map ctrl+shift+t new_tab
map ctrl+shift+q close_window
map ctrl+shift+w close_tab
map ctrl+shift+] next_window
map ctrl+shift+[ previous_window
map ctrl+shift+right next_tab
map ctrl+shift+left previous_tab

# Performance
repaint_delay 10
input_delay 3
sync_to_monitor yes

# Misc
enable_audio_bell no
visual_bell_duration 0.0
mouse_hide_wait 3.0
EOF

    # Swaylock config
    cat > ~/.config/swaylock/config << 'EOF'
color=1e1e2eff
bs-hl-color=f38ba8ff
key-hl-color=a6e3a1ff
ring-color=313244ff
ring-clear-color=f2cdcdff
ring-ver-color=89b4faff
ring-wrong-color=f38ba8ff
separator-color=00000000
text-color=cdd6f4ff
text-clear-color=f2cdcdff
text-ver-color=89b4faff
text-wrong-color=f38ba8ff
line-color=00000000
line-clear-color=00000000
line-ver-color=00000000
line-wrong-color=00000000
inside-color=00000088
inside-clear-color=00000088
inside-ver-color=00000088
inside-wrong-color=00000088
EOF

    # Rofi config
    cat > ~/.config/rofi/config.rasi << 'EOF'
configuration {
    modi: "drun,run,window";
    font: "JetBrainsMono Nerd Font 12";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    display-drun: " Apps";
    display-run: " Run";
    display-window: " Window";
    drun-display-format: "{name}";
    window-format: "{w} · {c} · {t}";
    
    timeout {
        action: "kb-cancel";
        delay: 0;
    }
}

@theme "catppuccin-mocha"

* {
    bg-col: #1e1e2e;
    bg-col-light: #313244;
    border-col: #cba6f7;
    selected-col: #45475a;
    mauve: #cba6f7;
    fg-col: #cdd6f4;
    fg-col2: #f38ba8;
    grey: #6c7086;
    
    width: 600;
    font: "JetBrainsMono Nerd Font 12";
}

element-text, element-icon, mode-switcher {
    background-color: inherit;
    text-color: inherit;
}

window {
    height: 360px;
    border: 2px;
    border-color: @border-col;
    background-color: @bg-col;
}

mainbox {
    background-color: @bg-col;
}

inputbar {
    children: [prompt,entry];
    background-color: @bg-col;
    border-radius: 0px;
    padding: 2px;
}

prompt {
    background-color: @mauve;
    padding: 6px;
    text-color: @bg-col;
    margin: 20px 0px 0px 20px;
}

textbox-prompt-colon {
    expand: false;
    str: ":";
}

entry {
    padding: 6px;
    margin: 20px 0px 0px 10px;
    text-color: @fg-col;
    background-color: @bg-col;
}

listview {
    border: 0px 0px 0px;
    padding: 6px 0px 0px;
    margin: 10px 0px 0px 20px;
    columns: 2;
    lines: 5;
    background-color: @bg-col;
}

element {
    padding: 5px;
    background-color: @bg-col;
    text-color: @fg-col;
}

element-icon {
    size: 25px;
}

element selected {
    background-color: @selected-col;
    text-color: @fg-col;
}

mode-switcher {
    spacing: 0;
}

button {
    padding: 10px;
    background-color: @bg-col-light;
    text-color: @grey;
    vertical-align: 0.5;
    horizontal-align: 0.5;
}

button selected {
    background-color: @bg-col;
    text-color: @mauve;
}

message {
    background-color: @bg-col-light;
    margin: 2px;
    padding: 2px;
}

textbox {
    padding: 6px;
    margin: 20px 0px 0px 20px;
    text-color: @mauve;
    background-color: @bg-col-light;
}
EOF

    # Mako config
    cat > ~/.config/mako/config << 'EOF'
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#cba6f7
border-size=2
border-radius=0
padding=15
margin=10
max-icon-size=48
default-timeout=5000
font=JetBrainsMono Nerd Font 11
anchor=top-right
EOF

    # GTK-3.0 settings
    cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-theme-name=Catppuccin-Mocha-Standard-Mauve-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=JetBrainsMono Nerd Font 11
gtk-cursor-theme-name=Catppuccin-Mocha-Dark-Cursors
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
EOF

    # Cava config
    cat > ~/.config/cava/config << 'EOF'
[general]
bars = 12
bar_width = 2
bar_spacing = 1

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7

[color]
foreground = cyan

[smoothing]
integral = 77
monstercat = 1
waves = 0
EOF

    # Systemd sway-session.target
    cat > ~/.config/systemd/user/sway-session.target << 'EOF'
[Unit]
Description=Sway compositor session
Documentation=man:systemd.special(7)
BindsTo=graphical-session.target
Wants=graphical-session-pre.target
After=graphical-session-pre.target
EOF
}

# Configure system files
configure_system() {
    log "Configuring system files..."
    
    # TLP config
    info "Configuring TLP..."
    sudo tee /etc/tlp.conf > /dev/null << 'EOF'
# Battery thresholds
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80

# CPU
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave

# AMD GPU
RADEON_DPM_STATE_ON_AC=performance
RADEON_DPM_STATE_ON_BAT=battery

# Wifi power
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on
EOF

    # Bluetooth config
    info "Configuring Bluetooth..."
    sudo tee /etc/bluetooth/main.conf > /dev/null << 'EOF'
[General]
Enable=Source,Sink,Media,Socket
ControllerMode = bredr
FastConnectable = true

[Policy]
AutoEnable=true
EOF

    # PAM configs
    info "Configuring PAM for fingerprint..."
    
    # Backup original PAM files
    sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak
    sudo cp /etc/pam.d/login /etc/pam.d/login.bak
    
    # Add fingerprint to sudo
    if ! grep -q "pam_fprintd.so" /etc/pam.d/sudo; then
        sudo sed -i '1i auth      sufficient pam_fprintd.so\nauth      optional   pam_gnome_keyring.so' /etc/pam.d/sudo
    fi
    
    # Add keyring to login
    if ! grep -q "pam_gnome_keyring.so auto_start" /etc/pam.d/login; then
        echo "session   optional   pam_gnome_keyring.so auto_start" | sudo tee -a /etc/pam.d/login > /dev/null
    fi

    # Polkit rules
    info "Configuring Polkit rules..."
    sudo tee /etc/polkit-1/rules.d/50-wheel-admin.rules > /dev/null << 'EOF'
// Allow wheel group to use admin actions with fingerprint
polkit.addRule(function(action, subject) {
    if (subject.isInGroup("wheel")) {
        return polkit.Result.AUTH_ADMIN_KEEP;
    }
});

// Allow certain actions without authentication for wheel group
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.NetworkManager.settings.modify.system" ||
         action.id == "org.freedesktop.NetworkManager.network-control" ||
         action.id == "org.bluez.obex" ||
         action.id == "org.freedesktop.login1.suspend" ||
         action.id == "org.freedesktop.login1.hibernate" ||
         action.id == "org.freedesktop.udisks2.filesystem-mount" ||
         action.id == "org.freedesktop.systemd1.manage-units") &&
        subject.isInGroup("wheel")) {
        return polkit.Result.YES;
    }
});
EOF

    # Greetd config
    info "Configuring Greetd..."
    sudo tee /etc/greetd/config.toml > /dev/null << 'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --cmd sway --time --remember"
user = "greeter"
EOF
}

# Setup user
setup_user() {
    log "Setting up user configuration..."
    
    # Add user to groups
    info "Adding user to required groups..."
    sudo usermod -aG wheel,video,audio,input "$USER"
    
    # Download wallpaper
    info "Downloading wallpaper..."
    wget -q -O ~/Pictures/wallpaper.jpg "https://source.unsplash.com/1920x1080/?nature,landscape" || \
        warning "Failed to download wallpaper"
}

# Enable services
enable_services() {
    log "Enabling system services..."
    
    # System services
    sudo systemctl enable NetworkManager
    sudo systemctl enable bluetooth
    sudo systemctl enable tlp
    sudo systemctl enable ufw
    sudo systemctl enable greetd
    
    # Start immediate services
    sudo systemctl start NetworkManager
    sudo systemctl start bluetooth
    sudo systemctl start tlp
    
    # User services
    systemctl --user enable pipewire
    systemctl --user enable pipewire-pulse
    systemctl --user enable wireplumber
    
    # Configure firewall
    info "Configuring firewall..."
    sudo ufw --force enable
}

# Fingerprint setup
setup_fingerprint() {
    log "Setting up fingerprint authentication..."
    
    read -p "Do you want to enroll fingerprint now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo fprintd-enroll "$USER"
    else
        info "You can enroll fingerprint later with: sudo fprintd-enroll $USER"
    fi
}

# Post-install message
post_install_message() {
    echo
    log "Installation completed successfully!"
    echo
    info "Next steps:"
    echo "  1. Review the log file: $LOG_FILE"
    echo "  2. Reboot your system: sudo reboot"
    echo "  3. After reboot, you can:"
    echo "     - Use 'nmtui' to configure network"
    echo "     - Use 'bluetui' to configure bluetooth"
    echo "     - Test fingerprint with 'fprintd-verify'"
    echo
    info "Backups of your old configs are stored in: $BACKUP_DIR"
    echo
    warning "Note: wlsunset will automatically detect your location via GeoIP"
}

# Main installation flow
main() {
    clear
    echo "========================================="
    echo "   Arch + Sway Complete Setup Script"
    echo "========================================="
    echo
    
    check_not_root
    
    # Ask for confirmation
    read -p "This will install and configure Sway desktop. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    
    # Create log file
    touch "$LOG_FILE"
    
    # Run installation steps
    backup_configs
    install_packages
    install_aur_packages
    create_directories
    install_configs
    configure_system
    setup_user
    enable_services
    setup_fingerprint
    post_install_message
}

# Run main function
main "$@"
