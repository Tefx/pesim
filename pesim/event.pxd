from .process cimport Process
from .pairing_heap cimport MinPairingHeapNode
from libc.stdint cimport int64_t

cdef class Event(MinPairingHeapNode):
    cdef int64_t time_i64
    cdef Process process
    cdef int reason

    cpdef bint key_lt(self, MinPairingHeapNode other)
