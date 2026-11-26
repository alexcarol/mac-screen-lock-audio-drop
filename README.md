# mac-screen-lock-audio-drop

Disconnects Bluetooth audio devices when your Mac screen locks and prevents them from reconnecting until you unlock. Input devices (keyboard, mouse) stay connected the entire time.

## Why?

When you lock your Mac near shared Bluetooth headphones or speakers, those audio devices can still connect to it. This tool prevents that by disconnecting audio devices on lock and rejecting any audio connection attempts while locked.

## Installation

### Homebrew

```bash
brew tap alexcarol/mac-screen-lock-audio-drop https://github.com/alexcarol/mac-screen-lock-audio-drop
brew install screen-lock-audio-drop && brew services start screen-lock-audio-drop
```

### Manual

```bash
git clone https://github.com/alexcarol/mac-screen-lock-audio-drop.git
cd mac-screen-lock-audio-drop
./setup.sh
```

## Uninstallation

### Homebrew

```bash
brew uninstall screen-lock-audio-drop
```

### Manual

```bash
./uninstall.sh
```

## How It Works

The tool listens for macOS screen lock/unlock notifications and uses the IOBluetooth framework to:

1. **On lock**: disconnect all connected audio devices and start monitoring for new connections
2. **While locked**: automatically disconnect any audio device that tries to connect
3. **On unlock**: stop monitoring, allowing audio devices to connect freely again

A Bluetooth device counts as an audio device when it provides a CoreAudio input or output (such as `AA-BB-CC-DD-EE-FF:output`), or when IOBluetooth reports the audio class of device for it. While locked, the tool also watches the CoreAudio device list, so headphones that reconnect on their own are dropped again as soon as their audio device appears.

Bluetooth itself stays on, so peripherals like keyboards and mice are never interrupted.

Every lock, unlock and disconnect is logged, together with the reason when nothing was disconnected. With Homebrew the log is `$(brew --prefix)/var/log/screen-lock-audio-drop.log`; with the manual install it is `/tmp/screen-lock-audio-drop.log`.

## Bluetooth Permission

When the tool starts, macOS prompts for Bluetooth access. Allow it for the tool to work. If you miss the prompt, grant it manually in **System Settings > Privacy & Security > Bluetooth** and restart the service. Each rebuild (for example a `brew upgrade`) can ask again.

## Requirements

- macOS
- Xcode Command Line Tools (for building from source)

## License

MIT
