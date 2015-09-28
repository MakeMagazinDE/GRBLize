{ ----------------------------------------------------------------------------
  FTDI D2XX types
  Copyright (c) Michael "Zipplet" Nixon 2009.
  Licensed under the MIT license, see license.txt in the project trunk.

  Unit: FTDItypes.pas
  Purpose: FTDI types
  ---------------------------------------------------------------------------- }
unit FTDItypes;

{ ----------------------------------------------------------------------------
  ---------------------------------------------------------------------------- }

interface

uses
  sysutils, windows, messages, classes, bsearchtree, blinklist;

Const
    { -------- FTD2XX.H ------------------------------------------------------ }
    { FT_Result Values }
    FT_OK = 0;
    FT_INVALID_HANDLE = 1;
    FT_DEVICE_NOT_FOUND = 2;
    FT_DEVICE_NOT_OPENED = 3;
    FT_IO_ERROR = 4;
    FT_INSUFFICIENT_RESOURCES = 5;
    FT_INVALID_PARAMETER = 6;
    FT_SUCCESS = FT_OK;
    FT_INVALID_BAUD_RATE = 7;
    FT_DEVICE_NOT_OPENED_FOR_ERASE = 8;
    FT_DEVICE_NOT_OPENED_FOR_WRITE = 9;
    FT_FAILED_TO_WRITE_DEVICE = 10;
    FT_EEPROM_READ_FAILED = 11;
    FT_EEPROM_WRITE_FAILED = 12;
    FT_EEPROM_ERASE_FAILED = 13;
    FT_EEPROM_NOT_PRESENT = 14;
    FT_EEPROM_NOT_PROGRAMMED = 15;
    FT_INVALID_ARGS = 16;
    FT_OTHER_ERROR = 17;

    { FT_Open_Ex Flags }
    FT_OPEN_BY_SERIAL_NUMBER = 1;
    FT_OPEN_BY_DESCRIPTION = 2;
    FT_OPEN_BY_LOCATION = 4;

    { FT_List_Devices Flags }
    FT_LIST_NUMBER_ONLY = $80000000;
    FT_LIST_BY_INDEX = $40000000;
    FT_LIST_ALL = $20000000;

    { Baud Rate Selection }
    FT_BAUD_300 = 300;
    FT_BAUD_600 = 600;
    FT_BAUD_1200 = 1200;
    FT_BAUD_2400 = 2400;
    FT_BAUD_4800 = 4800;
    FT_BAUD_9600 = 9600;
    FT_BAUD_14400 = 14400;
    FT_BAUD_19200 = 19200;
    FT_BAUD_38400 = 38400;
    FT_BAUD_57600 = 57600;
    FT_BAUD_115200 = 115200;
    FT_BAUD_230400 = 230400;
    FT_BAUD_460800 = 460800;
    FT_BAUD_921600 = 921600;

    { Data Bits Selection }
    FT_DATA_BITS_7 = 7;
    FT_DATA_BITS_8 = 8;

    { Stop Bits Selection }
    FT_STOP_BITS_1 = 0;
    FT_STOP_BITS_2 = 2;

    { Parity Selection }
    FT_PARITY_NONE = 0;
    FT_PARITY_ODD = 1;
    FT_PARITY_EVEN = 2;
    FT_PARITY_MARK = 3;
    FT_PARITY_SPACE = 4;

    { Flow Control Selection }
    FT_FLOW_NONE = $0000;
    FT_FLOW_RTS_CTS = $0100;
    FT_FLOW_DTR_DSR = $0200;
    FT_FLOW_XON_XOFF = $0400;

    { Purge Commands }
    FT_PURGE_RX = 1;
    FT_PURGE_TX = 2;

    { Notification Events }
    FT_EVENT_RXCHAR = 1;
    FT_EVENT_MODEM_STATUS = 2;

    { Modem Status }
    CTS = $10;
    DSR = $20;
    RI = $40;
    DCD = $80;

    { Devices }
    FT_DEVICE_232BM = 0;
    FT_DEVICE_232AM = 1;
    FT_DEVICE_100AX = 2;
    FT_DEVICE_UNKNOWN = 3;
    FT_DEVICE_2232C = 4;
    FT_DEVICE_232R = 5;

type
  { -------- Var types ------------------------------------------------------- }
  dword = longword;
  FT_Result = integer;
  FT_Handle = dword;

  { -------- D2XX ------------------------------------------------------------ }
  ftdiDeviceNode = packed record
    flags: dword;
    deviceType: dword;
    id: dword;
    locid: dword;
    serialNumber: array[0..15] of Ansichar;
    description: array[0..63] of Ansichar;
    ftHandle: FT_HANDLE;
  end;

  ftdiDeviceList = array[0..7] of ftdiDeviceNode;
  pftdiDeviceList = ^ftdiDeviceList;

  { -------- Enums ----------------------------------------------------------- }
  fBaudRate = (fBaud300, fBaud600, fBaud1200, fBaud2400, fBaud4800, fBaud9600,
               fBaud14400, fBaud19200, fBaud38400, fBaud57600, fBaud115200,
               fBaud230400, fBaud460800, fBaud921600);
  fWordLength = (fBits8, fBits7);
  fStopBits = (fStopBits1, fStopBits2);
  fParity = (fParityNone, fParityOdd, fParityEven, fParityMark, fParitySpace);
  fFlowControl = (fFlowNone, fFlowRTSCTS, fFlowDTRDSR, fFlowXONXOFF);
  fQueue = (fSendQueue, fReceiveQueue, fAll);
  fDevice = (fDevice232BM, fDevice232AM, fDevice100AX, fDeviceUnknown, fDevice2232C, fDevice232R);
  fEvent = (fEventRXChar, fEventModemStatus, fEventAny, fEventTimedOut, fEventError);

  { -------- Method pointer types -------------------------------------------- }
  tftdievent_onReceiveData = procedure(ftdichip: tobject; datalength: longint) of object;
  tftdievent_onSendQueueEmpty = procedure(ftdichip: tobject) of object;
  tftdievent_onError = procedure(ftdichip: tobject) of object;

implementation

end.
