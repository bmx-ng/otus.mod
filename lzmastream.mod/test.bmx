'Tests Otus.LzmaStream
SuperStrict

Framework BRL.StandardIO

Import BRL.FileSystem

Import Otus.LzmaStream

'Write a compressed file

Local out:TStream = WriteStream("lzma::test.txt")

For Local i% = 1 To 10
	out.WriteLine "Hello World"
	out.WriteLine "This is a test."
Next

out.Close()

'Read the compressed file

Local in:TStream = ReadStream("lzma::test.txt")

While Not in.Eof()
	Print in.ReadLine()
Wend

Print "Done."

