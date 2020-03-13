_EPSILON = 1e-3
_EPSILON_RECIPROCAL = 1.0 / _EPSILON

EPSILON = _EPSILON
EPSILON_RECIPROCAL = _EPSILON_RECIPROCAL


cpdef bint feq(double a, double b):
    return -_EPSILON < a - b < _EPSILON

cpdef bint flt(double a, double b):
    return a + _EPSILON <= b

cpdef bint fle(double a, double b):
    return a < b + _EPSILON

cdef int64_t d2l(double x):
    return <int64_t>(x * EPSILON_RECIPROCAL + .999)

cdef double l2d(int64_t x):
    return <double>(x * _EPSILON)

cdef double d2d(double x):
    return <int64_t>(x * EPSILON_RECIPROCAL + .999) * _EPSILON
