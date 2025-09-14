# iPowerMenu

A macOS menu bar application that displays solar power generation and battery state of charge from Home Assistant.

## Features

- **Menu Bar Display**: Shows solar watts and battery SOC with SF Symbols in the menu bar
- **Auto-refresh**: Configurable refresh interval (default 30 seconds)
- **Settings UI**: Easy configuration of Home Assistant connection and entity IDs
- **First-run Setup**: Automatically opens settings on first launch
- **Connection Testing**: Verify your Home Assistant connection before saving

## Installation

### Option 1: Download Release (Recommended)

1. Go to [Releases](https://github.com/ICULikeMac/iPowerMenu/releases)
2. Download the latest `iPowerMenu-x.x.x.dmg` file
3. Open the DMG and drag iPowerMenu.app to your Applications folder
4. Launch iPowerMenu from Applications

### Option 2: Build from Source

```bash
git clone https://github.com/ICULikeMac/iPowerMenu.git
cd iPowerMenu
swift build
swift run
```

### Option 3: Build Distribution Package

```bash
# Build app bundle
./build-app.sh

# Create DMG for distribution
./create-dmg.sh
```

## Setup

### 1. Configure Home Assistant

When you first run the app, the settings window will open automatically. You'll need to provide:

- **Home Assistant URL**: Your Home Assistant instance URL (e.g., `http://homeassistant.local:8123`)
- **Access Token**: A long-lived access token from Home Assistant
- **Solar Entity ID**: The entity ID for your solar power sensor (e.g., `sensor.solar_power`)
- **Battery Entity ID**: The entity ID for your battery SOC sensor (e.g., `sensor.battery_soc`)

### 2. Getting a Home Assistant Access Token

1. Log into your Home Assistant web interface
2. Click on your username in the bottom left
3. Scroll down to "Long-lived access tokens"
4. Click "Create Token"
5. Give it a name (e.g., "Menu Bar App")
6. Copy the token and paste it into the app settings

### 3. Finding Entity IDs

1. In Home Assistant, go to Developer Tools > States
2. Search for your solar and battery sensors
3. Copy the entity IDs (they look like `sensor.solar_power` or `sensor.battery_soc`)

## Menu Bar Features

- **Status Display**: Shows current solar watts and battery percentage
- **Click Menu**: Right-click or left-click to see detailed values and options
- **Refresh**: Manual refresh option in the menu
- **Settings**: Access configuration at any time
- **Connection Status**: Visual indicator of Home Assistant connection

## Display Format

The menu bar shows a stacked display similar to iStat Menus using SF Symbols:

```
☀️ 1250w
🏠 85%
```

- ☀️ (sun.min SF Symbol) indicates solar power generation in watts  
- 🏠 (bolt.house SF Symbol) indicates battery state of charge as percentage  
- Values are displayed vertically stacked for compact, easy reading

## Troubleshooting

- **"Connection Error"**: Check your Home Assistant URL and access token
- **"Entity not found"**: Verify your entity IDs in Home Assistant Developer Tools
- **"---" values**: Check that your sensors are reporting numeric values

## Requirements

- macOS 13.0 or later
- Home Assistant instance with REST API access
- Swift 5.9 or later (for building from source)