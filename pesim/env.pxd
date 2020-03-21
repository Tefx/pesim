from .process cimport Process
from .event cimport Event
from .pairing_heap_c cimport MinPairingHeap


cdef class Environment:
    cdef readonly MinPairingHeap ev_heap
    cdef readonly double time
    cdef list processes

    cpdef Process add(self, Process process)
    cdef inline void timeout(self, Event ev, double time, int priority)
    cpdef void start(self) except *
    cpdef double run_until(self, double ex_time, int current_priority=?)
    cpdef double next_event_time(self)
