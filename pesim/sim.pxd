from .process cimport Process
from .pairing_heap_c cimport MinPairingHeap

cdef class Environment:
    cdef readonly MinPairingHeap ev_heap
    cdef readonly double current_time
    cdef list processes

    cpdef Process add(self, Process process)
    cdef void timeout(self, Process process, double time, int priority)
    cpdef void activate(self, Process process, double time, int priority)
    cpdef void start(self) except *
    cpdef void run_until(self, double ex_time, int current_priority=?)
    cpdef double next_event_time(self)
