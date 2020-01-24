
_EPSILON = 1e-3
EPSILON = _EPSILON

cpdef bint feq(double a, double b):
    return -_EPSILON < a - b < _EPSILON

cpdef bint flt(double a, double b):
    return a + _EPSILON < b

cpdef bint fle(double a, double b):
    return a < b + _EPSILON
