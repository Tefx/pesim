from .event cimport Event
from .sim cimport Environment

cdef class Process:
    cdef public Environment env
    cdef public double time
    cdef public object process
    cdef object id
    cdef Event next_event

    cpdef tuple _wait(self, int priority=?)
    cpdef _process(self)
    cpdef void activate(self, double time, int priority)
    cdef tuple send(self, double time)

