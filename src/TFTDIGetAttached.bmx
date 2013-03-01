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
Import "TFTDIDeviceNode.bmx"
Import "TFTDIDLL.bmx"
Import "TFTDIDevice.bmx"

Public
Type TFTDIGetAttached

	?Threaded
	Global mutex:TMutex = TMutex.Create()
	?
	
	Function DeviceNodes:IFTDIDeviceNode[]()	
		Local dll:TFTDIDLL = TFTDIDLL.Load() ; Assert dll
		Local nodes:IFTDIDeviceNode[] = Null
		Local num:Int = 0
		?Threaded
		mutex.Lock
		?
		If dll.FT_CreateDeviceInfoList(num) = TFTDIDLL.FT_OK And num > 0 Then
			nodes = New IFTDIDeviceNode[num] ; Assert nodes
			Const SN_BUFFSIZE:Int = 64, DESC_BUFFSIZE:Int = 128
			Local sn:Byte Ptr = MemAlloc( SN_BUFFSIZE ) ; Assert sn
			Local desc:Byte Ptr = MemAlloc( DESC_BUFFSIZE ) ; Assert desc
			While num	' cleaner/easier than calling FT_GetDeviceInfoList()
				num :- 1
				MemClear( sn, SN_BUFFSIZE )
				MemClear( desc, DESC_BUFFSIZE )
				Local flags:Int, device:Int, id:Int, loc:Int, hnd:Int
				If dll.FT_GetDeviceInfoDetail( num, flags, device, ..
				             id, loc, sn, desc, hnd ) <> TFTDIDLL.FT_OK Then
					nodes = Null; Exit ' deref to get gc'd and bail
				EndIf
				Select device
					Case FT_DEVICE_232R
						nodes[num] = TFTDI232RNode.Create( num, ..
				                           String.FromCString(sn), String.FromCString(desc), flags )
					Default
						nodes[num] = TFTDIUnknownNode.Create( num, ..
				                           String.FromCString(sn), String.FromCString(desc), flags )
				End Select
				Assert nodes[num]
			End While
			MemFree(sn)
			MemFree(desc)
		End If
		?Threaded
		mutex.Unlock
		?
		Return nodes
	End Function

	Function Devices:TList()
		Local devices:TList = CreateList()
		For Local node:IFTDIDeviceNode = EachIn DeviceNodes()
			' make sure it's !open and keep it that way, the caller
			' can open as they see fit, we're just sorting for available
			' devices here (available = !open)
			If Not node.IsOpen() Then devices.AddLast( TFTDIDevice.Create(node, False) )
		Next
		Return devices
	EndFunction

	' forex:
	'	Local d:TFTDI232RDevice = TFTDI232RDevice( ..
	'		TFTDIGetAttached.FirstDeviceByType( TTypeId.ForName("TFTDI232RDevice") ))
	'
	Function FirstDeviceByType:IFTDIDevice( t:TTypeId )
		Local device:IFTDIDevice = Null 
		For device = EachIn Devices()
			If t = TTypeId.ForObject(device) Then Exit
		Next
		Return device
	End Function

End Type

Private
Const FT_DEVICE_BM:Int       = 0
Const FT_DEVICE_AM:Int       = 1
Const FT_DEVICE_100AX:Int    = 2
Const FT_DEVICE_UNKNOWN:Int  = 3
Const FT_DEVICE_2232C:Int    = 4
Const FT_DEVICE_232R:Int     = 5
Const FT_DEVICE_2232H:Int    = 6
Const FT_DEVICE_4232H:Int    = 7
Const FT_DEVICE_232H:Int     = 8
Const FT_DEVICE_X_SERIES:Int = 9
