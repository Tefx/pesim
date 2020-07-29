from .process cimport Process
from .pairing_heap cimport MinPairingHeap
from .event cimport Event
from libc.stdint cimport int64_t

cdef class Environment:
    cdef readonly MinPairingHeap ev_heap
    cdef int64_t time_i64
    cdef readonly list processes
    cdef bint started

    cpdef Process add(self, Process process)
    cdef inline void timeout(self, Event ev, double time, int reason)
    cpdef void start(self) except *
    cpdef void finish(self)
    cpdef double run_until(self, double ex_time, int after_reason=?) except *
    cpdef double next_event_time(self)
