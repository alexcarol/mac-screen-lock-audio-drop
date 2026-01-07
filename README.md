# bluetooth-lock

Automatically disables Bluetooth when your Mac screen locks and re-enables it when you unlock.

## Installation

### Homebrew

```bash
brew tap alexcarol/bluetooth-lock https://github.com/alexcarol/bluetooth-lock
brew install bluetooth-lock && brew services start bluetooth-lock
```

### Manual

```bash
git clone https://github.com/alexcarol/bluetooth-lock.git
cd bluetooth-lock
./setup.sh
```

## Uninstallation

### Homebrew

```bash
brew uninstall bluetooth-lock
```

### Manual

```bash
./uninstall.sh
```

## How It Works

The tool listens for macOS screen lock/unlock notifications (`com.apple.screenIsLocked` and `com.apple.screenIsUnlocked`) and toggles Bluetooth power accordingly using the IOBluetooth framework.

## Requirements

- macOS
- Xcode Command Line Tools (for building from source)

## License

MIT
