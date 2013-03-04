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
Import "TSRecordException.bmx"

Type TSRecord

    ' Public
    Const S0:Int = 1
    Const S1:Int = 2
    Const S2:Int = 3
    Const S3:Int = 4
    Const S7:Int = 8
    Const S8:Int = 9
    Const S9:Int = 10

    ' Prv
    Field _rt:Int = S0
    Field _addr:Int = 0
    Field _data:Byte[] = Null

    Method Rectype:Int()
        Assert IsRectype( _rt ), "_rt Invalid"
        Assert IsValidAddressForRectype( _addr, _rt ), "_addr Invalid"
        Return _rt
    End Method
    
    Method SetRectype( rt:Int )
        If Not IsRectype( rt ) Then ..
            Throw TSRecordException.Create( "Not A valid record type" )
        ' also need to check that current address can be contained
        ' by this rectype, and if not then notify caller. it's up
        ' to the caller to then decide what they want to change the
        ' address to since they know what rectype they're trying
        ' to set
        If Not IsValidAddressForRectype( _addr, rt ) Then ..
            Throw TSRecordException.Create( "Not a valid address for the current record type" )
        ' otherwise, all good
        _rt = rt
    End Method

    Method Address:Int()
        Assert IsRectype( _rt ), "_rt Invalid"
        Assert IsValidAddressForRectype( _addr, _rt ), "_addr Invalid"
        Return _addr
    End Method

    Method SetAddress( addr:Int )
        If Not IsValidAddressForRectype( addr, _rt ) Then ..
            Throw TSRecordException.Create( "Not a valid address for the current record type" )
        _addr = addr
    End Method
    
    ' data is not mutable, so we need to do a copy
    Method Data:Byte[]()
        Return _data[..]
    End Method
    
    ' data is not mutable, so we need to do a copy
    Method SetData( data:Byte[] )
        If Len(data) > 192 Then ..
            Throw TSRecordException.Create( "Too much data" )
        _data = data[..]
    End Method
    
    Method Compare:Int( other:Object )
        If Address() > TSRecord(other).Address() Then Return  1
        If Address() < TSRecord(other).Address() Then Return -1
        Return 0
    End Method
    
    Method ToString:String()
        Select Rectype()
            Case S0 Return "S0" + _prvLenAddrDataChk( 2 )
            Case S1 Return "S1" + _prvLenAddrDataChk( 2 )
            Case S2 Return "S2" + _prvLenAddrDataChk( 3 )
            Case S3 Return "S3" + _prvLenAddrDataChk( 4 )
            Case S7 Return "S7" + _prvLenAddrDataChk( 4 )
            Case S8 Return "S8" + _prvLenAddrDataChk( 3 )
            Case S9 Return "S9" + _prvLenAddrDataChk( 2 )
            Default Assert False
        End Select
        Return Null
    End Method
    
    Method _prvLenAddrDataChk:String( al:Int )
        Local chk:Byte = al + Len(_data) + 1
        Local s:String = Right( Hex(chk), 2 )   ' <chk used to place length
        s :+ Right( Hex(_addr), al Shl 1 )      ' <addr
        chk :+ Byte( _addr Shr 24 )             ' <chk address
        chk :+ Byte( _addr Shr 16 )
        chk :+ Byte( _addr Shr 8  )
        chk :+ Byte( _addr        )
        For Local i:Int = 0 Until Len(_data)    ' <chk and place data
            s :+ Right( Hex(_data[i]), 2 )
            chk :+ _data[i]
        Next
        Return s + Right( Hex(~chk), 2 )        ' <invert and place chk
    End Method

    Function Create:TSRecord()
        Return New TSRecord
    End Function
    
    Function CreateFromString:TSRecord( rec:String )
        Local r:TSRecord = Create()
        Const MIN_POSSIBLE_RECSIZE:Int = 10         ' <"ssllaaaacc"
        If rec <> Null Or Len(rec) >= MIN_POSSIBLE_RECSIZE Then
            rec = rec.ToUpper().Trim()
            If Len(rec) Mod 2 Then ..               ' <2n length ?
                Throw TSRecordException.Create( "Invalid Length" )
            Local rt:Int                            ' <extract type
            Select rec[0..2]
                Case "S0" rt = S0
                Case "S1" rt = S1
                Case "S2" rt = S2
                Case "S3" rt = S3
                Case "S7" rt = S7
                Case "S8" rt = S8
                Case "S9" rt = S9                                                                                                                       
                Default Throw TSRecordException.Create( "Unsupported RecType" )
            End Select                      
            Local cl:Int = ("$"+rec[2..4]).ToInt()  ' <peel off chk length while
                                                    '  we're walking down the str
            Local dsi:Int                           ' <data start index
            Select rt                               ' <extract addr
                Case S0, S1, S9 dsi = 8
                Case S2, S8     dsi = 10
                Case S3, S7     dsi = 12
                Default Assert False
            End Select
            Local addr:Int = ("$"+rec[4..dsi]).ToInt()
            If Not IsValidAddressForRectype( addr, rt ) Then ..
                Throw TSRecordException.Create( "Not a valid address for the current record type" )

            rec = rec[2..]                  ' <drop "Sn" and convert the rest
            dsi :- 2                        '  to a byte array
            Local data:Byte[] = New Byte[Len(rec) Shr 1]
            Local i:Int
            For i=0 Until Len(data)
                Local start:Int = i Shl 1
                data[i] = Byte(("$"+rec[start..start+2]).ToInt())
            Next
            i :- 1                      ' <pull chk and drop
            Local chk:Byte = data[i]    '  it from the upcoming
            data = data[..i]            '  calc
            Local cchk:Byte = 0         ' <compute chk
            For Local b:Byte=EachIn(data) 
                cchk :+ b
            Next
            cchk = ~cchk
            If cchk <> chk Then ..          ' <validate chk
                Throw TSRecordException.Create( "Bad Checksum" )
                        
            r._rt = rt                      ' <parse success
            r._addr = addr
            r._data = data[(dsi Shr 1)..]   ' <extract data
        EndIf
        
        Return r
    End Function
    
    Function IsRectype:Int( rt:Int )
        Return rt = S0 Or rt = S1 Or ..
               rt = S2 Or rt = S3 Or rt = S7 Or ..
               rt = S8 Or rt = S9
    End Function
    
    ' comparisons are signed! need to do 'mask' style
    ' address width is dependent on rectype -> do the two jive ?
    Function IsValidAddressForRectype:Int( a:Int, rt:Int )
        Select rt
            Case S0, S1, S9
                ' 16 bit address
                Return Not (a & $ffff0000)
            Case S2, S8
                ' 24 bit address
                Return Not (a & $ff000000)
            Case S3, S7
                ' 32 bit address
                Return True
        End Select
        Return False
    End Function
    
End Type