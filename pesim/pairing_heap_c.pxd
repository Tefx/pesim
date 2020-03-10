from cpython cimport PyObject, Py_INCREF, Py_DECREF

cdef class MinPairingHeapNode:
    cdef PyObject *first_child
    cdef PyObject *left
    cdef PyObject *right

    cpdef bint cmp(self, MinPairingHeapNode other)
    cdef void _insert_first_child(self, PyObject* node)
    cdef void _detach(self)
    cdef PyObject* _meld(self, PyObject* other)
    cdef PyObject* _pop(self)
    cpdef void print_tree(self, int indent=?)
    cdef clear_subtree(self)

cdef class MinPairingHeap:
    cdef PyObject* root

    cpdef MinPairingHeapNode first(self)
    cpdef void push(self, MinPairingHeapNode node)
    cpdef MinPairingHeapNode pop(self)
    cpdef void notify_dec(self, MinPairingHeapNode node)
    cpdef clear(self)
