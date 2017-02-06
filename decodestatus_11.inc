// Version für GRBL 1.1

function DecodeStatus(my_response: String; var pos_changed: Boolean): Boolean;
// liefert Busy-Status TRUE wenn GRBL-Status nicht IDLE ist
// setzt pos_changed wenn sich Position änderte

// Format ab GRBL 1.1:
// Meldung <Idle|MPos:0.000,0.000,0.000|FS:0,0|WCO:0.000,-10.000,3.000>
// oder    <Idle|MPos:0.000,0.000,0.000|FS:0,0|Ov:100,100,100>
// oder    <Idle|MPos:0.000,0.000,0.000|FS:0,0>
// 1 Zeichen dauert bei 115200 Bd 1/11520 s = ca. 0,086 ms, d.h. 7 ms für gesamten Satz
// 1 Zeichen dauert bei 19200  Bd 1/1920 s  = ca. 0,5 ms,   d.h. 35 ms für gesamten Satz

var
  my_str: String;
  i: Integer;
  is_valid, is_jogging: Boolean;
  sl_fields, sl_values: TSTringList;
begin
  sl_fields:= TStringList.Create;
  sl_values:= TStringList.Create;
  result:= false;
  pos_changed:= false;
  try
    if (pos('>', my_response) = 0) then begin  // nicht vollständig
      inc(ResponseFaultCounter);
      exit;
    end;
    if (my_response[1] = '<') then begin
      my_response:= StringReplace(my_response,'<','',[rfReplaceAll]);
      my_response:= StringReplace(my_response,'>','',[rfReplaceAll]);
      my_response:= StringReplace(my_response,':',',',[rfReplaceAll]);
    end else begin                             // nicht vollständig
      inc(ResponseFaultCounter);
      exit;
    end;
    is_valid:= false;
    with Form1 do begin
      sl_fields.delimiter:= '|';
      sl_fields.DelimitedText:= my_response;
      if sl_fields.Count < 2 then
        exit;   // Meldung fehlerhaft

      if AliveCount >= 7 then
        AliveIndicatorDirection:= false;
      if AliveCount <= 0 then
        AliveIndicatorDirection:= true;
      if AliveIndicatorDirection then
        inc(AliveCount)
      else
        dec(AliveCount);
      ShowAliveState(LastAliveState);

      my_Str:= sl_fields[0];
      if (my_Str = 'Idle') or (my_Str = 'Zero') then begin
        PanelReady.Color:= clLime;
        PanelReady.Font.Color:= clwhite;
        is_valid:= true;
        if (my_Str = 'Zero') then
          MachineState:= zero
        else
          MachineState:= idle;
      end else begin
        PanelReady.Color:= $00004000;
        PanelReady.Font.Color:= clgray;
      end;

      if (my_Str = 'Queue') or (my_Str =  'Hold') then begin
        is_valid:= true;
        PanelHold.Color:= clAqua;
        PanelHold.Font.Color:= clwhite;
        result:= true;
        MachineState:= hold;
      end else begin
        PanelHold.Color:= $00400000;
        PanelHold.Font.Color:= clgray;
      end;

      is_jogging:= AnsiContainsStr(my_Str,'Jog');
      if (my_Str = 'Run') or is_jogging then begin
        is_valid:= true;
        PanelRun.Color:= clFuchsia;
        PanelRun.Font.Color:= clwhite;
        result:= true;
        MachineState:= run;
      end else begin
        PanelRun.Color:= $00400040;
        PanelRun.Font.Color:= clgray;
      end;

      if my_Str = 'Alarm' then begin
        is_valid:= true;
        PanelAlarm.Color:= clRed;
        PanelAlarm.Font.Color:= clwhite;
        MachineState:= alarm;
        HomingPerformed:= false;
      end else begin
        PanelAlarm.Color:= $00000040;
        PanelAlarm.Font.Color:= clgray;
      end;

      // keine gültige Statusmeldung?
      if not is_valid then begin
        inc(ResponseFaultCounter);
        exit;
      end;

// Meldung <Idle|MPos:0.000,0.000,0.000|FS:0,0|WCO:0.000,-10.000,3.000>
// oder    <Idle|MPos:0.000,0.000,0.000|FS:0,0|Ov:100,100,100>
// oder    <Idle|MPos:0.000,0.000,0.000|FS:0,0>
// Doppelpunkt ist jetzt Komma, String davor zählt als values-Feld mit
      for i := 1 to sl_fields.count - 1 do begin
        sl_values.clear;
        sl_values.delimiter:= ',';
        sl_values.DelimitedText:= sl_fields[i];
        if (sl_values.count > 3) and (sl_values[0] = 'MPos') then begin
          grbl_mpos.x:= StrDotToFloat(sl_values[1]);
          grbl_mpos.y:= StrDotToFloat(sl_values[2]);
          grbl_mpos.z:= StrDotToFloat(sl_values[3]);
          grbl_wpos.x:= grbl_mpos.x - grbl_wco.x;
          grbl_wpos.y:= grbl_mpos.y - grbl_wco.y;
          grbl_wpos.z:= grbl_mpos.z - grbl_wco.z;
          DisplayWorkPosition;
        end;
        if (sl_values.count > 3) and (sl_values[0] = 'WCO') then begin
          grbl_wco.x:= StrDotToFloat(sl_values[1]);
          grbl_wco.y:= StrDotToFloat(sl_values[2]);
          grbl_wco.z:= StrDotToFloat(sl_values[3]);
          DisplayMachinePosition;
        end;
        if (sl_values.count > 2) and (sl_values[0] = 'FS') then begin
          grbl_feed:= StrToIntDef(sl_values[1], 0);
          grbl_speed:= StrToIntDef(sl_values[2], 0);
        end;
        if (sl_values.count > 1) and (sl_values[0] = 'F') then begin
          grbl_feed:= StrToIntDef(sl_values[1], 0);
        end;
        if (sl_values.count > 2) and (sl_values[0] = 'Ov') then begin
          grbl_feed_ov:= StrToIntDef(sl_values[1], 100);
          grbl_seek_ov:= StrToIntDef(sl_values[2], 100);
          grbl_speed_ov:= StrToIntDef(sl_values[3], 100);
        end;
      end;
    end;
  finally
    sl_fields.free;
    sl_values.free;
  end;
  if (MachineState = run) or (old_grbl_wpos.X <> grbl_wpos.X)
     or (old_grbl_wpos.Y <> grbl_wpos.Y) then begin
    pos_changed:= true;
    old_grbl_wpos:= grbl_wpos;
    NeedsRedraw:= true;
  end;
end;
