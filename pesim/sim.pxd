from .process cimport Process
from .event cimport Event

cdef class Environment:
    cdef list ev_heap
    cdef readonly double current_time
    cdef list processes

    cpdef Process add(self, Process process)
    # cdef double next_time(self)
    cdef void timeout(self, Process process, double time, int priority)
    cpdef void activate(self, Process process, double time, int priority)
    cdef Event first(self)
    cpdef void start(self)
    cpdef double run_until(self, double ex_time, Process proc_next=?)
    # cpdef void pre_ev_hook(self, double time)
    # cpdef void post_ev_hook(self, double time)

    cpdef double next_event_time(self)
