from .process cimport Process
from .event cimport Event

cdef class Environment:
    cdef list ev_heap
    cdef readonly float current_time
    cdef list processes

    cpdef Process add(self, Process process)
    cdef float next_time(self)
    cdef timeout(self, Process process, float time, int priority)
    cpdef activate(self, Process process, float time, int priority)
    cdef Event first(self)
    cpdef start(self)
    cpdef float run_until(self, float ex_time, Process proc_next=?)
    cpdef pre_ev_hook(self, float time)
    cpdef post_ev_hook(self, float time)
