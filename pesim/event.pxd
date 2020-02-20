from .process cimport Process
from.pairing_heap_c cimport MinPairingHeapNode

cdef class Event(MinPairingHeapNode):
    cdef public double time
    cdef public int priority
    cdef readonly Process process

    cpdef bint cmp(self, MinPairingHeapNode other)
