// #############################################################################
// ################################## A T C ####################################
// #############################################################################

procedure SetATCslot(const pen_idx: Integer; atc_idx: integer);
begin
  if atc_idx > c_numATCslots then
    atc_idx:= c_numATCslots; // invalid or manual
  atcArray[atc_idx].isInSpindle:= (ToolInSpindle = atc_idx);
  atcArray[atc_idx].used:= true;
  if (atc_idx > 0) then
    atcArray[atc_idx].pen:= pen_idx;
end;

procedure ClearATCarray;
var
  i: Integer;
begin
// atcArray[0] ist unbenutzt!
  Form1.sgATC.RowCount:= c_numATCslots + 2;
  for i:= 0 to c_numATCslots do begin
    atcArray[i].used:= false;
    atcArray[i].isInSpindle:= false;
    atcArray[i].TREFok:= false;
    atcArray[i].TLCok:= false;
    atcArray[i].TLCdelta:= 0.0;
    atcArray[i].pen:= 0;
  end;
end;

function search_same_tool_in_atc(pen_idx: Integer): Integer;
// liefert Slot-Nummer, wenn gleiches Tool gefunden, ansonsten -1
var i: Integer;
begin
  result:= -1;
  for i := 1 to c_numATCslots do
    if atcArray[i].used and
       not isToolDifferent(pen_idx, atcArray[i].pen) then begin
      result:= i;
      break;
    end;
end;

procedure AutoAssignATCtoolsToJob;
var pen_idx, atc_idx, atc_slot, block_idx, my_len: Integer;
begin
  ClearATCarray;
  my_len:= length(final_array) - 1;
  if my_len < 0 then
    exit;

  atc_slot:= 0;
  for block_idx:= 0 to my_len do begin
    if final_array[block_idx].enable and
       not final_array[block_idx].out_of_work then begin
      pen_idx:= final_array[block_idx].pen;
      atc_idx:= search_same_tool_in_atc(pen_idx);
      if atc_idx < 0 then begin        // nicht gefunden, neuen Slot reservieren
        inc(atc_slot);
        atc_idx:= atc_slot;
      end;
      if atc_idx <= c_numATCslots then begin
        SetATCslot(pen_idx, atc_idx);
        job.pens[pen_idx].atc:= atc_idx;
  //        Form1.Memo1.lines.add('Pen/Tool ' + IntToStr(pen_idx) + ' assigned to ATC #' + IntToStr(atc_slot));
      end else begin
        PlaySound('SYSTEMHAND', 0, SND_ASYNC);
        Form1.Memo1.lines.add('WARNING: ATC full, some tools not assigned');
      end;
    end;
  end;
  JobToPenGridList;
  ToolInSpindle:= 1;
  atcArray[ToolInSpindle].isInSpindle:= true; // ist in der Maschine
  UpdateATC;
  Form1.sgATC.Col:= 1;
  Form1.sgATC.Row:= 1;
  Form1.EditFirstToolDia.Text:= pen_description(atcArray[ToolInSpindle].pen);
  GLSsetToolToATCidx(ToolInSpindle);
  ForceToolPositions(grbl_wpos.x, grbl_wpos.y, grbl_wpos.z);
end;

procedure UpdateATC;
var i: Integer;
  my_str: String;
begin
  with Form1 do begin
    sgATC.rowcount:= c_numATCslots + 1;
    for i:= 1 to c_numATCslots do begin
      if atcArray[i].pen = 0 then
        my_str:='(undefined)'
      else
        my_str:= pen_description(atcArray[i].pen);
      if i = ToolInSpindle then begin
          my_str:= my_str + ' (in spindle) ';
          atcArray[i].isInSpindle:= true;
      end;
      sgATC.cells[0,i]:= IntToStr(i);
      sgATC.cells[1,i]:= my_str;
      if atcArray[i].TREFok then
        sgATC.cells[2,i]:= 'REF ' + FormatFloat('0.00', atcArray[i].TLCref)
      else
        if atcArray[i].TLCok then
          sgATC.cells[2,i]:= 'TLC ' + FormatFloat('0.00', atcArray[i].TLCdelta)
        else
          sgATC.cells[2,i]:= ''
    end;
    sgATC.cells[0,0]:= 'Slot';
    sgATC.cells[1,0]:= 'Tool/Description';
    sgATC.cells[2,0]:= 'REF/TLC';
    sgATC.Col:= 1;
  end;
  GLSneedsATCupdateTimeout:= 1;
