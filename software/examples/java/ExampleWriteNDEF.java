import com.tinkerforge.IPConnection;
import com.tinkerforge.BrickletNFC;

public class ExampleWriteNDEF {
	private static final String HOST = "localhost";
	private static final int PORT = 4223;

	// Change XYZ to the UID of your NFC Bricklet
	private static final String UID = "XYZ";
	private static final String NDEF_URI = "www.tinkerforge.com";

	// Note: To make the example code cleaner we do not handle exceptions. Exceptions
	//       you might normally want to catch are described in the documentation
	public static void main(String args[]) throws Exception {
		IPConnection ipcon = new IPConnection(); // Create IP connection
		BrickletNFC nfc = new BrickletNFC(UID, ipcon); // Create device object

		ipcon.connect(HOST, PORT); // Connect to brickd
		// Don't use device before ipcon is connected

		// Add state changed listener
		nfc.addCardemuStateChangedListener(new BrickletNFC.CardemuStateChangedListener() {
			public void cardemuStateChanged(int state, boolean idle) {
				if (state == BrickletNFC.CARDEMU_STATE_IDLE) {
					try {
						int[] NDEFRecordURI = new int[NDEF_URI.toCharArray().length + 5];

						// Only short records are supported
						NDEFRecordURI[0] = 0xD1;                              // MB/ME/CF/SR=1/IL/TNF
						NDEFRecordURI[1] = 0x01;                              // TYPE LENGTH
						NDEFRecordURI[2] = NDEF_URI.toCharArray().length + 1; // Length
						NDEFRecordURI[3] = (int)'U';                          // Type
						NDEFRecordURI[4] = 0x04;                              // Status

						for (int i = 0; i < NDEF_URI.toCharArray().length; i++) {
							NDEFRecordURI[5 + i] = (int)NDEF_URI.toCharArray()[i];
						}

						nfc.cardemuWriteNdef(NDEFRecordURI);
						nfc.cardemuStartDiscovery();
					}
					catch (Exception e) {
						return;
					}
				}
				else if(state == BrickletNFC.CARDEMU_STATE_DISCOVER_READY) {
					try{
						nfc.cardemuStartTransfer(1);
					}
					catch (Exception e) {
						return;
					}
				}
				else if (state == BrickletNFC.CARDEMU_STATE_DISCOVER_ERROR) {
					System.out.println("Discover error");
				}
				else if (state == BrickletNFC.CARDEMU_STATE_TRANSFER_NDEF_ERROR) {
					System.out.println("Transfer NDEF error");
				}
				else if (state == BrickletNFC.READER_STATE_REQUEST_TAG_ID_ERROR) {
					System.out.println("Request tag ID error");
				}
			}
		});

		nfc.setMode(BrickletNFC.MODE_CARDEMU);

		System.out.println("Press key to exit"); System.in.read();
		ipcon.disconnect();
	}
}
