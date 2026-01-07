import Foundation
import IOBluetooth

@_silgen_name("IOBluetoothPreferenceSetControllerPowerState")
func setBluetoothPower(_ state: Int32)

// Trigger permission prompt on startup (ensures Bluetooth is on)
setBluetoothPower(1)

let center = DistributedNotificationCenter.default()

center.addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: nil) { _ in
    setBluetoothPower(0)
}

center.addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: nil) { _ in
    setBluetoothPower(1)
}

RunLoop.current.run()
