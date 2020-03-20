from .pairing_heap_c cimport MinPairingHeap
from .event cimport Event
from .env cimport Environment


cdef class Process:
    cdef public Environment env
    cdef readonly double time
    cdef public object process
    cdef object id
    cdef readonly Event event
    cdef MinPairingHeap ev_heap

    cpdef tuple _wait(self, int priority=?)
    cpdef _process(self)
    cpdef void activate(self, double time, int priority)

