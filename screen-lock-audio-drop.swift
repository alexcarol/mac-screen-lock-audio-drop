import Foundation
import IOBluetooth

let kBluetoothAudioMajorClass: UInt32 = 0x04

/// Notification token for the connection listener (nil when unlocked)
var connectionNotification: IOBluetoothUserNotification?

func isAudioDevice(_ device: IOBluetoothDevice) -> Bool {
    return device.deviceClassMajor == kBluetoothAudioMajorClass
}

func disconnectAudioDevices() {
    guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return }
    for device in paired where device.isConnected() && isAudioDevice(device) {
        device.closeConnection()
    }
}

/// Observer that intercepts and rejects audio device connections while locked
class BluetoothGuard: NSObject {
    @objc func onConnect(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        if isAudioDevice(device) {
            device.closeConnection()
        }
    }
}

let guard_ = BluetoothGuard()
let center = DistributedNotificationCenter.default()

center.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: nil) { _ in
    disconnectAudioDevices()
    connectionNotification = IOBluetoothDevice.register(forConnectNotifications: guard_,
                                                         selector: #selector(BluetoothGuard.onConnect(_:device:)))
}

center.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: nil) { _ in
    connectionNotification?.unregister()
    connectionNotification = nil
}

RunLoop.current.run()
