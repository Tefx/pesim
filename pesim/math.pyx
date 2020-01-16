EPSILON = _EPSILON

cpdef bint feq(double a, double b):
    return -_EPSILON < a - b < _EPSILON

cpdef bint flt(double a, double b):
    return b - a > _EPSILON

cpdef bint fle(double a, double b):
    return b - a > -_EPSILON
