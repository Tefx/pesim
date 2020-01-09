from .event cimport Event

cdef class ProcessQueue:
    cdef list queue

    cdef push(self, Event item)
    cdef Event pop(self)
    cdef Event first(self)
