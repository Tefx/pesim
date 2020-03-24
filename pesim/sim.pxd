from .process cimport Process
from .pairing_heap cimport MinPairingHeap
from .event cimport Event

cdef class Environment:
    cdef readonly MinPairingHeap ev_heap
    cdef readonly double time
    cdef list processes

    cpdef Process add(self, Process process)
    cdef inline void timeout(self, Event ev, double time, int reason)
    cpdef void start(self) except *
    cpdef void finish(self)
    cpdef double run_until(self, double ex_time, int after_reason=?) except *
    cpdef double next_event_time(self)
