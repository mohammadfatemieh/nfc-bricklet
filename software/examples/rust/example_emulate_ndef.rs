use std::{error::Error, io, thread};
use tinkerforge::{ipconnection::IpConnection, nfc_bricklet::*};

const HOST: &str = "127.0.0.1";
const PORT: u16 = 4223;
const UID: &str = "XYZ"; // Change XYZ to the UID of your NFC Bricklet
const NDEF_URI: &str = "www.tinkerforge.com";

fn main() -> Result<(), Box<dyn Error>> {
    let ipcon = IpConnection::new(); // Create IP connection
    let nfc_bricklet = NFCBricklet::new(UID, &ipcon); // Create device object

    ipcon.connect(HOST, PORT).recv()??; // Connect to brickd
                                        // Don't use device before ipcon is connected

    //Create listener for cardemu state changed events.
    let cardemu_state_changed_listener = nfc_bricklet.get_cardemu_state_changed_receiver();
    // Spawn thread to handle received events. This thread ends when the nfc_bricklet
    // is dropped, so there is no need for manual cleanup.
    let nfc_bricklet_copy = nfc_bricklet.clone(); //Device objects don't implement Sync, so they can't be shared between threads (by reference). So clone the device and move the copy.
    thread::spawn(move || {
        for event in cardemu_state_changed_listener {
            if event.state == NFC_BRICKLET_CARDEMU_STATE_IDLE {
                let mut ndef_record_udi = vec![0xd1u8, 0x01, NDEF_URI.len() as u8 + 1, 'U' as u8, 0x04];

                // Only short records are supported
                for byte in NDEF_URI.bytes() {
                    ndef_record_udi.push(byte);
                }

                if let Err(e) = nfc_bricklet_copy.cardemu_write_ndef(&ndef_record_udi) {
                    println!("Error while writing ndef {}", e);
                }
                nfc_bricklet_copy.cardemu_start_discovery();
            }
            if event.state == NFC_BRICKLET_CARDEMU_STATE_DISCOVER_READY {
                nfc_bricklet_copy.cardemu_start_transfer(NFC_BRICKLET_CARDEMU_TRANSFER_WRITE);
            } else if event.state == NFC_BRICKLET_CARDEMU_STATE_DISCOVER_ERROR {
                println!("Discover error");
            } else if event.state == NFC_BRICKLET_CARDEMU_STATE_TRANSFER_NDEF_ERROR {
                println!("Transfer NDEF error");
            }
        }
    });

    // Enable cardemu mode
    nfc_bricklet.set_mode(NFC_BRICKLET_MODE_CARDEMU);

    println!("Press enter to exit.");
    let mut _input = String::new();
    io::stdin().read_line(&mut _input)?;
    ipcon.disconnect();
    Ok(())
}
