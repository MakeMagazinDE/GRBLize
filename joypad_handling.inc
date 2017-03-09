{$IFDEF GRBL_11}
// Joypad-Behandlung für GRBL 1.1 Jogging (erweitert mit direktem Feed Override)
        TimerStatus.Enabled := false;
        JoyPad.update;

{
// Test/Debug Joypad
        LabelJoyInfo.Caption := 'Buttons:';
        for i := 0 to 31 do
          if JoyPad.Buttons[i] then
            LabelJoyInfo.Caption := LabelJoyInfo.Caption + IntToStr(i) + #32;
        LabelJoyInfo.Caption := LabelJoyInfo.Caption + ' POV raw:' +
          IntToStr(JoyPad.POV.raw) + #32;
        if JoyPad.POV.up then
          LabelJoyInfo.Caption := LabelJoyInfo.Caption + 'up ';
        if JoyPad.POV.right then
          LabelJoyInfo.Caption := LabelJoyInfo.Caption + 'right ';
        if JoyPad.POV.left then
          LabelJoyInfo.Caption := LabelJoyInfo.Caption + 'left ';
        if JoyPad.POV.down then
          LabelJoyInfo.Caption := LabelJoyInfo.Caption + 'down ';
        LabelJoyInfo.Caption := LabelJoyInfo.Caption + 'X:' + IntToStr(JoyPad.X)
          + #32 + 'Y:' + IntToStr(JoyPad.Y) + #32 + 'Z:' + IntToStr(JoyPad.Z) +
          #32 + 'R:' + IntToStr(JoyPad.R);
        // Ende Test/Debug Joypad
}
        if JoyPad.POV.active then begin
          repeat
            if JoyPad.POV.right then
              grbl_SendWithShortTimeout('$J=G91X0.05F100');
            if JoyPad.POV.left then
              grbl_SendWithShortTimeout('$J=G91X-0.05F100');
            if JoyPad.POV.up then
              grbl_SendWithShortTimeout('$J=G91Y0.05F100');
            if JoyPad.POV.down then
              grbl_SendWithShortTimeout('$J=G91Y-0.05F100');
            mdelay(50);
            DecodeStatus(grbl_statusStr);
            JoyPad.Update;
          until not JoyPad.POV.active;
          grbl_sendRealTimeCmd(#$85); // Jog Cancel
          TimerStatus.Enabled := true;
        end;

        btn_idx:= get_AppDefaults_int(41);  // ZeroAll Button
        if JoyPad.Buttons[btn_idx] then begin
          // Taste 1, Nullpunkt soll gesetzt werden
          HandleZeroRequest;
          joy_wait_btn_release(btn_idx);
        end;

        btn_idx:= get_AppDefaults_int(42);  // FloodToggle Button
        if JoyPad.Buttons[btn_idx] then begin
          grbl_sendRealTimeCmd(#$A0); // Coolant Toggle
          joy_wait_btn_release(btn_idx);
        end;

        btn_idx:= get_AppDefaults_int(43);  // SpindleToggle Button
        if JoyPad.Buttons[btn_idx] then begin
          grbl_sendRealTimeCmd(#$9E);
          joy_wait_btn_release(btn_idx);
        end;

        btn_idx:= get_AppDefaults_int(44);  // FeedHold Button
        if JoyPad.Buttons[btn_idx] then begin
          grbl_sendRealTimeCmd(#$85);       // Jog Cancel!
          if MachineState = hold then
            grbl_sendRealTimeCmd('~')
          else
            grbl_sendRealTimeCmd('!');
          joy_wait_btn_release(btn_idx);
        end;

        if JoyPad.IsAnalogActive then begin
          LabelJoySend.Caption := 'Active Jog';
          btn_idx:= get_AppDefaults_int(40);  // FastJog Button
          fast_jog:= JoyPad.Buttons[btn_idx];
          if fast_jog then
            feed_str := 'F' + get_AppDefaults_str(37)
          else
            feed_str := 'F' + get_AppDefaults_str(38);

          jog_sent := false;
          feed_old := 0;
          while (JoyPad.X <> 0) and (fast_jog = JoyPad.Buttons[btn_idx]) do begin
            feed_v.X := abs(JoyPad.X) - JoyPad.DeadZone;
            // Joypad-Ergebnis 0 oder zwischen 200 und 1000 bzw. -200 und -1000
            feed := feed_v.X div 57; // auf 0 bis 14 skalieren
            if feed < 1 then
              feed := 1;
            my_str := '';
            if not jog_sent then begin
              grbl_sendRealTimeCmd(Char(feed + $F0)); // Feed Override DIRECT
              if JoyPad.X > 0 then
                my_str := '$J=G53X' + FloatToSTrDot(job.table_x) + feed_str;
              // Tisch-Ende
              if JoyPad.X < 0 then
                my_str := '$J=G53X0' + feed_str; // Richtung Maschinen-Nullpunkt
              grbl_SendWithShortTimeout(my_str);
              LabelJoyInfo.Caption := my_str + ' OVR:' + IntToStr(feed);
            end else if feed <> feed_old then
              grbl_sendRealTimeCmd(Char(feed + $F0)); // Feed Override DIRECT
            feed_old := feed;
            jog_sent := true;
            JoyPad.Update;
            mdelay(10);
            DecodeStatus(grbl_statusStr);
          end;

          jog_sent := false;
          feed_old := 0;
          while (JoyPad.Y <> 0) and (fast_jog = JoyPad.Buttons[btn_idx]) do begin
            // Joypad-Ergebnis 0 oder zwischen 200 und 1000 bzw. -200 und -1000
            feed_v.Y := abs(JoyPad.Y) - JoyPad.DeadZone;
            feed := feed_v.Y div 57; // auf 0 bis 14 skalieren
            if feed < 1 then
              feed := 1;
            my_str := '';
            if not jog_sent then begin
              grbl_sendRealTimeCmd(Char(feed + $F0)); // Feed Override DIRECT
              if JoyPad.Y > 0 then // Joystick nach oben ist Minus!
                my_str := '$J=G53Y0' + feed_str; // Richtung Maschinen-Nullpunkt
              if JoyPad.Y < 0 then
                my_str := '$J=G53Y' + FloatToSTrDot(job.table_x) + feed_str;
              // Tisch-Ende
              grbl_SendWithShortTimeout(my_str);
              LabelJoyInfo.Caption := my_str + ' OVR:' + IntToStr(feed);
            end else if feed <> feed_old then
              grbl_sendRealTimeCmd(Char(feed + $F0)); // Feed Override DIRECT
            feed_old := feed;
            jog_sent := true;
            JoyPad.Update;
            mdelay(10);
            DecodeStatus(grbl_statusStr);
          end;

          jog_sent := false;
          feed_old := 0;
          z_temp:= joy_get_swapped_z;
          while (z_temp <> 0) and (fast_jog = JoyPad.Buttons[btn_idx]) do begin
             // Joypad-Ergebnis 0 oder zwischen 200 und 1000 bzw. -200 und -1000
            feed_v.Z := abs(z_temp) - JoyPad.DeadZone;
            feed := feed_v.Z div 100; // auf 0 bis 14 skalieren
            if feed < 1 then
              feed := 1;
            feed_old := feed;
            my_str := '';
            if not jog_sent then begin
              grbl_sendRealTimeCmd(Char(feed + $F0)); // Feed Override DIRECT
              if z_temp > 0 then
                // Joystick nach oben ist Minus!
                my_str := '$J=G53Z-' + FloatToSTrDot(abs(job.table_z))
                  + feed_str;
              // Tisch-Ende
              if z_temp < 0 then
                my_str := '$J=G53Z0' + feed_str;
              // Richtung Maschinen-Nullpunkt (oben)
              grbl_SendWithShortTimeout(my_str);
              JoyPad.Update;
              z_temp:= joy_get_swapped_z;
              LabelJoyInfo.Caption := my_str + ' OVR:' + IntToStr(feed) + #32 + feed_str;
             end else if feed <> feed_old then
              grbl_sendRealTimeCmd(Char(feed + $F0)); // Feed Override DIRECT
            feed_old := feed;
            jog_sent:= true;
            JoyPad.Update;
            z_temp:= joy_get_swapped_z;
            mdelay(10);
            DecodeStatus(grbl_statusStr);
          end;
          LabelJoySend.Caption := 'Cancel Jog';
          grbl_sendRealTimeCmd(#$85); // Jog Cancel
          grbl_sendRealTimeCmd(#$90); // Feed Reset
        end;
        TimerStatus.Enabled := true;
{$ENDIF}
