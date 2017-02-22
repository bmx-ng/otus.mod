' Minimal test that the lzma module works.

SuperStrict

Framework BRL.StandardIO

Import Otus.Lzma

Const DATA_BYTES% = 2560000


Print "Generating "+DATA_BYTES+" bytes of sequential data..."

?bmxng
Local rsize:Size_T
Local csize:Size_T
Local dsize:Size_T
?Not bmxng
Local rsize%
Local csize%
Local dsize%
?

rsize = DATA_BYTES
Local raw:Byte[rsize]
Local rbuf:Byte Ptr = raw

For Local i% = 0 Until DATA_BYTES
	rbuf[i] = i
Next

Print "Done."


Print "Compressing data using default level..."

csize = DATA_BYTES
Local comp:Byte[csize]

LzmaCompress comp, csize, raw, rsize

Print "Done: "+csize+" bytes."


Print "Compressing data using maximum compression level..."

csize = DATA_BYTES

LzmaCompress2 comp, csize, raw, rsize, 9

Print "Done: "+csize+" bytes."


Print "Uncompressing data..."

dsize = DATA_BYTES
Local Dec:Byte[dsize]

LzmaUncompress Dec, dsize, comp, csize

Print "Done: "+dsize+" bytes."


Print "Verifying integrity..."

If dsize <> DATA_BYTES Then Print "Failed!" ; End

Local dbuf:Byte Ptr = Dec

For Local i% = 0 Until dsize
	If Byte(dbuf[i] - i) Then Print "Failed!" ; End
Next

Print "Done."