end;



procedure TForm1.sgATCDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var my_color: TColor;
begin
  Rect.Left:= Rect.Left-4;    // Workaround für XE8-Darstellung
  if aRow = 0 then with sgATC,Canvas do begin
    Font.Style := [fsBold];
    TextRect(Rect, Rect.Left + 2, Rect.Top + 2, Cells[ACol, ARow]);
  end else with sgATC,Canvas do begin
    case aCol of
    0: // Slot
      begin
        if job.pens[atcArray[aRow].pen].enable then
          my_color:= job.pens[atcArray[aRow].pen].color
        else
          my_color:=clgray;
        InflateRect(Rect, -1, -1);
        Brush.Color := clgray;
        FrameRect(Rect);
        Brush.Color := my_color;
        InflateRect(Rect, -1, -1);
        FillRect(Rect);
        Font.Style := [fsBold];
        TextRect(Rect, Rect.Left + 8, Rect.Top, Cells[ACol, ARow]);
      end;
    1: // Description
      begin
        if aRow = sgATC.Row then begin
          // selected cell
          Brush.Color := clMenuHighlight;
          Font.Color := clHighlightText;
        end else begin
          // cell not selected
          Brush.Color := clWindow;
          Font.Color := clWindowText;
        end;
        TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Cells[ACol, ARow]);
      end;
    end; //case
  end;
end;


procedure TForm1.sgATCSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
begin
  sgATC.invalidate;
end;


// #############################################################################
// ##########################   A T C  B U T T O N S  ##########################
// #############################################################################

function ManualToolchange(atc_idx_old, atc_idx_new: Integer; do_tlc: boolean): boolean;
// zur Wechselposition bewegen, auf Aufnahme eines neuen Werkzeugs warten,
// Werkzeug ausmessen und G92-ProbeOffset setzen
// liefert False wenn abgebrochen
var my_dlg_result, i: integer;
begin
// Neues Werkzeug manuell aufnehmen
  result:= false;
  if isCancelled then
    exit;
  result:= true;
  if atc_idx_old = atc_idx_new then
    exit;
  spindle_on_off(false);
  grbl_moveZ(0, true);  // Z ganz oben, absolut!
  Form1.Memo1.lines.add('Move to manual tool change position');
  grbl_moveXY(job.toolchange_x, job.toolchange_y, true);
  grbl_moveZ(job.toolchange_z, true);
// manuelle Wechselposition
  SendListToGrbl;
  if job.toolchange_pause and
     job.use_fixed_probe then
    my_dlg_result:= MessageDlg('Tool Change Pause. Change tool manually to'
        + #13 + #13 + pen_description(atcArray[atc_idx_new].pen)
        + #13 + #13 + 'Click YES when done and clear machine for TLC,'
        + #13 + 'NO to keep current tool or CANCEL to abort job.'
        + #13 + 'All tools must have same length if TLC disabled.',
          mtConfirmation, mbYesNocancel, 0)
  else
    my_dlg_result:= MessageDlg('Tool Change Pause. Change tool manually to'
        + #13 + #13 + pen_description(atcArray[atc_idx_new].pen)
        + #13 + #13 + 'All tools must have same length since TLC is disabled.'
        + #13 + 'Click YES when done, CANCEL to abort job.',
          mtConfirmation, [mbYes, mbCancel], 0);

  if Form1.Show3DPreview1.checked and (my_dlg_result = mrYES) then
    GLSsetToolToATCidx(atc_idx_new);

  if job.toolchange_pause and
     job.use_fixed_probe and
     (my_dlg_result = mrYES) then begin
    if do_tlc then
      if DoTLCandConfirm(false, atc_idx_new) then begin
        Form1.Memo1.lines.add('Tool changed, new Tool Delta Z applied');
        result:= true;
      end;
  end else begin
    Form1.Memo1.lines.add('Tool not changed, Tool Delta Z retained');
  end;
  if my_dlg_result = mrCANCEL then begin
    result:= false;
    exit;
  end;

  for i:= 0 to c_numATCslots do
    atcArray[i].isInSpindle:= false;
  if (my_dlg_result = mrYES) then begin
    ToolInSpindle:= atc_idx_new;
    UpdateATC;
    Form1.sgATC.Col:= 1;
    Form1.sgATC.row:= atc_idx_new;
  end;
