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
Import "IFTDIDevice.bmx"
Import "TFTDIDeviceNode.bmx"      '< 'friend' access needed
Import "TFTDIDLL.bmx"
Import "TFTDIException.bmx"

Public
Type TFTDI232RDevice Extends TFTDIUnknownDevice

    Const BITMODE_BIT_BANG:Byte = $20

    ' % |cb3 dir|cb2 dir|cb1 dir|cb0 dir||cb3 state|cb2 state|cb1 state|cb0 state|
    Const CBUS_DIR_IN:Byte  = %0
    Const CBUS_DIR_OUT:Byte = %1
    
    Const CBUS_HI:Byte = %1
    Const CBUS_LO:Byte = %0
    
    ' or mask these
    Const CB0_IN:Byte  = CBUS_DIR_IN  Shl 4
    Const CB0_OUT:Byte = CBUS_DIR_OUT Shl 4
    Const CB1_IN:Byte  = CBUS_DIR_IN  Shl 5
    Const CB1_OUT:Byte = CBUS_DIR_OUT Shl 5
    Const CB2_IN:Byte  = CBUS_DIR_IN  Shl 6
    Const CB2_OUT:Byte = CBUS_DIR_OUT Shl 6
    Const CB3_IN:Byte  = CBUS_DIR_IN  Shl 7
    Const CB3_OUT:Byte = CBUS_DIR_OUT Shl 7
    Const CB_ALLIN:Byte  = CB0_IN | CB1_IN | CB2_IN | CB3_IN
    Const CB_ALLOUT:Byte = CB0_OUT | CB1_OUT | CB2_OUT | CB3_OUT
    
    ' or mask these
    Const CB0_HI:Byte = CBUS_HI Shl 0
    Const CB0_LO:Byte = CBUS_LO Shl 0
    Const CB1_HI:Byte = CBUS_HI Shl 1
    Const CB1_LO:Byte = CBUS_LO Shl 1
    Const CB2_HI:Byte = CBUS_HI Shl 2
    Const CB2_LO:Byte = CBUS_LO Shl 2
    Const CB3_HI:Byte = CBUS_HI Shl 3
    Const CB3_LO:Byte = CBUS_LO Shl 3
    Const CB_ALLHI:Byte = CB0_HI | CB1_HI | CB2_HI | CB3_HI
    Const CB_ALLLO:Byte = CB0_LO | CB1_LO | CB2_LO | CB3_LO

    Method SetBitMode( mask:Byte, bitmode:Byte )
        Assert _hnd
        Local e:Int = _dll.FT_SetBitMode( _hnd, mask, bitmode )
        If e <> TFTDIDLL.FT_OK Then Throw ..
            TFTDILibraryCallFailException.Create( "FT_SetBitMode( $" + Hex(_hnd) ..
              + ", " + mask + ", " + bitmode + " ) : " + TFTDIDLL.ErrToString(e) )
    EndMethod

    Function Create:TFTDI232RDevice( node:IFTDIDeviceNode, open:Int=True )
        Local me:TFTDI232RDevice = New TFTDI232RDevice
        _create( me, node, open )
        Return me
    End Function
End Type

