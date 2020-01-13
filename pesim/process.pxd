from .event cimport Event
from .sim cimport Environment

cdef class Process:
    cdef public Environment env
    cdef public float time
    cdef public object process
    cdef object id
    cdef Event next_event

    cpdef _wait(self, int priority=?)
    cpdef _process(self)
    cpdef activate(self, float time, int priority)
    cdef tuple send(self, float time)

