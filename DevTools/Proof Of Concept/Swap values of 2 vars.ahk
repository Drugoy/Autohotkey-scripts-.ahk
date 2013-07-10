x := 1041
y := 205
Swap(y,x)
Swap(ByRef x, ByRef y)
{
    x ^= y
    y ^= x
    x ^= y
}
msgbox % x y