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
' generate a test srec of random data
'

SuperStrict
Import "src\TSRecord.bmx"

Local str:TStream = WriteFile( "random.s19" )
Assert str

Local r:TSRecord = TSRecord.Create()
str.WriteLine( r.ToString() )	' S0 by default

r.SetRectype( TSRecord.S3 )
r.SetAddress( $40000000 )
For Local i:Int = 0 Until 128 ' 2048 = 48k
	Local cnt:Int = 24
	r.SetData( gen(cnt) )
	str.WriteLine( r.ToString() )
	r.SetAddress( r.Address() + cnt )
Next

r.SetRectype( TSRecord.S7 )
r.SetAddress( $40000000 )
r.SetData( Null )
str.WriteLine( r.ToString() )
str.Close()

Function gen:Byte[]( byte_cnt:Int )
	Local a:Byte[] = New Byte[byte_cnt]
	For Local i:Int = 0 Until Len(a)
		a[i] = Rand( $00, $ff )
	Next
	Return a
End Function
