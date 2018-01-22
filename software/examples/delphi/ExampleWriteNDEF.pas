program ExampleWriteNDEF;

{$ifdef MSWINDOWS}{$apptype CONSOLE}{$endif}
{$ifdef FPC}{$mode OBJFPC}{$H+}{$endif}

uses
  SysUtils, IPConnection, BrickletNFC;

type
  TExample = class

  private
    ipcon: TIPConnection;
    nfc: TBrickletNFC;

  public
    procedure StateChangedCB(sender: TBrickletNFC;
                             const state: byte;
                             const idle: boolean);
    procedure Execute;
  end;

const
  HOST = 'localhost';
  PORT = 4223;
  UID = 'XYZ'; { Change XYZ to the UID of your NFC Bricklet }
  NDEF_URI = 'www.tinkerforge.com';

var
  e: TExample;

{ Callback procedure for state changed callback }
procedure TExample.StateChangedCB(sender: TBrickletNFC;
                                  const state: byte;
                                  const idle: boolean);
  var i: byte;
  var NDEFRecordURI: Array of Byte;

begin
  if state = BRICKLET_NFC_CARDEMU_STATE_IDLE then begin
    { Only short records are supported } 
    SetLength(NDEFRecordURI, Length(NDEF_URI) + 5);

    NDEFRecordURI[0] := $D1;                  { MB/ME/CF/SR=1/IL/TNF }
    NDEFRecordURI[1] := $01;                  { TYPE LENGTH }
    NDEFRecordURI[2] := Length(NDEF_URI) + 1; { Length }
    NDEFRecordURI[3] := ord('U');             { Type }
    NDEFRecordURI[4] := $04;                  { Status }

    for i := 0 to (Length(NDEF_URI) + 1) do begin
      NDEFRecordURI[5 + i] := ord(NDEF_URI[i + 1]);
    end;

    nfc.CardemuWriteNdef(NDEFRecordURI);
    nfc.CardemuStartDiscovery();
  end
  else if state = BRICKLET_NFC_CARDEMU_STATE_DISCOVER_READY then begin
    sender.CardemuStartTransfer(1);
  end
  else if state = BRICKLET_NFC_CARDEMU_STATE_DISCOVER_ERROR then begin
    WriteLn('Discover error');
  end
  else if state = BRICKLET_NFC_CARDEMU_STATE_TRANSFER_NDEF_ERROR then begin
    WriteLn('Transfer NDEF error');
  end;
end;

procedure TExample.Execute;
begin
  { Create IP connection }
  ipcon := TIPConnection.Create;

  { Create device object }
  nfc := TBrickletNFC.Create(UID, ipcon);

  { Connect to brickd }
  ipcon.Connect(HOST, PORT);
  { Don't use device before ipcon is connected }

  { Register state changed callback to procedure StateChangedCB }
  nfc.OnCardemuStateChanged := {$ifdef FPC}@{$endif}StateChangedCB;

  nfc.SetMode(BRICKLET_NFC_MODE_CARDEMU);

  WriteLn('Press key to exit');
  ReadLn;
  ipcon.Destroy; { Calls ipcon.Disconnect internally }
end;

begin
  e := TExample.Create;
  e.Execute;
  e.Destroy;
end.