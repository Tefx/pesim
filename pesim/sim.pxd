from .process cimport Process
from .event cimport Event

cdef class Environment:
    cdef list ev_heap
    cdef readonly double current_time
    cdef list processes

    cpdef Process add(self, Process process)
    cdef double next_time(self)
    cdef timeout(self, Process process, double time, int priority)
    cpdef activate(self, Process process, double time, int priority)
    cdef Event first(self)
    cpdef start(self)
    cpdef double run_until(self, double ex_time, Process proc_next=?)
    cpdef pre_ev_hook(self, double time)
    cpdef post_ev_hook(self, double time)
