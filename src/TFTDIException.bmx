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
Import "IFTDIException.bmx"

Public
Type TFTDIOpenNodeException Extends TFTDIException
    Function Create:TFTDIOpenNodeException( s:String = "" )
        Local me:TFTDIOpenNodeException = New TFTDIOpenNodeException
        _create( me, s )
        Return me
    End Function
End Type

Public
Type TFTDIBadFlagsException Extends TFTDIException
    Function Create:TFTDIBadFlagsException( s:String = "" )
        Local me:TFTDIBadFlagsException = New TFTDIBadFlagsException
        _create( me, s )
        Return me
    End Function
End Type

Public
Type TFTDIBadIndexException Extends TFTDIException
    Function Create:TFTDIBadIndexException( s:String = "" )
        Local me:TFTDIBadIndexException = New TFTDIBadIndexException
        _create( me, s )
        Return me
    End Function
End Type

Public
Type TFTDILibraryCallFailException Extends TFTDIException
    Function Create:TFTDILibraryCallFailException( s:String = "" )
        Local me:TFTDILibraryCallFailException = New TFTDILibraryCallFailException
        _create( me, s )
        Return me
    End Function
End Type

Public
Type TFTDILibraryLoadFailException Extends TFTDIException
    Function Create:TFTDILibraryLoadFailException( s:String = "" )
        Local me:TFTDILibraryLoadFailException = New TFTDILibraryLoadFailException
        _create( me, s )
        Return me
    End Function
End Type

Public
Type TFTDIException Extends IFTDIException 

    Field _s:String = Null
    
    Method ToString:String()
        Return _s
    End Method
    
    Function Create:TFTDIException( s:String = "" )
        Local me:TFTDIException = New TFTDIException
        _create( me, s )
        Return me
    End Function
    
    Function _create( me:TFTDIException, s:String )
        Assert me
        me._s = TTypeId.ForObject( me ).Name() + " : " + s
    End Function
    
End Type