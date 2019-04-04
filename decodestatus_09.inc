// Version für GRBL 0.9j und 0.9ks

function GetStatus09: Boolean;
// liefert Busy-Status TRUE wenn GRBL-Status nicht IDLE ist
// setzt pos_changed wenn sich Position änderte

// Format ab GRBL 0.9j:
// <Idle,MPos:40.001,35.989,-19.999,WPos:40.001,35.989,-19.999>  3-stellig, 61 Zeichen
// <Idle,MPos:40.00,35.98,-19.99,WPos:40.00,35.98,-19.99>  2-stellig 55 Zeichen
// 1 Zeichen dauert bei 115200 Bd 1/11520 s = ca. 0,086 ms, d.h. 7 ms für gesamten Satz
// 1 Zeichen dauert bei 19200  Bd 1/1920 s  = ca. 0,5 ms,   d.h. 35 ms für gesamten Satz

var
  my_str: String;
  my_start_idx: Integer;
  is_valid, is_jogging: Boolean;
  sl_values: TSTringList;
  my_response: String;

  begin
    sl_values:= TStringList.Create;
  try
    my_response:= grbl_statusStr; // anfordern
    result:= false;
    if (pos('>', my_response) = 0) then begin
      grbl_wait_for_timeout(50);
      inc(StatusFaultCounter);  // nicht vollständig
      Form1.LabelResponse.Caption:= my_response;
      my_response:= grbl_statusStr; // nochmals anfordern
    end;

    if (length(my_response) > 1) and (my_response[1] = '<') then begin
      my_response:= StringReplace(my_response,'<','',[rfReplaceAll]);
      my_response:= StringReplace(my_response,'>','',[rfReplaceAll]);
      my_response:= StringReplace(my_response,':',',',[rfReplaceAll]);
    end else begin                             // nicht vollständig
      inc(StatusFaultCounter);
      exit;
    end;
    is_valid:= false;
    with Form1 do begin
      sl_values.clear;
      sl_values.CommaText:= my_response;
      if sl_values.Count < 2 then
        exit;   // Meldung fehlerhaft
      my_Str:= sl_values[0];
      if AliveCount >= 7 then
        AliveIndicatorDirection:= false;
      if AliveCount <= 0 then
        AliveIndicatorDirection:= true;
      if AliveIndicatorDirection then
        inc(AliveCount)
      else
        dec(AliveCount);
      ShowAliveState(LastAliveState);

      if (my_Str = 'Idle') or (my_Str = 'Zero') then begin
        PanelReady.Color:= clLime;
        PanelReady.Font.Color:= clwhite;
        is_valid:= true;
        if (my_Str = 'Zero') then begin
          MachineState:= zero;
          HandleZeroRequest(7);
        end else
          MachineState:= idle;
      end else begin
        PanelReady.Color:= $00004000;
        PanelReady.Font.Color:= clgray;
      end;

      if (my_Str = 'Queue') or (my_Str =  'Hold') then begin
        is_valid:= true;
        PanelHold.Color:= clAqua;
        PanelHold.Font.Color:= clwhite;
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
        inc(StatusFaultCounter);
        exit;
      end;
      if is_jogging then begin  // Kurzmeldung von GRBL-JOG 0.9j
        if my_Str = 'JogX' then begin
          grbl_wpos.x:= StrDotToFloat(sl_values[1]);
          PosX.Caption:= FormatFloat('000.00', grbl_wpos.x);
          PosX_2.Caption:= PosX.Caption;
        end;
        if my_Str = 'JogY' then begin
          grbl_wpos.y:= StrDotToFloat(sl_values[1]);
          PosY.Caption:= FormatFloat('000.00', grbl_wpos.y);
          PosY_2.Caption:= PosY.Caption;
        end;
        if my_Str = 'JogZ' then begin
          grbl_wpos.z:= StrDotToFloat(sl_values[1]);
          PosZ.Caption:= FormatFloat('000.00', grbl_wpos.z);
          PosZ_2.Caption:= PosZ.Caption;
        end;
      end else begin
        my_start_idx:= sl_values.IndexOf('MPos');
        if my_start_idx >= 0 then begin
          grbl_mpos.x:= StrDotToFloat(sl_values[my_start_idx+1]);
          grbl_mpos.y:= StrDotToFloat(sl_values[my_start_idx+2]);
          grbl_mpos.z:= StrDotToFloat(sl_values[my_start_idx+3]);
          DisplayMachinePosition;
        end;
        my_start_idx:= sl_values.IndexOf('WPos');
        if my_start_idx >= 0 then begin
          grbl_wpos.x:= StrDotToFloat(sl_values[my_start_idx+1]);
          grbl_wpos.y:= StrDotToFloat(sl_values[my_start_idx+2]);
          grbl_wpos.z:= StrDotToFloat(sl_values[my_start_idx+3]);
          DisplayWorkPosition;
        end;

      end;
    end;
  finally
    sl_values.free;
  end;

  if (MachineState = run) or (old_grbl_wpos.X <> grbl_wpos.X)
     or (old_grbl_wpos.Y <> grbl_wpos.Y) then begin
    result:= true;
    old_grbl_wpos:= grbl_wpos;
    NeedsRedraw:= true;
  end;
end;
