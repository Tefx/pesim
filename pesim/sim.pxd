from .process cimport Process
from .pairing_heap_c cimport MinPairingHeap
from libc.stdint cimport int64_t

cdef class Environment:
    cdef readonly MinPairingHeap ev_heap
    cdef readonly double time
    cdef list processes

    cpdef Process add(self, Process process)
    cdef void timeout(self, Process process, double time, int priority)
    cdef void activate(self, Process process, double time, int priority)
    cpdef void start(self) except *
    cpdef double run_until(self, double ex_time, int current_priority=?)
    cpdef double next_event_time(self)
