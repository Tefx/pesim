EPSILON = _EPSILON

cpdef bint feq(float a, float b):
    return -_EPSILON < a - b < _EPSILON

cpdef bint flt(float a, float b):
    return b - a > _EPSILON

cpdef bint fle(float a, float b):
    return b - a > -_EPSILON
