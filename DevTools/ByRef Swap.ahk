Swap(ByRef a, ByRef b)	; A function to exchange values of two variables without the need to create 3rd temporary one.
{
	a ^= b
	b ^= a
	a ^= b
}