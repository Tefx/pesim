from libc.stdint cimport int64_t

cdef double _EPSILON
# cdef double _EPSILON_RECIPROCAL

cpdef bint feq(double a, double b)
cpdef bint flt(double a, double b)
cpdef bint fle(double a, double b)

cpdef int64_t d2l(double x)
cpdef double l2d(int64_t x)
