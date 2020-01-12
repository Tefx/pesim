from .process cimport Process

cdef class Event:
    cdef public float time
    cdef readonly Process process
    cdef public int priority

    cdef bint ltcmp(self, Event other)
