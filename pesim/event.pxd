from .process cimport Process
from .pairing_heap_c cimport MinPairingHeapNode
from libc.stdint cimport int64_t

cdef class Event(MinPairingHeapNode):
    cdef readonly int64_t time_i64
    cdef readonly int priority
    cdef readonly Process process

    cpdef bint cmp(self, MinPairingHeapNode other)
