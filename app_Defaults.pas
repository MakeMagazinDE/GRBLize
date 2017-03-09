// AppDefaults StringGrid Handler
unit app_defaults;

interface

//uses SysUtils, FTDIdll, FTDIchip, FTDItypes;
uses Classes, Grids;

procedure LoadStringGrid(aGrid: TStringGrid; const my_fileName: string);
function get_AppDefaults_float(sg_row: Integer): double;
function get_AppDefaults_bool(sg_row: Integer): boolean;
function get_AppDefaults_int(sg_row: Integer): Integer;
function get_AppDefaults_str(sg_row: Integer): String;
procedure set_AppDefaults_int(sg_row, new_val: Integer);

implementation

uses
  grbl_com, grbl_player_main, SysUtils, StrUtils;

// AppDefaults StringGrid

procedure LoadStringGrid(aGrid: TStringGrid; const my_fileName: string);
var
  my_StringList, my_Line: TStringList;
  aCol, aRow: Integer;
begin
  aGrid.RowCount := 2; //clear any previous data
  my_StringList := TStringList.Create;
  try
    my_Line := TStringList.Create;
    try
      my_StringList.LoadFromFile(my_fileName);
      aGrid.RowCount := my_StringList.Count;
      for aRow := 0 to my_StringList.Count-1 do
      begin
        my_Line.CommaText := my_StringList[aRow];
        for aCol := 0 to aGrid.ColCount-1 do
          if aCol < my_Line.Count then
            aGrid.Cells[aCol, aRow] := my_Line[aCol]
          else
            aGrid.Cells[aCol, aRow] := '0';
      end;
    finally
      my_Line.Free;
    end;
  finally
    my_StringList.Free;
  end;
end;


function get_AppDefaults_float(sg_row: Integer): double;
begin
  result:= 0;
  if sg_row < Form1.SgAppDefaults.RowCount then
    result:= StrToFloatDef(Form1.SgAppDefaults.Cells[1,sg_row],0);
end;

function get_AppDefaults_bool(sg_row: Integer): boolean;
begin
  result:= false;
  if sg_row < Form1.SgAppDefaults.RowCount then
    result:= Form1.SgAppDefaults.Cells[1,18] = 'ON';
end;

function get_AppDefaults_int(sg_row: Integer): Integer;
begin
  result:= 0;
  if sg_row < Form1.SgAppDefaults.RowCount then
    result:= StrToIntDef(Form1.SgAppDefaults.Cells[1,sg_row],0);
end;

function get_AppDefaults_str(sg_row: Integer): String;
begin
  result:= '';
  if sg_row < Form1.SgAppDefaults.RowCount then
    result:= Form1.SgAppDefaults.Cells[1,sg_row];
end;

procedure set_AppDefaults_int(sg_row, new_val: Integer);
begin
  if sg_row < Form1.SgAppDefaults.RowCount then
    Form1.SgAppDefaults.Cells[1,sg_row]:= IntToStr(new_val);
end;

end.