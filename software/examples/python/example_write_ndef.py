#!/usr/bin/env python
# -*- coding: utf-8 -*-

HOST = "localhost"
PORT = 4223
UID = "XYZ" # Change XYZ to the UID of your NFC/RFID Bricklet

from tinkerforge.ip_connection import IPConnection
from tinkerforge.bricklet_nfc import BrickletNFC

NDEF_URI = "www.tinkerforge.com"

# Callback function for state changed callback
def cb_state_changed(state, idle, nfc):
    if state == nfc.CARDEMU_STATE_IDLE:
        payload_uri = []

        for c in list(NDEF_URI):
            payload_uri.append(ord(c))

        # Only short records are supported.
        ndef_record_uri = [
                                0xD1,                 # MB/ME/CF/SR=1/IL/TNF
                                0x01,                 # TYPE LENGTH
                                len(payload_uri) + 1, # Length
                                ord("U"),             # Type
                                4                     # Status
                           ]

        for d in payload_uri:
            ndef_record_uri.append(d)

        nfc.cardemu_write_ndef(ndef_record_uri)
        nfc.cardemu_start_discovery()
    elif state == nfc.CARDEMU_STATE_DISCOVER_READY:
        nfc.cardemu_start_transfer(True)
    elif state == nfc.CARDEMU_STATE_DISCOVER_ERROR:
        print "Discover error"
    elif state == nfc.CARDEMU_STATE_TRANSFER_NDEF_ERROR:
        print "Transfer NDEF error"

if __name__ == "__main__":
    ipcon = IPConnection() # Create IP connection
    nfc = BrickletNFC(UID, ipcon) # Create device object

    ipcon.connect(HOST, PORT) # Connect to brickd
    # Don't use device before ipcon is connected

    # Register state changed callback to function cb_state_changed
    nfc.register_callback(nfc.CALLBACK_CARDEMU_STATE_CHANGED,
                          lambda x, y: cb_state_changed(x, y, nfc))

    nfc.set_mode(nfc.MODE_CARDEMU)

    raw_input("Press key to exit\n") # Use input() in Python 3
    ipcon.disconnect()
