{ ----------------------------------------------------------------------------
  FTDI D2XX calls
  Copyright (c) Michael "Zipplet" Nixon 2009.
  Licensed under the MIT license, see license.txt in the project trunk.

  Unit: FTDIdll.pas
  Purpose: FTDI DLL calls
  ---------------------------------------------------------------------------- }
unit FTDIdll;

{ ----------------------------------------------------------------------------
  ---------------------------------------------------------------------------- }

interface

uses
  sysutils, windows, messages, classes, bsearchtree, blinklist,
  FTDItypes;

const
    { DLL Name }
    FT_DLL_Name = 'FTD2XX.DLL';

  { ----------------------------------------------------------------------------
    FTDI DLL calls

    Taken from D2XXunit.pas (http://www.ftdichip.com/
    -------------------------------------------------------------------------- }

  //Classic functions
  function FT_GetNumDevices(pvArg1:Pointer; pvArg2:Pointer; dwFlags:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_ListDevices';
  function FT_ListDevices(pvArg1:Dword; pvArg2:Pointer; dwFlags:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_ListDevices';
  function FT_Open(Index:Integer; ftHandle:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_Open';
  function FT_OpenEx(pvArg1:Pointer; dwFlags:Dword; ftHandle:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_OpenEx';
  function FT_OpenByLocation(pvArg1:DWord; dwFlags:Dword; ftHandle:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_OpenEx';
  function FT_Close(ftHandle:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_Close';
  function FT_Read(ftHandle:Dword; FTInBuf:Pointer; BufferSize:LongInt; ResultPtr:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_Read';
  function FT_Write(ftHandle:Dword; FTOutBuf:Pointer; BufferSize:LongInt; ResultPtr:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_Write';
  function FT_ResetDevice(ftHandle:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_ResetDevice';
  function FT_SetBaudRate(ftHandle:Dword; BaudRate:DWord):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetBaudRate';
  function FT_SetDivisor(ftHandle:Dword; Divisor:DWord):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetDivisor';
  function FT_SetDataCharacteristics(ftHandle:Dword; WordLength,StopBits,Parity:Byte):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetDataCharacteristics';
  function FT_SetFlowControl(ftHandle:Dword; FlowControl:Word; XonChar,XoffChar:Byte):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetFlowControl';
  function FT_SetDtr(ftHandle:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetDtr';
  function FT_ClrDtr(ftHandle:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_ClrDtr';
  function FT_SetRts(ftHandle:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetRts';
  function FT_ClrRts(ftHandle:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_ClrRts';
  function FT_GetModemStatus(ftHandle:Dword; ModemStatus:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_GetModemStatus';
  function FT_SetChars(ftHandle:Dword; EventChar,EventCharEnabled,ErrorChar,ErrorCharEnabled:Byte):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetChars';
  function FT_Purge(ftHandle:Dword; Mask:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_Purge';
  function FT_SetTimeouts(ftHandle:Dword; ReadTimeout,WriteTimeout:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetTimeouts';
  function FT_GetQueueStatus(ftHandle:Dword; RxBytes:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_GetQueueStatus';
  function FT_SetBreakOn(ftHandle:Dword) : FT_Result; stdcall; External FT_DLL_Name name 'FT_SetBreakOn';
  function FT_SetBreakOff(ftHandle:Dword) : FT_Result; stdcall; External FT_DLL_Name name 'FT_SetBreakOff';
  function FT_GetStatus(ftHandle:DWord; RxBytes,TxBytes,EventStatus:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_GetStatus';
  function FT_SetEventNotification(ftHandle:DWord; EventMask:DWord; pvArgs:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetEventNotification';
  function FT_GetDeviceInfo(ftHandle:DWord; DevType,ID,SerNum,Desc,pvDummy:Pointer) : FT_Result; stdcall; External FT_DLL_Name name 'FT_GetDeviceInfo';
  function FT_SetResetPipeRetryCount(ftHandle:Dword; RetryCount:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetResetPipeRetryCount';
  function FT_StopInTask(ftHandle:Dword) : FT_Result; stdcall; External FT_DLL_Name name 'FT_StopInTask';
  function FT_RestartInTask(ftHandle:Dword) : FT_Result; stdcall; External FT_DLL_Name name 'FT_RestartInTask';
  function FT_ResetPort(ftHandle:Dword) : FT_Result; stdcall; External FT_DLL_Name name 'FT_ResetPort';
  function FT_CyclePort(ftHandle:Dword) : FT_Result; stdcall; External 'FTD2XX.DLL' name 'FT_CyclePort';
  function FT_CreateDeviceInfoList(NumDevs:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_CreateDeviceInfoList';
  function FT_GetDeviceInfoList(pFT_Device_Info_List:Pointer; NumDevs:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_GetDeviceInfoList';
  function FT_GetDeviceInfoDetail(Index:DWord; Flags,DevType,ID,LocID,SerialNumber,Description,DevHandle:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_GetDeviceInfoDetail';
  function FT_GetDriverVersion(ftHandle:Dword; DrVersion:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_GetDriverVersion';
  function FT_GetLibraryVersion(LbVersion:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_GetLibraryVersion';

  // EEPROM functions
  function FT_EE_Read(ftHandle:DWord; pEEData:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_EE_Read';
  function FT_EE_Program(ftHandle:DWord; pEEData:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_EE_Program';

  // EEPROM primitives - you need an NDA for EEPROM checksum
  function FT_ReadEE(ftHandle:DWord; WordAddr:DWord; WordRead:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_ReadEE';
  function FT_WriteEE(ftHandle:DWord; WordAddr:DWord; WordData:word):FT_Result; stdcall; External FT_DLL_Name name 'FT_WriteEE';
  function FT_EraseEE(ftHandle:DWord):FT_Result; stdcall; External FT_DLL_Name name 'FT_EraseEE';
  function FT_EE_UARead(ftHandle:DWord; Data:Pointer; DataLen:DWord; BytesRead:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_EE_UARead';
  function FT_EE_UAWrite(ftHandle:DWord; Data:Pointer; DataLen:DWord):FT_Result; stdcall; External FT_DLL_Name name 'FT_EE_UAWrite';
  function FT_EE_UASize(ftHandle:DWord; UASize:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_EE_UASize';

  // FT2232C, FT232BM and FT245BM Extended API Functions
  function FT_GetLatencyTimer(ftHandle:Dword; Latency:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_GetLatencyTimer';
  function FT_SetLatencyTimer(ftHandle:Dword; Latency:Byte):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetLatencyTimer';
  function FT_GetBitMode(ftHandle:Dword; BitMode:Pointer):FT_Result; stdcall; External FT_DLL_Name name 'FT_GetBitMode';
  function FT_SetBitMode(ftHandle:Dword; Mask,Enable:Byte):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetBitMode';
  function FT_SetUSBParameters(ftHandle:Dword; InSize,OutSize:Dword):FT_Result; stdcall; External FT_DLL_Name name 'FT_SetUSBParameters';

implementation

end.
