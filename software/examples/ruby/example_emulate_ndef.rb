#!/usr/bin/env ruby
# -*- ruby encoding: utf-8 -*-

require 'tinkerforge/ip_connection'
require 'tinkerforge/bricklet_nfc'

include Tinkerforge

HOST = 'localhost'
PORT = 4223
UID = 'XYZ' # Change XYZ to the UID of your NFC Bricklet
NDEF_URI = 'www.tinkerforge.com'

ipcon = IPConnection.new # Create IP connection
nfc = BrickletNFC.new UID, ipcon # Create device object

ipcon.connect HOST, PORT # Connect to brickd
# Don't use device before ipcon is connected

# Register cardemu state changed callback
nfc.register_callback(BrickletNFC::CALLBACK_CARDEMU_STATE_CHANGED) do |state, idle|
  if state == BrickletNFC::CARDEMU_STATE_IDLE
    # Only short records are supported.
    ndef_record_uri = [
        0xD1,                # MB/ME/CF/SR=1/IL/TNF
        0x01,                # TYPE LENGTH
        NDEF_URI.length + 1, # Length
        'U'.ord,             # Type
        4                    # Status
    ]

    NDEF_URI.split('').each do |c|
      ndef_record_uri.push c.ord
    end

    nfc.cardemu_write_ndef ndef_record_uri
    nfc.cardemu_start_discovery
  elsif state == BrickletNFC::CARDEMU_STATE_DISCOVER_READY
    nfc.cardemu_start_transfer BrickletNFC::CARDEMU_TRANSFER_WRITE
  elsif state == BrickletNFC::CARDEMU_STATE_DISCOVER_ERROR
    puts "Discover error"
  elsif state == BrickletNFC::CARDEMU_STATE_TRANSFER_NDEF_ERROR
    puts "Transfer NDEF error"
  end
end

# Enable cardemu mode
nfc.set_mode BrickletNFC::MODE_CARDEMU

puts 'Press key to exit'
$stdin.gets
ipcon.disconnect
