from .process cimport Process

cdef class Event:
    cdef public double time
    cdef readonly Process process
    cdef public int priority

    cdef bint ltcmp(self, Event other)
