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
' -----------------------------------------------------------------------------
'
' lodur: o5e (lo)ader(du)mpe(r) - dumping is yet to come
'
' usage:
'	lodur <srecord file>
'
' planned:
'	open FTDI device by serial number
'	list ftdi devices attached (so you can figure out which one to open)
'	VLE support
'	specify hardware password other than the factory default (0xfeedfacecafebeef)
'	better feedback as we progress through the process
'	timing/throughput metrics
'
SuperStrict
Import "src\TImage.bmx"
Import "src\TSRecord.bmx"
Import "src\TFTDIGetAttached.bmx"
Import "src\TFTDIDevice.bmx"

' open specified file
If AppArgs.Length <> 2 Then RuntimeError "Invalid argument"
Local stream:TStream = OpenFile( AppArgs[1], True, False )
If Not stream Then RuntimeError "Unable to open: ~q" + AppArgs[1] + "~q"

' load it up into an image
Local img:TImage = CreateImageFromSRecordStream( stream ); Assert img

' go grab the first unopened FT232R device
Local d:TFTDI232RDevice = TFTDI232RDevice( ..
	TFTDIGetAttached.FirstDeviceByType( TTypeId.ForName("TFTDI232RDevice") ))
If Not d Then RuntimeError "No device found"

Local o5e:o5eDevice = o5eDevice.Create( d ); Assert o5e

o5e.Open()
o5e.StartSerialBootloader()
o5e.LoadImage( img )
o5e.Close()

End
' -----------------------------------------------------------------------------

