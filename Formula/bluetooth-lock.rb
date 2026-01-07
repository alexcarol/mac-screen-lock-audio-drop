class BluetoothLock < Formula
  desc "Automatically disable Bluetooth when your Mac screen locks"
  homepage "https://github.com/alexcarol/bluetooth-lock"
  url "https://github.com/alexcarol/bluetooth-lock/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "PLACEHOLDER"
  license "MIT"

  depends_on :macos

  def install
    system "swiftc", "-O", "bluetooth-lock.swift", "-o", "bluetooth-lock"
    bin.install "bluetooth-lock"
  end

  service do
    run opt_bin/"bluetooth-lock"
    keep_alive true
    log_path var/"log/bluetooth-lock.log"
    error_log_path var/"log/bluetooth-lock.err"
  end

  def caveats
    <<~EOS
      To start bluetooth-lock now and restart at login:
        brew services start bluetooth-lock

      To stop the service:
        brew services stop bluetooth-lock
    EOS
  end

  test do
    assert_predicate bin/"bluetooth-lock", :executable?
  end
end