end;

procedure UnloadATCtool(atc_idx: Integer);
// Werkzeug ablegen, Spannzange offen lassen
// liefert TRUE wenn erfolgreich
// tool_idx zählt ab 1
var my_atc_x, my_atc_y: Double;
  atc_pos_idx: Integer;

begin
  atc_pos_idx:= atc_idx - 1;
  spindle_on_off(false);
  my_atc_x:= job.atc_zero_x + (atc_pos_idx * job.atc_delta_x);
  my_atc_y:= job.atc_zero_y + (atc_pos_idx * job.atc_delta_y);
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Unload tool at ATC slot #'+ IntToStr(atc_idx));
  grbl_moveZ(0, true);  // move Z up
  grbl_moveXY(my_atc_x, my_atc_y, true);
  SendListToGrbl;
  grbl_moveZ(job.atc_pickup_z + 10, true);  // move Z down
  grbl_sendlist.add('G4 P0'); // dwell
  grbl_sendlist.add(get_AppDefaults_str(35));  // Ausblasen
  SendListToGrbl;
  atcArray[atc_idx].isInSpindle:= false;
//    atcArray[tool_idx].tool_pen:= tool_idx;
  grbl_moveSlowZ(job.atc_pickup_z, true);  // move Z down
  if Form1.Show3DPreview1.Checked then begin
    GLSupdateATC;
    GLSsetToolDia(0, 0);
  end;
  grbl_sendlist.add('G4 P0'); // dwell
  grbl_moveZ(0, true);     // move Z up
  SendListToGrbl;
  ToolInSpindle:= 0; // kein Tool
  UpdateATC;
  Form1.sgATC.Col:= 1;
  Form1.sgATC.Row:= atc_idx;
end;

procedure LoadATCtool(atc_idx: Integer; do_tlc: boolean);
var my_atc_x, my_atc_y: Double;
  atc_pos_idx: Integer;
begin
// Neues Werkzeug aufnehmen, tool_idx zählt ab 1
  atc_pos_idx:= atc_idx - 1;
  spindle_on_off(false);
  my_atc_x:= job.atc_zero_x + (atc_pos_idx * job.atc_delta_x);
  my_atc_y:= job.atc_zero_y + (atc_pos_idx * job.atc_delta_y);
  Form1.Memo1.lines.add('');
  Form1.Memo1.lines.add('Load tool at ATC slot #'+ IntToStr(atc_idx));
  grbl_moveZ(0, true);  // move Z up
  grbl_moveXY(my_atc_x, my_atc_y, true);
  grbl_moveZ(job.atc_pickup_z + 20, true);  // move Z down
  grbl_moveSlowZ(job.atc_pickup_z, true);  // move Z down
  grbl_sendlist.add('G4 P0'); // dwell
  SendListToGrbl;
  grbl_sendlist.add(get_AppDefaults_str(36));   // Tool aufnehmen
  grbl_sendlist.add('G4 P1'); // dwell
  grbl_moveZ(0, true);  // move Z up
  SendListToGrbl;
  atcArray[atc_idx].isInSpindle:= true;
  if Form1.Show3DPreview1.Checked then begin
    GLSupdateATC;
    GLSsetToolToATCidx(atc_idx);
  end;
  if do_tlc then
    DoTLCandConfirm(false, atc_idx);
  ToolInSpindle:= atc_idx;
  UpdateATC;
  Form1.sgATC.Col:= 1;
  Form1.sgATC.row:= atc_idx;
end;

procedure ChangeATCtool(atc_idx_old, atc_idx_new: Integer; do_tlc: boolean);
// Liefert OK wenn erfolgreich
begin
  if atc_idx_old <> atc_idx_new then begin
    UnloadATCtool(atc_idx_old);
    LoadATCtool(atc_idx_new, do_tlc);
  end;
end;

