//##############################################################################
// TGamepad, Joystick
// http://www.delphipraxis.net/71569-gamepad-joystick-abfragen.html
//##############################################################################

function TGamepad.GetX:integer;
begin
  result := round(range/32767*(Device.wXpos-CenterX));
  if abs(result) <=  deadzone then result := 0;
end;

function TGamepad.GetY:integer;
begin
  result := round(range/32767*(Device.wYpos-CenterY));
  if abs(result) <= deadzone then result := 0;
end;

function TGamepad.GetZ:integer;
begin
  result := round(range/32767*(Device.wZpos-CenterZ));
  if abs(result) <= deadzone then result := 0;
end;

function TGamepad.GetR:integer;
begin
  result := round(range/32767*(Device.dwRpos-CenterR));
  if abs(result) <= deadzone then result := 0;
end;

function TGamepad.GetU:integer;
begin
  result := round(range/32767*(Device.dwUpos-CenterU));
  if abs(result) <= deadzone then result := 0;
end;

function TGamepad.GetV:integer;
begin
  result := round(range/32767*(Device.dwVpos-CenterV));
  if abs(result) <= deadzone then result := 0;
end;

function TGamepad.GetAnalogActive: Boolean;
begin
  result:= (abs(GetV) > 0) or (abs(GetU) > 0)
    or (abs(GetZ) > 0) or (abs(GetR) > 0)
    or (abs(GetX) > 0) or (abs(GetY) > 0);
end;

function TGamepad.GetPOV:TPOVControl;
begin
  //Verarbeitet die Daten des Steuerkreuzes
  result.up := false;
  result.left := false;
  result.down := false;
  result.right := false;
  result.raw:= Device.dwPOV;
  if Device.dwPOV = 0 then begin result.up := true; end;
  if Device.dwPOV = 4500 then begin result.up := true; result.right := true end;
  if Device.dwPOV = 9000 then begin result.right := true; end;
  if Device.dwPOV = 13500 then begin result.down := true; result.right := true end;
  if Device.dwPOV = 18000 then begin result.down := true; end;
  if Device.dwPOV = 22500 then begin result.down := true; result.left := true; end;
  if Device.dwPOV = 27000 then begin result.left := true; end;
  if Device.dwPOV = 31500 then begin result.left := true; result.up := true; end;
  result.active:= result.up or result.down or result.left or result.right;
end;

procedure TGamepad.Update;
begin
  //Liest die Joystick-Daten ein und schreibt sie in die "Device" Variable
  if (DeviceInfo.wCaps and JOYCAPS_HASZ) <> 0 then
    Device.dwSize := sizeof(tjoyInfoEx);
  Device.dwFlags:=JOY_RETURNALL;
  JoygetposEx(DeviceNr,@device);
end;

procedure TGamepad.UpdateDeviceNr(nr:cardinal);
begin
  //0...15 Devices/Gampads/Joysticks
  FDeviceNr := nr;
  joyGetDevCaps(FDeviceNr, @DeviceInfo, sizeof(DeviceInfo));
end;

constructor TGamepad.Create;
begin
  inherited Create;
  DeviceNr := 0;
  Range := 1000;
  DeadZone := 200;
  Calibrate;
end;

procedure TGamepad.Calibrate;
begin
  //Liest die Nullstellung der Achsen ein
  if (DeviceInfo.wCaps and JOYCAPS_HASZ) <> 0 then
    Device.dwSize := sizeof(tjoyInfoEx);
  Device.dwFlags:=JOY_RETURNCENTERED;
  JoygetposEx(DeviceNr,@device);
  CenterX := device.wXpos;
  CenterY := device.wYpos;
  CenterZ := device.wZpos;
  CenterU := device.dwUpos;
  CenterV := device.dwVpos;
  CenterR := device.dwRpos;
end;

function TGamepad.GetButton(index:integer):boolean;
begin
  //Liest die Position der Buttons ein.
  result := false;
  if index in [0..31] then
    result := device.wbuttons and (1 shl (index)) > 0;
end;

//##############################################################################
