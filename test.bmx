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

'
' test parts of the lodur codebase
'
SuperStrict
Import BaH.Maxunit
Import "src\TImage.bmx"
Import "src\TSRecord.bmx"

New TTestSuite.run()

Type TTestTImage Extends TTest

    Field i:TImage

    Method TestDefaultCreate() { test }
        i = TImage.Create( 4 )
        assertNotNull( i )
        assertEqualsI( i.Size(), 4 )
    End Method

    Method TestSimpleGetIter() { test }
        i = TImage.Create( 4 )
        assertEqualsI( i.Address(), $00 )

        assertEqualsB( i.GetNext(), $ff )
        assertEqualsI( i.Address(), $01 )

        assertEqualsB( i.GetNext(), $ff )
        assertEqualsI( i.Address(), $02 )

        assertEqualsB( i.GetNext(), $ff )
        assertEqualsI( i.Address(), $03 )
    End Method

    Method TestGetIterClampUpper() { test }
        i = TImage.Create( 4 )
        ' grab (and autoinc) item at end of image
        ' make sure address is clamped properly
        assertEqualsB( i.Get($03), $ff )
        assertEqualsI( i.Address(), $03 )
    End Method

    Method TestSimpleSetIter() { test }
        i = TImage.Create( 4 )
        assertEqualsI( i.Address(), $00 )

        i.SetNext( $00 )
        assertEqualsI( i.Address(), $01 )

        i.SetNext( $11 )
        assertEqualsI( i.Address(), $02 )

        i.SetNext( $22 )
        assertEqualsI( i.Address(), $03 )

        i.SetNext( $33 )
        assertEqualsI( i.Address(), $03 )   ' clamp!

        ' read back while we're at it:
        assertEqualsB( i.Get( $00 ), $00 )
        assertEqualsB( i.GetNext(),  $11 )
        assertEqualsB( i.GetNext(),  $22 )
        assertEqualsB( i.GetNext(),  $33 )
        assertEqualsB( i.GetNext(),  $33 )
        assertEqualsB( i.GetNext(),  $33 )
        assertEqualsB( i.GetNext(),  $33 )
    End Method

    Method TestSetIterClampUpper() { test }
        i = TImage.Create( 4 )
        ' set (and autoinc) item at end of image
        ' make sure address is clamped properly
        i.Set( $03, $11 )
        assertEqualsI( i.Address(), $03 )
        assertEqualsB( i.GetNext(), $11 )
        assertEqualsB( i.GetNext(), $11 )
    End Method

    Method TestCreateWithBaseAndBlank() { test }
        i = TImage.Create( 4, $20000000, $aa )
        assertEqualsI( i.Address(), $20000000 )

        assertEqualsB( i.GetNext(), $aa )
        assertEqualsI( i.Address(), $20000001 )

        assertEqualsB( i.GetNext(), $aa )
        assertEqualsI( i.Address(), $20000002 )

        assertEqualsB( i.GetNext(), $aa )
        assertEqualsI( i.Address(), $20000003 )

        assertEqualsB( i.GetNext(), $aa )
        assertEqualsI( i.Address(), $20000003 )
    End Method

    Method TestBaseAddrUpperClamp() { test }
        i = TImage.Create( 4, $20000000, $aa )
        i.SetAddress( $1fff0000 )
        assertEqualsI( i.Address(), $20000000 )
    End Method

    Method TestBaseAddrLowerClamp() { test }
        i = TImage.Create( 4, $20000000, $aa )
        i.SetAddress( $20001000 )
        assertEqualsI( i.Address(), $20000003 )
    End Method
    
End Type

