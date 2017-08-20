SuperStrict

Rem
bbdoc: Streams/Lzma Streams
End Rem
Module Otus.LzmaStream

ModuleInfo "Version: 1.02"
ModuleInfo "Author: Jan Varho"
ModuleInfo "License: Public domain"

ModuleInfo "History: 1.02"
ModuleInfo "History: Updated for NG."
ModuleInfo "History: 1.01"
ModuleInfo "History: Added Discard method"
ModuleInfo "History: Added 4 bytes to header"
ModuleInfo "History: Fixed memory access error"

Import BRL.BankStream
Import BRL.Stream
Import Otus.LZMA

Rem
bbdoc: LZMA stream wrapper type
about:
#TLzmaStream wraps a raw stream and allows access to uncompressed data.

When writing, the data is compressed and the compressed daa written to the wrapped stream.
If compression expands the data, uncompressed data is written instead.

Changes in the raw stream don't automatically appear in a TLzmaStream 
- #ReadSync updates to the current raw stream, but any changes are lost.

Similarly, changes written to a TLzmaStream are only written to the raw stream 
on a Flush/FlushStream call or when the stream is closed.

Note: You may lose data if you fail to close/flush the stream before program ends.
Do not rely on the automatic Delete->Close call!
End Rem
Type TLzmaStream Extends TStreamWrapper
	
	Field _basestream:TStream
	
	Field _level:Int = 5
	
	Field _closed:Int
	
Rem
bbdoc: Closes the stream, writing any changes
End Rem
	Method Close()
		If _closed Return
		Flush()
		If _basestream Then _basestream.Close()
		If _stream Then _stream.Close()
		_closed = True
	End Method
	
Rem
bbdoc: Closes the stream, discarding any changes
End Rem
	Method Discard()
		If _closed Return
		_basestream = Null
		If _stream Then _stream.Close()
		_closed = True
	End Method
	
Rem
bbdoc: Updates to current raw stream data
End Rem
	Method ReadSync()
		'Empty stream?
		If _basestream.Size()=0
			_stream = CreateBankStream(Null)
			Return
		End If
		
		'Verify header
		_basestream.Seek(0)
		If _basestream.ReadInt() <> $4c5a4d41	'LZMA
			Return
		End If
		_basestream.Seek(0)
		
		'Copy stream contents to a bank
?bmxng
		Local b:TBank = TBank.Create(Size_T(_basestream.Size()))
?Not bmxng
		Local b:TBank = TBank.Create(_basestream.Size())
?
		CopyStream _basestream, CreateBankStream(b)
		
		'Set up bank for raw access
		Local buf:Byte Ptr = b.Lock()
		
		'Is this uncompressed data?
?bmxng
		Local size:Size_T = b.Size()-8
		Local usize:Long = Int Ptr(buf)[1] + 1
?Not bmxng		
		Local size:Int = b.Size()-8
		Local usize:Int = Int Ptr(buf)[1] + 1
?
		If usize<=1
			If -usize <> size Return
?bmxng
			Local u:TBank = TBank.Create(Size_T(-usize))
			Local ubuf:Byte Ptr = u.Lock()
			MemCopy ubuf, buf+8, Size_T(-usize)
?Not bmxng		
			Local u:TBank = TBank.Create(-usize)
			Local ubuf:Byte Ptr = u.Lock()
			MemCopy ubuf, buf+8, -usize
?
			u.Unlock()
			_stream = CreateBankStream(u)
			Return
		End If
		
		
		'Create a bank for uncompressed data
?bmxng
		Local u:TBank = TBank.Create(Size_T(usize))
		Local ubuf:Byte Ptr = u.Lock()

		Local us:Size_T = Size_T(usize)
		LzmaUncompress ubuf, us, buf+8, size
		usize = us
?Not bmxng		
		Local u:TBank = TBank.Create(usize)
		Local ubuf:Byte Ptr = u.Lock()

		LzmaUncompress ubuf, usize, buf+8, size
?
		
		
		'Not valid LZMA?
		If usize <> u.Size()-1 Then Return
		
		u.Unlock()
?bmxng
		u.Resize(Size_T(usize))
?Not bmxng
		u.Resize(usize)
?
		
		_stream = CreateBankStream(u)
	End Method
	
Rem
bbdoc: Flushes current data to the raw stream
End Rem
	Method Flush()

		'Set up bank for raw access
		Local b:TBank = TBankStream(_stream)._bank
?bmxng
		Local bsize:Size_T = b.Size()
?Not bmxng
		Local bsize:Int = b.Size()
?
		Local buf:Byte Ptr = b.Lock()
		
		'Create bank for compressed data
?bmxng
		Local csize:Size_T = bsize + 1024
?Not bmxng
		Local csize:Int = bsize + 1024
?
		Local c:TBank = TBank.Create(csize)
		Local cbuf:Byte Ptr = c.Lock()
		
		LzmaCompress2 cbuf, csize, buf, bsize, _level

		_basestream.Seek 0

		'Does it fit? 
		If csize<b.Size()
			_basestream.WriteInt $4c5a4d41	'LZMA
			_basestream.WriteInt Int(b.Size())
			_basestream.WriteBytes cbuf, csize
		Else
			'Write uncompressed
			_basestream.WriteInt $4c5a4d41	'LZMA
			_basestream.WriteInt Int(-b.Size())
			_basestream.WriteBytes buf, b.Size()
		End If
		
		b.Unlock()
	End Method
	
	Function Create:TLzmaStream( stream:TStream )
		'Stream must be seekable
		If stream=Null Or stream.Seek(0)=-1 Then Return Null
		
		Local l:TLzmaStream = New TLzmaStream
		l._basestream = stream
		l.ReadSync()
		
		If Not l._stream Then Return Null
		
		Return l
	End Function
	
End Type

Rem
bbdoc: Opens #url as TLzmaStream
about:
An alternative to using OpenStream("lzma::-blah").
End Rem
Function CreateLzmaStream:TLzmaStream( url:Object )
	Return TLzmaStream.Create( OpenStream(url) )
End Function

New TLzmaStreamFactory

Type TLzmaStreamFactory Extends TStreamFactory
	
	Method CreateStream:TStream( url:Object,proto$,path$,readable%,writeable% )
		If proto<>"lzma" Then Return Null
		Local stream:TStream = OpenStream(path, readable, writeable)
		Assert stream<>Null
		Return TLzmaStream.Create( stream )
	End Method
	
End Type

