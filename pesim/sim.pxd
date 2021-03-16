from .process cimport Process
from .pairing_heap cimport MinPairingHeap
from .event cimport Event
from libc.stdint cimport int64_t

cdef class Environment:
    cdef MinPairingHeap ev_heap
    cdef int64_t time_i64
    cdef list processes
    cdef readonly bint started
    cdef readonly double stop_time

    cpdef void add(self, Process process)
    cdef inline void timeout(self, Event ev, double time, int reason)
    cpdef void start(self) except *
    cpdef void finish(self)
    cpdef double run_until(self, double ex_time, int after_reason=?)
    cpdef double join(self)
    cpdef double next_event_time(self)
    cpdef Event next_event(self)
