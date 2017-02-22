// Wrapper for the Encode function without filtering

#include "lzmasdk/LzmaUtil/Lzma86Enc.c"

void _LzmaCompress( Byte *dest, size_t *destLen, const Byte *src, size_t srcLen,
    int level, UInt32 dictSize )
{
	Lzma86_Encode( dest, destLen, src, srcLen, level, dictSize, SZ_FILTER_NO );
}