Type o5eDevice

	Field _d:TFTDI232RDevice

	Method Open()
		Assert _d
		Assert Not _d.IsOpen()
		_d.Open()
		_d.Reset()
		_d.SetBaudRate( 9600 )
		_d.SetDataCharacteristics( BITS_8, PARITY_NONE, STOP_BITS_1 )
		_d.SetLatencyTimer( 1 )	' we're going to be chirping small data frequently
		_d.SetFlowControl( FLOW_NONE )
		_d.SetTimeouts( 500, 500 )
	EndMethod

	Method StartSerialBootloader()
		' reset cb3
		' bootcfg1 cb2
		' tx_led&rx_led cb4
		' cb0, cb1 open for future (autobaud(EVTO) and enable ?)
		
		Const RESET_DIR_OUT:Byte = TFTDI232RDevice.CB3_OUT
		Const RESET_DIR_IN:Byte = TFTDI232RDevice.CB3_IN
		Const BOOTCFG1_DIR_OUT:Byte = TFTDI232RDevice.CB2_OUT
		Const BOOTCFG1_DIR_IN:Byte = TFTDI232RDevice.CB2_OUT
		
		Const RESET_PIN_HIGH:Byte = TFTDI232RDevice.CB3_HI
		Const RESET_PIN_LOW:Byte = TFTDI232RDevice.CB3_LO
		Const BOOTCFG1_PIN_HIGH:Byte = TFTDI232RDevice.CB2_HI
		Const BOOTCFG1_PIN_LOW:Byte = TFTDI232RDevice.CB2_LO
	
		Assert _d
		Assert _d.IsOpen()
		_d.SetBitMode( RESET_DIR_OUT | BOOTCFG1_DIR_OUT | RESET_PIN_LOW | BOOTCFG1_PIN_HIGH, ..
			TFTDI232RDevice.BITMODE_BIT_BANG )	' reset out and drive low, bootcfg1 out and drive high
		Delay 20
		_d.SetBitMode( RESET_DIR_IN | BOOTCFG1_DIR_OUT | RESET_PIN_HIGH | BOOTCFG1_PIN_HIGH, ..
			TFTDI232RDevice.BITMODE_BIT_BANG )	' reset <- input/float
		Delay 10
		_d.SetBitMode( RESET_DIR_IN | BOOTCFG1_DIR_IN | RESET_PIN_LOW | BOOTCFG1_PIN_LOW, ..
			TFTDI232RDevice.BITMODE_BIT_BANG )	' bootcfg1 <- input/float
		' you now have a few seconds to LoadImage() before the watchdog resets the device
	EndMethod

	Method LoadImage( img:TImage )
		Assert _d
		Assert _d.IsOpen()

		' TODO: ensure that image address and size fits within SRAM

		' password first
		Local password:Byte[] = [ $fe:Byte, $ed:Byte, $fa:Byte, $ce:Byte, ..
                                  $ca:Byte, $fe:Byte, $be:Byte, $ef:Byte ]
		If Not _prvExchange( password ) Then ..
			RuntimeError "echo incorrect"

		' base address (big endian) if password was accepted
		Local base:Int = img.Base()
		Local addr:Byte[] = [ Byte(base Shr 24), ..
							  Byte(base Shr 16), ..
							  Byte(base Shr  8), ..
							  Byte(base Shr  0) ]
		If Not _prvExchange( addr ) Then ..
			RuntimeError "password not accepted"	' device locks on incorrect password
													' from previous step

		' size (big endian) if base address accepted (VLE bit ignored for now)
		Local s:Int = img.Size()
		' If VLE Then s |= $80000000
		Local size:Byte[] = [ Byte(s Shr 24), ..
							  Byte(s Shr 16), ..
							  Byte(s Shr  8), ..
							  Byte(s Shr  0) ]
		If Not _prvExchange( size ) Then ..
			RuntimeError "address not accepted"		' device locks on incorrect address
													' from previous step

		' push data
		Local data:Byte[] = New Byte[img.Size()]	' convert img to an array for exchanging
		For Local i:Int=0 Until Len(data)
			data[i] = img.GetNext()
		Next
		If Not _prvExchange( data ) Then ..
			RuntimeError "data load failure"

		' viola, BAM should have jumped to your code at this point
		' don't forget to keep resetting the wdt.
	EndMethod

	Method Close()
		Assert _d
		Assert _d.IsOpen()
		_d.Close()
	EndMethod

	' BAM comms are half duplex, RM states to do 1:1 exchange
	Method _prvExchange:Int( ba:Byte[] )
		For Local i:Int=0 Until Len(ba)
			Local b:Byte[1]
			b[0] = ba[i]
			b = _d.Read( _d.Write(b) )
			If Not b Or b[0] <> ba[i] Then Return False
		Next
		Return True
	EndMethod

	Function Create:o5eDevice( d:TFTDI232RDevice )
		Local me:o5eDevice = New o5eDevice
		Assert d; me._d = d;
		Return me
	EndFunction

EndType

Function CreateImageFromSRecordStream:TImage( stream:TStream )

	' seek to first S0 record and start pulling from the following record
	Local srecord:TSRecord
	Repeat
		Local str:String = stream.ReadLine(); Assert str
		If Eof(stream) Then RuntimeError "No S0 record found"
		srecord = TSRecord.CreateFromString( str )
	Until srecord.Rectype() = TSRecord.S0

	' start loading up records (of the expected type)
	Local srecords:TList = CreateList()
	Repeat
		Local str:String = stream.ReadLine(); Assert str
		If Eof(stream) Then Exit
		srecord = TSRecord.CreateFromString( str )
		If srecord.Rectype() <> TSRecord.S3 Then ..
			RuntimeError "Unsupported record type"
		If srecord.Rectype() =  TSRecord.S7 Then Exit
		srecords.AddLast( srecord )
	Forever
	
	' sort by address
	srecords.Sort()

	' grab first address, this is our base
	srecord = TSRecord(srecords.First())
	Local base:Int = srecord.Address()

	' grab last to derive raw image size
	srecord = TSRecord(srecords.Last())
	Local last:Int = srecord.Address() + Len(srecord.Data())
	Local size:Int = last - base

	' load it up
	Local img:TImage = TImage.Create( size, base )
	For srecord=EachIn srecords
		img.SetAddress( srecord.Address() )
		For Local b:Byte=EachIn srecord.Data()
			img.SetNext( b )
		Next
	Next

	Return img
End Function
