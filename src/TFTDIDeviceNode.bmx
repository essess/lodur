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
Import "IFTDIDeviceNode.bmx"
Import "TFTDIException.bmx"

Public
Type TFTDI232RNode Extends TFTDIUnknownNode
	Function Create:TFTDI232RNode( index:Int, serial_number:String, ..
							description:String, flags:Int )
		Local me:TFTDI232RNode = New TFTDI232RNode
		_create( me, index, serial_number, description, flags )
		Return me
	End Function
End Type

Public
Type TFTDIUnknownNode Extends IFTDIDeviceNode

	Field _idx:Int
	Field _sn:String
	Field _desc:String
	Field _flags:Int
	?Threaded
	Field _mutex:TMutex
	?

	Const FLAG_OPEN:Int    = $00000001
	Const FLAG_HISPEED:Int = $00000002

	Method SerialNumber:String()
		Return _sn
	End Method
	
	Method Description:String()
		Return _desc
	End Method
	
	Method IsOpen:Int()
		Local _isOpen:Int
		?Threaded
		_mutex.Lock()
		?
		Assert _isFlags(_flags)
		_isOpen = ((_flags & FLAG_OPEN) = FLAG_OPEN)
		?Threaded
		_mutex.Unlock()
		?
		Return _isOpen
	End Method
	
	Method IsHighSpeed:Int()
		Assert _isFlags(_flags)
		Return (_flags & FLAG_HISPEED) = FLAG_HISPEED
	End Method
	
	Method ToString:String()
		Local s:String
		s :+ "Serial Number : " + "~q" + SerialNumber() + "~q~n"
		s :+ "Description   : " + "~q" + Description() + "~q~n"
		s :+ "Is            : "
		If Not IsOpen() Then s :+ "Not "
		s :+ "Open, "
		If Not IsHighSpeed() Then s :+ "Not "
		s :+ "High Speed"
		Return s
	End Method
	
	Function Create:TFTDIUnknownNode( index:Int, serial_number:String, ..
							description:String, flags:Int )
		Local me:TFTDIUnknownNode = New TFTDIUnknownNode
		_create( me, index, serial_number, description, flags )
		Return me
	End Function

	Function _create( me:TFTDIUnknownNode, index:Int, serial_number:String, ..
				 description:String, flags:Int )
		If Not _isFlags(flags) Then Throw TFTDIBadFlagsException.Create( "$" + Hex(flags) )
		If Not _isIndex(index) Then Throw TFTDIBadIndexException.Create( index )
		Assert me
		me._idx = index
		me._sn = serial_number
		me._desc = description
		me._flags = flags
		?Threaded
		me._mutex = TMutex.Create()
		?
	End Function
	
	?Threaded
	Method _friendGetMutex:TMutex()
		' any 'friends' that modify this obj (open flag) need to grab the mutex
		' to lock it for updates. mutexes are recursive on all platforms.
		Assert _mutex
		Return _mutex
	End Method
	?
	
	Method _friendGetIndex:Int()
		Return _idx
	End Method
	
	Method _friendSetOpen()
		?Threaded
		_mutex.Lock()
		?
		_flags = _flags | FLAG_OPEN
		?Threaded
		_mutex.Unlock()
		?
	End Method
	
	Method _friendSetClosed()
		?Threaded
		_mutex.Lock()
		?
		_flags = _flags & ~FLAG_OPEN
		?Threaded
		_mutex.Unlock()
		?
	End Method
	
	Function _isFlags:Int( f:Int )
		Return (f & ~(FLAG_OPEN|FLAG_HISPEED)) = 0
	End Function

	Function _isIndex:Int( i:Int )
		Const MAX_INDEX:Int = 32
		Return i <= MAX_INDEX
	End Function
	
End Type