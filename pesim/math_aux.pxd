from libc.stdint cimport int64_t

cdef double _EPSILON
cdef double _EPSILON_RECIPROCAL

cpdef bint feq(double a, double b)
cpdef bint flt(double a, double b)
cpdef bint fle(double a, double b)

cdef int64_t d2l(double x)
cdef double l2d(int64_t x)
cdef double d2d(double x)
