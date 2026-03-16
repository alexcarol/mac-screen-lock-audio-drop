import Foundation
import IOBluetooth

@_silgen_name("IOBluetoothPreferenceSetControllerPowerState")
func setBluetoothPower(_ state: Int32)

/// Addresses of devices that were connected before screen lock
var connectedAddresses: [String] = []

func saveConnectedDevices() {
    guard let paired = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return }
    connectedAddresses = paired.filter { $0.isConnected() }.compactMap { $0.addressString }
}

func reconnectDevices() {
    for address in connectedAddresses {
        guard let device = IOBluetoothDevice(addressString: address) else { continue }
        DispatchQueue.global(qos: .userInitiated).async {
            device.openConnection()
        }
    }
}

// Trigger permission prompt on startup (ensures Bluetooth is on)
setBluetoothPower(1)

let center = DistributedNotificationCenter.default()

center.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: nil) { _ in
    saveConnectedDevices()
    setBluetoothPower(0)
}

center.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: nil) { _ in
    setBluetoothPower(1)
    // Give the controller a moment to power on before reconnecting
    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.0) {
        reconnectDevices()
    }
}

RunLoop.current.run()
