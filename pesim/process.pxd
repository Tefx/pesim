from .event cimport Event
from .sim cimport Environment
from libc.stdint cimport int64_t

cdef class Process:
    cdef public Environment env
    cdef readonly double time
    cdef public object process
    cdef object id
    cdef readonly Event next_event

    cpdef tuple _wait(self, int priority=?)
    cpdef _process(self)
    cpdef void activate(self, double time, int priority)

