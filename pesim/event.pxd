cdef class Event:
    cdef public float time
    cdef readonly object process
    cdef public int priority

