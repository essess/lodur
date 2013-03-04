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

Type TImage

    Field _bank:TBank = Null
    Field _base_addr:Int = 0
    Field _offset:Int = 0
    
    'Public
    Method Get:Byte( addr:Int )
        SetAddress( addr )
        Return GetNext()
    End Method
    
    Method GetNext:Byte()
        Local b:Byte = _bank.PeekByte( _offset )
        _offset :+ 1
        _prvClampUpper()
        Return b
    End Method
    
    Method SetAddress( addr:Int )
        If addr < _base_addr Then addr = _base_addr
        _offset = addr - _base_addr
        _prvClampUpper()
    End Method
    
    Method Address:Int()
        Return _base_addr + _offset
    End Method
    
    Method Size:Int()
        Return _bank.Size()
    End Method

    Method Base:Int()
        Return _base_addr
    End Method
    
    'Friend/Protected
    Method Set( addr:Int, b:Byte )
        SetAddress( addr )
        SetNext( b )
    End Method
    
    Method SetNext( b:Byte )
        Assert _offset < _bank.Size()
        _bank.PokeByte( _offset, b )
        _offset :+ 1
        _prvClampUpper()
    End Method
    
    Method _prvClampUpper()
        Local s:Int = _bank.Size() - 1
        If _offset > s Then _offset = s
    End Method
    
    Function Create:TImage( size:Int=1024*32, base_addr:Int=0, blank:Byte=$ff )
        Assert size
        Local me:TImage = New TImage; Assert me
        me._bank = TBank.Create( size ); Assert me._bank
        For Local i:Int = 0 Until size      ' < wipe to blank value
            me._bank.PokeByte( i, blank )
        Next
        me._base_addr = base_addr
        me._offset = 0
        Return me
    End Function

End Type