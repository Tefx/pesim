from .process cimport Process
from .pairing_heap cimport MinPairingHeap

cdef class Environment:
    cdef MinPairingHeap ev_heap
    cdef readonly double current_time
    cdef list processes

    cpdef Process add(self, Process process)
    cdef void timeout(self, Process process, double time, int priority)
    cpdef void activate(self, Process process, double time, int priority)
    cpdef void start(self)
    cpdef void run_until(self, double ex_time, Process proc_next=?)
    cpdef double next_event_time(self)