Type TTestTSRecord Extends TTest

    Field r:TSRecord
    Field excOccured:Int

    Method Setup() { before }
        r = TSRecord.Create()
        assertNotNull( r )
        assertTrue( IsDefaultSRecord(r) )
        excOccured = False
    End Method

    Method TestAddressS0() { test }
        r.SetAddress( $ffff )
        assertEqualsI( r.Address(), $ffff )
    End Method

    Method TestAddressTooBigForRectypeS0Throws() { test }
        ' S0 type only handles addresses up to 16bits in length
        Try
            r.SetAddress( $10000 )
        Catch rte:TSRecordException
            assertTrue( rte.ToString() = "Not a valid address for the current record type" )
            excOccured = True
        Catch o:Object
            ' catching anything else but the specific type above is a failure
            fail( "TSRecordException not caught" )
        End Try
        assertTrue( excOccured )
    End Method

    Method TestAddressS1() { test }
        r.SetRectype( TSRecord.S1 )
        assertEqualsI( r.Rectype(), TSRecord.S1 )
        r.SetAddress( $ffff )
        assertEqualsI( r.Address(), $ffff )
    End Method

    Method TestAddressTooBigForRectypeS1Throws() { test }
        ' S1 type only handles addresses up to 16bits in length
        r.SetRectype( TSRecord.S1 )
        Try
            r.SetAddress( $10000 )
        Catch rte:TSRecordException
            assertTrue( rte.ToString() = "Not a valid address for the current record type" )
            excOccured = True
        Catch o:Object
            ' catching anything else but the specific type above is a failure
            fail( "TSRecordException not caught" )
        End Try
        assertTrue( excOccured )
    End Method

    Method TestAddressS2() { test }
        r.SetRectype( TSRecord.S2 )
        assertEqualsI( r.Rectype(), TSRecord.S2 )
        r.SetAddress( $ffffff )
        assertEqualsI( r.Address(), $ffffff )
    End Method

    Method TestAddressTooBigForRectypeS2Throws() { test }
        ' S2 type only handles addresses up to 24bits in length
        r.SetRectype( TSRecord.S2 )
        Try
            r.SetAddress( $1000000 )
        Catch rte:TSRecordException
            assertTrue( rte.ToString() = "Not a valid address for the current record type" )
            excOccured = True
        Catch o:Object
            ' catching anything else but the specific type above is a failure
            fail( "TSRecordException not caught" )
        End Try
        assertTrue( excOccured )
    End Method

    Method TestAddressS3() { test }
        r.SetRectype( TSRecord.S3 )
        assertEqualsI( r.Rectype(), TSRecord.S3 )
        r.SetAddress( $ffffffff )
        assertEqualsI( r.Address(), $ffffffff )
    End Method

    Method TestAddressTooBigForRectypeS3() { test }
        ' S3 type only handles addresses up to 32bits in length
        ' since address in an Int and can contain the entire address
        ' nothing tested
    End Method

    Method TestBadAddressShrinkThrows() { test }
        ' if an address is shunk and the existing one is too big to be
        ' represented, then throw
        r.SetRectype( TSRecord.S3 )
        assertEqualsI( r.Rectype(), TSRecord.S3 )
        r.SetAddress( $ffffffff )
        assertEqualsI( r.Address(), $ffffffff )
        Try
            r.SetRectype(TSRecord.S1)
        Catch rte:TSRecordException
            assertTrue( rte.ToString() = "Not a valid address for the current record type" )
            excOccured = True
        Catch o:Object
            ' catching anything else but the specific type above is a failure
            fail( "TSRecordException not caught" )
        End Try
        assertTrue( excOccured )
        assertEqualsI( r.Rectype(), TSRecord.S3 )
        ' now go back and clamp address and try again
        r.SetAddress( $ffff )
        r.SetRectype(TSRecord.S1)
        assertEqualsI( r.Rectype(), TSRecord.S1 )
        assertEqualsI( r.Address(), $ffff )
    End Method

    Method TestCompare() { test }
        ' sort works on address field, make sure compare
        ' behaves as expected
        Local other:TSRecord = TSRecord.Create()
        assertTrue( r.Compare(other) = 0 )  ' equal
        other.SetAddress( $1000 )
        assertTrue( r.Compare(other) < 0 )  ' address is smaller
        r.SetAddress( $2000 )
        assertTrue( r.Compare(other) > 0 )  ' address is larger
    End Method

    Method TestSimpleDataCompare() { test }
        Local d0:Byte[] = [1:Byte, 2:Byte, 3:Byte, 4:Byte]
        r.SetData( d0 )
        Local d1:Byte[] = r.Data()
        ' validate that they're the same, but more importantly, that they reference
        ' unique arrays - data in the srec is NOT MUTABLE, so alloc/copy operations
        ' are performed
        assertNotSame( d0, d1 )
        assertTrue( IsDataEqual(d0,d1) )
        ' wiping data by assigning null is allowed
        r.SetData( Null )
        assertTrue( r.Data() = Null )
    End Method

    Method TestDefaultToString() { test }
        assertEquals( r.ToString(), "S0030000FC" )
    End Method

    Method TestCreateFromStringDefault() { test }
        ' empty string or null results in default record 
        ' (just call Create() in these cases)
        r = TSRecord.CreateFromString( "" )
        assertTrue( IsDefaultSRecord(r) )
        assertEquals( r.ToString(), "S0030000FC" )
    End Method

    Method TestCreateFromNullString() { test }
        ' empty string or null results in default record 
        ' (just call Create() in these cases)
        r = TSRecord.CreateFromString( Null )
        assertTrue( IsDefaultSRecord(r) )
        assertEquals( r.ToString(), "S0030000FC" )
    End Method

    Method TestCreateFromStringS8() { test }
        Local s:String = "S80400C0003B"
        r = TSRecord.CreateFromString( s )
        assertEqualsI( r.Address(), $00C000 )
        assertEqualsI( r.Rectype(), TSRecord.S8 )
        assertTrue( r.Data() = Null )
        assertEquals( r.ToString(), s )
    End Method

    Method TestCreateFromStringS2() { test }
        Local s:String = "S214E08800000000000000000100000002000000037D"
        r = TSRecord.CreateFromString( s )
        assertEqualsI( r.Address(), $E08800 )
        assertEqualsI( r.Rectype(), TSRecord.S2 )
        assertTrue( IsDataEqual( r.Data(), ..
          [ $00:Byte, $00:Byte, $00:Byte, $00:Byte, $00:Byte, $00:Byte, $00:Byte, ..
            $01:Byte, $00:Byte, $00:Byte, $00:Byte, $02:Byte, $00:Byte, $00:Byte, ..
            $00:Byte, $03:Byte ] ) )
        assertEquals( r.ToString(), s )
    End Method

    Method TestCreateFromStringS0() { test }
        Local s:String = "S02B00006669726D776172652F46726565454D532D302E322E302D534E415053484F542D3139322D673439352A"
        r = TSRecord.CreateFromString( s )
        assertEqualsI( r.Address(), $0000 )
        assertEqualsI( r.Rectype(), TSRecord.S0 )
        assertTrue( IsDataEqual( r.Data(), ..
          [ $66:Byte, $69:Byte, $72:Byte, $6D:Byte, $77:Byte, $61:Byte, $72:Byte, ..
            $65:Byte, $2F:Byte, $46:Byte, $72:Byte, $65:Byte, $65:Byte, $45:Byte, ..
            $4D:Byte, $53:Byte, $2D:Byte, $30:Byte, $2E:Byte, $32:Byte, $2E:Byte, ..
            $30:Byte, $2D:Byte, $53:Byte, $4E:Byte, $41:Byte, $50:Byte, $53:Byte, ..
            $48:Byte, $4F:Byte, $54:Byte, $2D:Byte, $31:Byte, $39:Byte, $32:Byte, ..
            $2D:Byte, $67:Byte, $34:Byte, $39:Byte, $35:Byte ] ) )
        assertEquals( r.ToString(), s )
    End Method

    Method TestLowerCaseAccepted() { test }
        r = TSRecord.CreateFromString( "s80400c0003b" )
        assertEqualsI( r.Address(), $00C000 )
        assertEqualsI( r.Rectype(), TSRecord.S8 )
        assertTrue( r.Data() = Null )
        assertEquals( r.ToString(), "S80400C0003B" )
    End Method

    Method TestLeadTrailWhitespaceAccepted() { test }
        r = TSRecord.CreateFromString( "  ~t~n S80400C0003B  ~t ~r ~n  ~n" )
        assertEqualsI( r.Address(), $00C000 )
        assertEqualsI( r.Rectype(), TSRecord.S8 )
        assertTrue( r.Data() = Null )
        assertEquals( r.ToString(), "S80400C0003B" )
    End Method

    Method TestWrongChkThrows() { test }
        Try
            r = TSRecord.CreateFromString( "S80400C0003E" )
        Catch rte:TSRecordException
            assertTrue( rte.ToString() = "Bad Checksum" )
            excOccured = True
        Catch o:Object
            ' catching anything else but the specific type above is a failure
            fail( "TSRecordException not caught" )
        End Try
        assertTrue( excOccured )
    End Method

    Method TestWrongLengthThrows() { test }
        Try
            r = TSRecord.CreateFromString( "S80300C0003B" )
        Catch rte:TSRecordException
            ' can result in a few different strings
            assertTrue( rte.ToString() <> Null )
            excOccured = True
        Catch o:Object
            ' catching anything else but the specific type above is a failure
            fail( "TSRecordException not caught" )
        End Try
        assertTrue( excOccured )
    End Method

    Method TestNotMod2Throws() { test }
        Try
            r = TSRecord.CreateFromString( "S80400C0003BA" )
        Catch rte:TSRecordException
            ' can result in a few different strings
            assertTrue( rte.ToString() <> Null )
            excOccured = True
        Catch o:Object
            ' catching anything else but the specific type above is a failure
            fail( "TSRecordException not caught" )
        End Try
        assertTrue( excOccured )
    End Method

    Method TestUnsupportedRectypeThrows() { test }
        Try
            r = TSRecord.CreateFromString( "S50400C0003B" )
        Catch rte:TSRecordException
            ' can result in a few different strings
            assertTrue( rte.ToString() <> Null )
            excOccured = True
        Catch o:Object
            ' catching anything else but the specific type above is a failure
            fail( "TSRecordException not caught" )
        End Try
        assertTrue( excOccured )
    End Method
    
    Function IsDefaultSRecord:Int( r:TSRecord )
        Return r.Address() = 0 And r.Rectype() = TSRecord.S0 And r.Data() = Null
    End Function

    Function IsDataEqual:Int( d0:Byte[], d1:Byte[] )
        If Len(d0) = Len(d1) Then
            Local i:Int = Len(d0)
            While i
                i:-1
                If d0[i] <> d1[i] Then Return False
            End While
            Return True
        End If
        Return False
    End Function

End Type

