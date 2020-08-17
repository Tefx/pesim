from .process cimport Process
from .pairing_heap cimport MinPairingHeapNode
from libc.stdint cimport int64_t

cdef class Event(MinPairingHeapNode):
    cdef readonly int64_t time_i64
    cdef readonly Process process
    cdef readonly int reason

    cpdef bint key_lt(self, MinPairingHeapNode other)
