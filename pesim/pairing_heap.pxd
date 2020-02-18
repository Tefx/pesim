cdef class MinPairingHeapNode:
    cdef MinPairingHeapNode left, right, first_child

    cpdef bint cmp(self, MinPairingHeapNode other)
    cdef MinPairingHeapNode _insert_first_child(self, MinPairingHeapNode node)
    cdef void _detach(self)
    cdef MinPairingHeapNode _meld(self, MinPairingHeapNode other)
    cdef MinPairingHeapNode _pop(self)
    cpdef void print_tree(self, int indent=?)

cdef class MinPairingHeap:
    cdef MinPairingHeapNode root

    cpdef MinPairingHeapNode first(self)
    cpdef void push(self, node)
    cpdef MinPairingHeapNode pop(self)
    cpdef void notify_dec(self, MinPairingHeapNode node)
