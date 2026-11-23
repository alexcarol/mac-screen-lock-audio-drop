import CoreAudio
import Foundation
import IOBluetooth

setvbuf(stdout, nil, _IOLBF, 0)

let kBluetoothAudioMajorClass: UInt32 = 0x04

let timestampFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = .current
    return formatter
}()

func log(_ message: String) {
    print("\(timestampFormatter.string(from: Date())) \(message)")
}

func describe(_ device: IOBluetoothDevice) -> String {
    return "\(device.name ?? "unnamed device") (\(device.addressString ?? "no address"))"
}

func normalizedAddress(_ address: String) -> String {
    return address.lowercased().replacingOccurrences(of: ":", with: "-")
}

func isBluetoothAddress(_ address: String) -> Bool {
    let parts = address.split(separator: "-", omittingEmptySubsequences: false)
    return parts.count == 6 && parts.allSatisfy { $0.count == 2 && $0.allSatisfy(\.isHexDigit) }
}

let audioDevicesProperty = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                                      mScope: kAudioObjectPropertyScopeGlobal,
                                                      mElement: kAudioObjectPropertyElementMain)

func audioProperty<T>(_ object: AudioObjectID, _ selector: AudioObjectPropertySelector, _ value: inout T) -> Bool {
    var address = AudioObjectPropertyAddress(mSelector: selector,
                                             mScope: kAudioObjectPropertyScopeGlobal,
                                             mElement: kAudioObjectPropertyElementMain)
    var size = UInt32(MemoryLayout<T>.size)
    return withUnsafeMutableBytes(of: &value) { buffer in
        AudioObjectGetPropertyData(object, &address, 0, nil, &size, buffer.baseAddress!) == noErr
    }
}

/// Addresses of Bluetooth devices that currently provide a CoreAudio input or output. Such a device is
/// an audio device whatever class of device or connection state IOBluetooth reports for it.
func bluetoothAudioAddresses() -> Set<String> {
    let system = AudioObjectID(kAudioObjectSystemObject)
    var address = audioDevicesProperty
    var size: UInt32 = 0
    guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else {
        log("warning: could not read the CoreAudio device list; only the Bluetooth class of device is checked")
        return []
    }
    var devices = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
    guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &devices) == noErr else {
        log("warning: could not read the CoreAudio device list; only the Bluetooth class of device is checked")
        return []
    }

    var addresses = Set<String>()
    for device in devices {
        var transport: UInt32 = 0
        guard audioProperty(device, kAudioDevicePropertyTransportType, &transport),
              transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE
        else { continue }
        var uid: Unmanaged<CFString>?
        guard audioProperty(device, kAudioDevicePropertyDeviceUID, &uid), let uid else {
            log("warning: could not read the UID of Bluetooth audio device \(device); it can't be disconnected")
            continue
        }
        let uidString = uid.takeRetainedValue() as String
        let candidate = normalizedAddress(String(uidString.prefix(17)))
        if isBluetoothAddress(candidate) {
            addresses.insert(candidate)
        } else {
            log("warning: Bluetooth audio device UID \(uidString) holds no Bluetooth address; it can't be disconnected")
        }
    }
    return addresses
}

func disconnectAudioDevices(_ trigger: String, audioAddresses: Set<String> = bluetoothAudioAddresses()) {
    let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
    if paired.isEmpty {
        log("\(trigger): no paired Bluetooth devices visible. If there are some, allow Bluetooth access in "
            + "System Settings > Privacy & Security > Bluetooth and restart the service")
    }

    var devices = paired
    let pairedAddresses = Set(paired.compactMap { $0.addressString.map(normalizedAddress) })
    for address in audioAddresses.subtracting(pairedAddresses) {
        if let device = IOBluetoothDevice(addressString: address) {
            devices.append(device)
        } else {
            log("\(trigger): Bluetooth audio device \(address) is not known to IOBluetooth; it can't be disconnected")
        }
    }
    if devices.isEmpty { return }

    var states: [String] = []
    var handled = false
    for device in devices {
        let address = device.addressString.map(normalizedAddress)
        let providesAudio = address.map { audioAddresses.contains($0) } ?? false
        let connected = device.isConnected()
        let audioClass = device.deviceClassMajor == kBluetoothAudioMajorClass
        states.append("\(describe(device)) connected=\(connected) class=0x\(String(device.deviceClassMajor, radix: 16)) coreAudio=\(providesAudio)")
        guard providesAudio || (connected && audioClass) else { continue }

        handled = true
        let result = device.closeConnection()
        if result == kIOReturnSuccess {
            log("\(trigger): disconnected \(describe(device))")
        } else {
            log("\(trigger): failed to disconnect \(describe(device)): IOReturn 0x\(String(UInt32(bitPattern: result), radix: 16))")
        }
    }
    if !handled {
        log("\(trigger): no connected Bluetooth audio device. Paired: \(states.joined(separator: "; "))")
    }
}

/// Observer that intercepts and rejects audio device connections while locked
class BluetoothGuard: NSObject {
    @objc func onConnect(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        disconnectAudioDevices("\(describe(device)) connected while locked")
    }
}

/// Notification token for the connection listener (nil when unlocked)
var connectionNotification: IOBluetoothUserNotification?

/// Whether the CoreAudio device list listener is installed (only while locked)
var audioListenerInstalled = false

let guard_ = BluetoothGuard()

/// A2DP and HFP devices appear in CoreAudio shortly after the Bluetooth connection, so this catches
/// audio devices that connect while locked even when the IOBluetooth connect notification misses them.
let audioDevicesChanged: AudioObjectPropertyListenerBlock = { _, _ in
    let audioAddresses = bluetoothAudioAddresses()
    if !audioAddresses.isEmpty {
        disconnectAudioDevices("Bluetooth audio device appeared while locked", audioAddresses: audioAddresses)
    }
}

let center = DistributedNotificationCenter.default()

center.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: nil) { _ in
    log("Screen locked")
    if connectionNotification == nil {
        connectionNotification = IOBluetoothDevice.register(forConnectNotifications: guard_,
                                                             selector: #selector(BluetoothGuard.onConnect(_:device:)))
        if connectionNotification == nil {
            log("warning: could not register for Bluetooth connect notifications")
        }
    }
    if !audioListenerInstalled {
        var address = audioDevicesProperty
        let status = AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address,
                                                         DispatchQueue.main, audioDevicesChanged)
        audioListenerInstalled = status == noErr
        if !audioListenerInstalled {
            log("warning: could not watch CoreAudio devices (OSStatus \(status)); audio devices that connect while locked may stay connected")
        }
    }
    disconnectAudioDevices("lock")
}

center.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: nil) { _ in
    log("Screen unlocked")
    connectionNotification?.unregister()
    connectionNotification = nil
    if audioListenerInstalled {
        var address = audioDevicesProperty
        AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address,
                                               DispatchQueue.main, audioDevicesChanged)
        audioListenerInstalled = false
    }
}

// Touch IOBluetooth at startup so macOS asks for Bluetooth access now, while the user can answer,
// instead of at the first lock.
let pairedAtStart = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
log("Started; \(pairedAtStart.count) paired Bluetooth devices visible")
if pairedAtStart.isEmpty {
    log("warning: no paired Bluetooth devices visible. If there are some, allow Bluetooth access in "
        + "System Settings > Privacy & Security > Bluetooth and restart the service")
}

RunLoop.current.run()
