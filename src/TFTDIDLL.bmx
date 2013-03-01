'
' Copyright (c) 2013, Sean Stasiak. All rights reserved.
' Developed by: Sean Stasiak <sstasiak@gmail.com>
' 
' Permission is hereby granted, free of charge, to any person obtaining a copy
' of this software and associated documentation files (the "Software"), to deal
' with the Software without restriction, including without limitation the rights
' to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' copies of the Software, and to permit persons to whom the Software is furnished
' to do so, subject to the following conditions:
'
'   -Redistributions of source code must retain the above copyright notice,
'    this list of conditions and the following disclaimers.
'
'   -Redistributions in binary form must reproduce the above copyright notice,
'    this list of conditions and the following disclaimers in the documentation
'    and/or other materials provided with the distribution.
'
'   -Neither Sean Stasiak, nor the names of other contributors may be used to
'    endorse or promote products derived from this Software without specific
'    prior written permission.
'
' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
' IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
' FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
' CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
' LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
' OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH
' THE SOFTWARE.
'
SuperStrict
Import pub.win32

Type TFTDIDLL
	?Threaded
	Global mutex:TMutex = TMutex.Create()
	?
	Global me:TFTDIDLL = Null
	
	Const FT_OK:Int                          = 0
	Const FT_INVALID_HANDLE:Int              = 1
	Const FT_DEVICE_NOT_FOUND:Int            = 2
	Const FT_DEVICE_NOT_OPENED:Int           = 3
	Const FT_IO_ERROR:Int                    = 4
	Const FT_INSUFFICIENT_RESOURCES:Int      = 5
	Const FT_INVALID_PARAMETER:Int           = 6
	Const FT_INVALID_BAUD_RATE:Int           = 7
	Const FT_DEVICE_NOT_OPENED_FOR_ERASE:Int = 8
	Const FT_DEVICE_NOT_OPENED_FOR_WRITE:Int = 9
	Const FT_FAILED_TO_WRITE_DEVICE:Int      = 10
	Const FT_EEPROM_READ_FAILED:Int          = 11
	Const FT_EEPROM_WRITE_FAILED:Int         = 12
	Const FT_EEPROM_ERASE_FAILED:Int         = 13
	Const FT_EEPROM_NOT_PRESENT:Int          = 14
	Const FT_EEPROM_NOT_PROGRAMMED:Int       = 15
	Const FT_INVALID_ARGS:Int                = 16
	Const FT_NOT_SUPPORTED:Int               = 17
	Const FT_OTHER_ERROR:Int                 = 18
	Const FT_DEVICE_LIST_NOT_READY:Int       = 19

	Const FT_BITS_8:Byte = 8
	Const FT_BITS_7:Byte = 7
	
	Const FT_STOP_BITS_1:Byte = 0
	Const FT_STOP_BITS_2:Byte = 2
	
	Const FT_PARITY_NONE:Byte  = 0
	Const FT_PARITY_ODD:Byte   = 1
	Const FT_PARITY_EVEN:Byte  = 2
	Const FT_PARITY_MARK:Byte  = 3
	Const FT_PARITY_SPACE:Byte = 4
	
	Const FT_FLOW_NONE:Short     = $0000
	Const FT_FLOW_RTS_CTS:Short  = $0100
	Const FT_FLOW_DTR_DSR:Short  = $0200
	Const FT_FLOW_XON_XOFF:Short = $0400
	
	Const DRIVER_TESTED_VERSION:Int = $00020824

	Field FT_GetDeviceInfoDetail:Int( dwIndex:Int, lpdwFlags:Int Var, ..
	        lpdwType:Int Var, lpdwID:Int Var, lpdwLocId:Int Var, pcSerialNumber:Byte Ptr, ..
	        pcDescription:Byte Ptr, ftHandle:Int Var ) "win32"
	Field FT_CreateDeviceInfoList:Int( lpdwNumDevs:Int Var ) "win32"
	Field FT_Open:Int( iDevice:Int, ftHandle:Int Var ) "win32"
	Field FT_Close:Int( ftHandle:Int ) "win32"
	Field FT_GetDriverVersion:Int( ftHandle:Int, lpdwDriverVersion:Int Var ) "win32"
	Field FT_Read:Int( ftHandle:Int, lpBuffer:Byte Ptr, dwBytesToRead:Int, ..
		  lpdwBytesReturned:Int Var ) "win32"
	Field FT_Write:Int( ftHandle:Int, lpBuffer:Byte Ptr, dwBytesToWrite:Int, ..
	 	  lpdwBytesWritten:Int Var ) "win32"
	Field FT_SetBaudRate:Int( ftHandle:Int, dwBaudRate:Int ) "win32"
	Field FT_SetDataCharacteristics:Int( ftHandle:Int, uWordLength:Byte, ..
	        uStopBits:Byte, uParity:Byte ) "win32"
	Field FT_SetFlowControl:Int( ftHandle:Int, usFlowControl:Short, ..
	        uXon:Byte, uXoff:Byte ) "win32"
	Field FT_SetBitMode:Int( ftHandle:Int, ucMask:Byte, ucMode:Byte ) "win32"
	Field FT_SetLatencyTimer:Int( ftHandle:Int, ucTimer:Byte ) "win32"
	Field FT_ResetDevice:Int( ftHanlde:Int ) "win32"
	Field FT_GetLibraryVersion:Int( lpdwDLLVersion:Int Var ) "win32"
	Field FT_SetTimeouts:Int( ftHandle:Int, dwReadTimeout:Int, dwWriteTimeout:Int ) "win32"
	
	Function Load:TFTDIDLL( file:String = "ftd2xx.dll" )
		?Threaded
		mutex.Lock
		?
		If Not me Then
			Local hModule:Int = LoadLibraryW( file )
			If hModule Then
				me = New TFTDIDLL ; Assert me
				me.FT_GetLibraryVersion =  GetProcAddress( hModule, "FT_GetLibraryVersion" )
				me.FT_CreateDeviceInfoList = GetProcAddress( hModule, "FT_CreateDeviceInfoList" )
				me.FT_GetDeviceInfoDetail = GetProcAddress( hModule, "FT_GetDeviceInfoDetail" )
				me.FT_Open = GetProcAddress( hModule, "FT_Open" )
				me.FT_Close = GetProcAddress( hModule, "FT_Close" )
				me.FT_GetDriverVersion = GetProcAddress( hModule, "FT_GetDriverVersion" )
				me.FT_Read = GetProcAddress( hModule, "FT_Read" )
				me.FT_Write = GetProcAddress( hModule, "FT_Write" )
				me.FT_SetBaudRate = GetProcAddress( hModule, "FT_SetBaudRate" )
				me.FT_SetDataCharacteristics = GetProcAddress( hModule, "FT_SetDataCharacteristics" )
				me.FT_SetFlowControl = GetProcAddress( hModule, "FT_SetFlowControl" )
				me.FT_SetBitMode = GetProcAddress( hModule, "FT_SetBitMode" )
				me.FT_SetLatencyTimer = GetProcAddress( hModule, "FT_SetLatencyTimer" )
				me.FT_ResetDevice = GetProcAddress( hModule, "FT_ResetDevice" )
				me.FT_SetTimeouts = GetProcAddress( hModule, "FT_SetTimeouts" )
				Assert _isProcAddresses( me )
				Assert _isDllTestedVersion( me )
			End If
		End If
		?Threaded
		mutex.Unlock
		?
		Return me
	End Function
	
	Function ErrToString:String( err:Int )
		Local s:String = Null
		Select err
			Case FT_OK s = "FT_OK"
			Case FT_INVALID_HANDLE s = "FT_INVALID_HANDLE"
			Case FT_DEVICE_NOT_FOUND s = "FT_DEVICE_NOT_FOUND"
			Case FT_DEVICE_NOT_OPENED s = "FT_DEVICE_NOT_OPENED"
			Case FT_IO_ERROR s = "FT_IO_ERROR"
			Case FT_INSUFFICIENT_RESOURCES s = "FT_INSUFFICIENT_RESOURCES"
			Case FT_INVALID_PARAMETER s = "FT_INVALID_PARAMETER"
			Case FT_INVALID_BAUD_RATE s = "FT_INVALID_BAUD_RATE"
			Case FT_DEVICE_NOT_OPENED_FOR_ERASE s = "FT_DEVICE_NOT_OPENED_FOR_ERASE"
			Case FT_DEVICE_NOT_OPENED_FOR_WRITE s = "FT_DEVICE_NOT_OPENED_FOR_WRITE"
			Case FT_FAILED_TO_WRITE_DEVICE s = "FT_FAILED_TO_WRITE_DEVICE"
			Case FT_EEPROM_READ_FAILED s = "FT_EEPROM_READ_FAILED"
			Case FT_EEPROM_WRITE_FAILED s = "FT_EEPROM_WRITE_FAILED"
			Case FT_EEPROM_ERASE_FAILED s = "FT_EEPROM_ERASE_FAILED"
			Case FT_EEPROM_NOT_PRESENT s = "FT_EEPROM_NOT_PRESENT"
			Case FT_EEPROM_NOT_PROGRAMMED s = "FT_EEPROM_NOT_PROGRAMMED"
			Case FT_INVALID_ARGS s = "FT_INVALID_ARGS"
			Case FT_NOT_SUPPORTED s = "FT_NOT_SUPPORTED"
			Case FT_OTHER_ERROR s = "FT_OTHER_ERROR"
			Case FT_DEVICE_LIST_NOT_READY s = "FT_DEVICE_LIST_NOT_READY"
			Default s = "UNKNOWN"
		End Select
		Return s
	End Function
	
	?Debug
	Function _isProcAddresses:Int( me:TFTDIDLL )
		Return me.FT_GetLibraryVersion Or me.FT_CreateDeviceInfoList Or ..
			 me.FT_GetDeviceInfoDetail Or me.FT_Open Or me.FT_Close Or ..
			 me.FT_GetDriverVersion Or me.FT_Read Or me.FT_Write Or ..
			 me.FT_SetBaudRate Or me.FT_SetDataCharacteristics Or me.FT_SetFlowControl Or ..
			 me.FT_SetBitMode Or me.FT_SetLatencyTimer Or me.FT_ResetDevice	Or ..
			 me.FT_SetTimeouts
	End Function
	?
	
	?Debug
	Function _isDllTestedVersion:Int( me:TFTDIDLL )
		Const DLL_TESTED_VERSION:Int = $00030207
		Assert me
		Local v:Int = 0
		Assert me.FT_GetLibraryVersion(v) = FT_OK
		Return v >= DLL_TESTED_VERSION
	End Function
	?
	
End Type