Public
Type TFTDIUnknownDevice Extends IFTDIDevice

    Field _hnd:Int = 0
    Field _dll:TFTDIDLL = Null
    Field _node:TFTDIUnknownNode = Null
    
    Method Open()
        ' we do need to peek into _node._idx for windows platforms (which is what 
        ' this bit of code is written for anyways ) we're going to delve into internals .. 
        ' but think of it as 'friend' access in c++. This is a prime example of proper usage
        ' in that manner
        '
        ' not done directly through fields, the _friend() accessors are used
        '
        Assert _node
        ?Threaded
        Local m:TMutex = _node._friendGetMutex()
        Assert m
        m.Lock()
        ?
        If Not _node.IsOpen() Then
            Assert _hnd = 0
            Assert _dll
            Local e:Int = _dll.FT_Open( _node._friendGetIndex(), _hnd )
            If e <> TFTDIDLL.FT_OK Then Throw ..
                TFTDILibraryCallFailException.Create( ..
                  "FT_Open( " + _node._friendGetIndex() + ", $" + Hex(_hnd) + ..
                  ") : " + TFTDIDLL.ErrToString(e) )
            _node._friendSetOpen()
            Assert _hnd
            ?Debug
            Local v:Int = 0
            e = _dll.FT_GetDriverVersion( _hnd, v )
            If e <> TFTDIDLL.FT_OK Then Throw ..
                TFTDILibraryCallFailException.Create( ..
                  "FT_GetDriverVersion( $" + Hex(_hnd) + ", v ) : " + TFTDIDLL.ErrToString(e) )
            If v < TFTDIDLL.DRIVER_TESTED_VERSION Then Throw ..
                TFTDIException.Create( "v < TFTDIDLL.DRIVER_TESTED_VERSION : $" + Hex(v)  )
            ?
        End If
        ?Threaded
        m.Unlock()
        ?
    End Method

    Method Close()
        Assert _node
        ?Threaded
        Local m:TMutex = _node._friendGetMutex()
        Assert m
        m.Lock()
        ?
        If _node.IsOpen() Then
            Assert _dll
            Assert _hnd <> 0
            Local e:Int = _dll.FT_Close( _hnd )
            If e <> TFTDIDLL.FT_OK Then Throw ..
                TFTDILibraryCallFailException.Create( ..
                  "FT_Close( $" + Hex(_hnd) + " ) : " + TFTDIDLL.ErrToString(e) )
            _node._friendSetClosed()
            _hnd = 0
        End If
        ?Threaded
        m.Unlock()
        ?
    End Method
    
    Method SetBaudRate( bps:Int )
        Assert _hnd
        Local e:Int = _dll.FT_SetBaudRate( _hnd, bps )
        If e <> TFTDIDLL.FT_OK Then Throw ..
            TFTDILibraryCallFailException.Create( "FT_SetBaudRate( $" + Hex(_hnd) ..
              + ", " + bps + " ) : " + TFTDIDLL.ErrToString(e) )
    End Method
    
    Method SetDataCharacteristics( bits:Int, parity:Byte, stop_bits:Byte )
        Assert _hnd
        Local e:Int = _dll.FT_SetDataCharacteristics( _hnd, bits, stop_bits, parity )
        If e <> TFTDIDLL.FT_OK Then Throw ..
            TFTDILibraryCallFailException.Create( "FT_SetDataCharacteristics( $" + Hex(_hnd) ..
              + ", " + bits + ", " + stop_bits + ", " + parity + " ) : " + TFTDIDLL.ErrToString(e) )
    End Method

    Method SetLatencyTimer( millisec:Byte )
        Assert _hnd
        Local e:Int = _dll.FT_SetLatencyTimer( _hnd, millisec )
        If e <> TFTDIDLL.FT_OK Then Throw ..
            TFTDILibraryCallFailException.Create( "FT_SetLatencyTimer( $" + Hex(_hnd) ..
              + ", " + millisec + " ) : " + TFTDIDLL.ErrToString(e) )
    EndMethod

    Method SetFlowControl( flow:Short, xon:Byte=$11 , xoff:Byte=$13 )
        Assert _hnd
        Local e:Int = _dll.FT_SetFlowControl( _hnd, flow, xon, xoff )
        If e <> TFTDIDLL.FT_OK Then Throw ..
            TFTDILibraryCallFailException.Create( "FT_SetFlowControl( $" + Hex(_hnd) ..
              + ", " + flow + ", " + xon + ", " + xoff + " ) : " + TFTDIDLL.ErrToString(e) )
    EndMethod

    Method SetTimeouts( read_to_millisec:Int, write_to_millisec:Int )
        Assert _hnd
        Local e:Int = _dll.FT_SetTimeouts( _hnd, read_to_millisec, write_to_millisec )
        If e <> TFTDIDLL.FT_OK Then Throw ..
            TFTDILibraryCallFailException.Create( "FT_SetTimeouts( $" + Hex(_hnd) ..
              + ", " + read_to_millisec + ", " + write_to_millisec + " ) : " + TFTDIDLL.ErrToString(e) )
    EndMethod

    Method Reset()
        Assert _hnd
        Local e:Int = _dll.FT_ResetDevice( _hnd )
        If e <> TFTDIDLL.FT_OK Then Throw ..
            TFTDILibraryCallFailException.Create( "FT_ResetDevice( $" + Hex(_hnd) ..
              + " ) : " + TFTDIDLL.ErrToString(e) )
    EndMethod

    Method Write:Int( ba:Byte[] )
        Assert _hnd
        Local bytes_written:Int = 0
        Local e:Int = _dll.FT_Write( _hnd, ba, Len(ba), bytes_written )
        If e <> TFTDIDLL.FT_OK Then Throw ..
            TFTDILibraryCallFailException.Create( "FT_Write( $" + Hex(_hnd) ..
              + ", $" + ba.ToString() + ", " + Len(ba) + ", " + bytes_written + ..
              " ) : " + TFTDIDLL.ErrToString(e) )
        Return bytes_written
    EndMethod

    Method Read:Byte[]( cnt:Int )
        Local ba:Byte[] = Null
        If cnt
            Assert _hnd
            ba = New Byte[cnt]
            Local bytes_returned:Int = 0
            Local e:Int = _dll.FT_Read( _hnd, ba, cnt, bytes_returned )
            If e <> TFTDIDLL.FT_OK Then Throw ..
                TFTDILibraryCallFailException.Create( "FT_Read( $" + Hex(_hnd) ..
                  + ", " + ba.ToString() + ", " + cnt + ", " + bytes_returned + ..
                  " ) : " + TFTDIDLL.ErrToString(e) )
            If bytes_returned <> Len(ba) Then ba = Null
        EndIf
        Return ba
    EndMethod

    Method SerialNumber:String()
        Assert _node
        Return _node.SerialNumber()
    End Method
    
    Method Description:String()
        Assert _node
        Return _node.Description()
    End Method
    
    Method IsOpen:Int()
        Assert _node
        Return _node.IsOpen()
    End Method
    
    Function Create:TFTDIUnknownDevice( node:IFTDIDeviceNode, open:Int = True )
        Local me:TFTDIUnknownDevice = New TFTDIUnknownDevice
        _create( me, node, open )
        Return me
    End Function
    
    Function _create( me:TFTDIUnknownDevice, node:IFTDIDeviceNode, do_open:Int )
        Assert me
        me._node = TFTDIUnknownNode(node)   ' cast to get access to friend functions
        me._dll = TFTDIDLL.Load()
        If Not me._dll Then Throw ..
            TFTDILibraryLoadFailException.Create( TTypeId.ForObject(me).Name() )
        ' a node can NEVER be open once we begin management of it here
        ?Threaded
        Local m:TMutex = me._node._friendGetMutex()
        Assert m
        ?
        If me._node.IsOpen() Then Throw ..
            TFTDIOpenNodeException.Create( me._node.SerialNumber() )
        If do_open Then me.Open()
        ?Threaded
        m.Unlock()
        ?
    End Function
    
    Function _isBits:Int( b:Byte )
        Return b = BITS_8 Or b = BITS_7
    End Function
    
    Function _isStopBits:Int( sb:Byte )
        Return sb = STOP_BITS_1 Or sb = STOP_BITS_2
    End Function
    
    Function _isParity:Int( p:Byte )
        Return p = PARITY_NONE Or p = PARITY_ODD  Or p = PARITY_EVEN Or ..
               p = PARITY_MARK Or p = PARITY_SPACE
    End Function
    
    Function _isFlow:Int( f:Short )
        Return f = FLOW_NONE Or f = FLOW_RTS_CTS Or ..
             f = FLOW_DTR_DSR Or f= FLOW_XON_XOFF
    End Function

End Type

Const BITS_8:Int = 8
Const BITS_7:Int = 7
    
Const STOP_BITS_1:Byte = 0
Const STOP_BITS_2:Byte = 2
    
Const PARITY_NONE:Byte  = 0
Const PARITY_ODD:Byte   = 1
Const PARITY_EVEN:Byte  = 2
Const PARITY_MARK:Byte  = 3
Const PARITY_SPACE:Byte = 4
    
Const FLOW_NONE:Short     = $0000
Const FLOW_RTS_CTS:Short  = $0100
Const FLOW_DTR_DSR:Short  = $0200
Const FLOW_XON_XOFF:Short = $0400

Public
Type TFTDIDevice
    ' factory func, forex:
    '   Local d:TFTDI232RDevice = TFTDIDevice.Create( n:TFTDI232RNode )
    Function Create:IFTDIDevice( node:IFTDIDeviceNode, open:Int=True )
        Select TTypeId.ForObject(node).Name()
            Case "TFTDI232RNode" Return TFTDI232RDevice.Create( node, open )
            Case "TFTDIUnknownNode" Return TFTDIUnknownDevice.Create( node, open )
        EndSelect
        Return Null
    EndFunction
EndType