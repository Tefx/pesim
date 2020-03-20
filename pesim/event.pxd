from .process cimport Process
from .pairing_heap_c cimport MinPairingHeapNode
from libc.stdint cimport int64_t

cdef class Event(MinPairingHeapNode):
    cdef int64_t time_i64
    cdef int priority
    cdef Process process

    cpdef bint cmp(self, MinPairingHeapNode other)
