from libc.math cimport ceil

_EPSILON = 1e-4

cdef double _EPSILON1 = _EPSILON * 10
cdef double _EPSILON1_RECIPROCAL = 1.0 / _EPSILON1

# EPSILON1 = _EPSILON1
# EPSILON1_RECIPROCAL = _EPSILON1_RECIPROCAL

cpdef bint feq(double a, double b):
    return -_EPSILON < a - b < _EPSILON

cpdef bint flt(double a, double b):
    return a + _EPSILON <= b

cpdef bint fle(double a, double b):
    return a < b + _EPSILON

cpdef int64_t d2l(double x):
    cdef int64_t y
    x *= _EPSILON1_RECIPROCAL
    y = <int64_t> (x + 1)
    return y - <int64_t> (y - x)

cpdef double l2d(int64_t x):
    return <double> (x * _EPSILON1)

# cdef double d2d(double x):
#     # return <int64_t>(x * _EPSILON1_RECIPROCAL + .999) * _EPSILON1
#     return (_LONG_MAX_L - <int64_t>(_LONG_MAX_D - x * _EPSILON1_RECIPROCAL)) * _EPSILON1

