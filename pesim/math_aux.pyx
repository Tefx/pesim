from libc.math cimport round

cdef double EPSILON_RECIPROCAL = 1e3

cpdef int64_t d2l(double x):
    return <int64_t>round(x * EPSILON_RECIPROCAL)

cpdef double l2d(int64_t x):
    return (<double>x) / EPSILON_RECIPROCAL

cpdef bint time_eq(double a, double b):
    return d2l(a) == d2l(b)

cpdef bint time_le(double a, double b):
    return d2l(a) <= d2l(b)

cpdef bint time_lt(double a, double b):
    return d2l(a) < d2l(b)

cpdef bint time_ge(double a, double b):
    return d2l(a) >= d2l(b)

cpdef bint time_gt(double a, double b):
    return d2l(a) > d2l(b)
