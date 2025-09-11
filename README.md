# Home Assistant Menu Bar

A macOS menu bar application that displays solar power generation and battery state of charge from Home Assistant.

## Features

- **Menu Bar Display**: Shows solar watts (⚡️) and battery SOC (🔋) in the menu bar
- **Auto-refresh**: Configurable refresh interval (default 30 seconds)
- **Settings UI**: Easy configuration of Home Assistant connection and entity IDs
- **First-run Setup**: Automatically opens settings on first launch
- **Connection Testing**: Verify your Home Assistant connection before saving

## Setup

### 1. Build and Run

```bash
swift build
swift run
```

### 2. Configure Home Assistant

When you first run the app, the settings window will open automatically. You'll need to provide:

- **Home Assistant URL**: Your Home Assistant instance URL (e.g., `http://homeassistant.local:8123`)
- **Access Token**: A long-lived access token from Home Assistant
- **Solar Entity ID**: The entity ID for your solar power sensor (e.g., `sensor.solar_power`)
- **Battery Entity ID**: The entity ID for your battery SOC sensor (e.g., `sensor.battery_soc`)

### 3. Getting a Home Assistant Access Token

1. Log into your Home Assistant web interface
2. Click on your username in the bottom left
3. Scroll down to "Long-lived access tokens"
4. Click "Create Token"
5. Give it a name (e.g., "Menu Bar App")
6. Copy the token and paste it into the app settings

### 4. Finding Entity IDs

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

The menu bar shows a stacked display similar to iStat Menus:

```
⚡️ 1250w
🔋 85%
```

- ⚡️ indicates solar power generation in watts  
- 🔋 indicates battery state of charge as percentage  
- Values are displayed vertically stacked for compact, easy reading

## Troubleshooting

- **"Connection Error"**: Check your Home Assistant URL and access token
- **"Entity not found"**: Verify your entity IDs in Home Assistant Developer Tools
- **"---" values**: Check that your sensors are reporting numeric values

## Requirements

- macOS 13.0 or later
- Home Assistant instance with REST API access
- Swift 5.9 or later (for building from source)