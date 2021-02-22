from libc.stdint cimport int64_t

cpdef int64_t d2l(double x)
cpdef double l2d(int64_t x)

cpdef bint time_eq(double a, double b)
cpdef bint time_le(double a, double b)
cpdef bint time_lt(double a, double b)
cpdef bint time_ge(double a, double b)
cpdef bint time_gt(double a, double b)
