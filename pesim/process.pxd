from .pairing_heap cimport MinPairingHeap
from .event cimport Event
from .sim cimport Environment


cdef class Process:
    cdef readonly Environment env
    # cdef readonly double time
    cdef object process
    cdef object id
    cdef readonly bint _is_waiting
    cdef Event event
    cdef MinPairingHeap ev_heap

    cpdef tuple _wait(self)
    cpdef _process(self)
    cpdef void activate(self, double time, int reason)
    cpdef void start(self) except *
    cpdef void finish(self)
    cpdef void setup_env(self, env)
    cdef void run_step(self) except *


