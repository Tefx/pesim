from .event cimport Event

cdef class Environment:
    cdef dict pqs
    cdef list pq_heap
    cdef float current_time
    cdef list processes

    cpdef add(self, process)
    cdef float next_time(self)
    cdef timeout(self, process, float time, int priority)
    cpdef activate(self, process, float time, int priority)
    cdef Event pop(self)
    cdef Event first(self)
    cpdef start(self)
    cpdef float run_until(self, float ex_time, proc_next=?)
