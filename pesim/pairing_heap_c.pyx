from cpython cimport Py_INCREF, Py_DECREF
from cython cimport freelist

@freelist(1024)
cdef class MinPairingHeapNode:
    def __cinit__(self):
        self.left = NULL
        self.right = NULL
        self.first_child = NULL

    cpdef bint cmp(self, MinPairingHeapNode other):
        raise NotImplementedError

    cdef inline void _insert_first_child(self, PyObject*node):
        if self.first_child != NULL:
            (<MinPairingHeapNode> (self.first_child)).left = node
            (<MinPairingHeapNode> node).right = self.first_child
        else:
            (<MinPairingHeapNode> node).right = NULL
        (<MinPairingHeapNode> node).left = <PyObject*> self
        self.first_child = node

    cdef inline void _detach(self):
        if self.right != NULL:
            (<MinPairingHeapNode> self.right).left = self.left
        if (<MinPairingHeapNode> self.left).first_child == <PyObject*> self:
            (<MinPairingHeapNode> self.left).first_child = self.right
        else:
            (<MinPairingHeapNode> self.left).right = self.right
        self.right = NULL
        self.left = NULL

    cdef inline PyObject*_meld(self, PyObject*other):
        if self.cmp(<MinPairingHeapNode> other):
            self._insert_first_child(other)
            return <PyObject*> (self)
        else:
            (<MinPairingHeapNode> other)._insert_first_child(<PyObject*> self)
            return other

    cdef PyObject*_pop(self):
        cdef PyObject *node
        cdef PyObject *right
        cdef PyObject *tmp
        cdef PyObject *last_node
        cdef MinPairingHeapNode x

        if self.first_child == NULL:
            return NULL
        else:
            node = self.first_child
            self.first_child = NULL
            (<MinPairingHeapNode> node).left = NULL

            last_node = NULL
            while True:
                right = (<MinPairingHeapNode> node).right
                if right != NULL:
                    tmp = (<MinPairingHeapNode> right).right
                    (<MinPairingHeapNode> right).right = NULL
                    (<MinPairingHeapNode> right).left = NULL
                    (<MinPairingHeapNode> node).right = NULL
                    node = ((<MinPairingHeapNode> node)._meld(right))

                    (<MinPairingHeapNode> node).left = last_node
                    last_node = node

                    if tmp != NULL:
                        node = tmp
                        (<MinPairingHeapNode> node).left = NULL
                    else:
                        break
                else:
                    (<MinPairingHeapNode> node).left = last_node
                    break

            left = (<MinPairingHeapNode> node).left
            (<MinPairingHeapNode> node).left = NULL
            while left != NULL:
                tmp = (<MinPairingHeapNode> left).left
                (<MinPairingHeapNode> left).left = NULL
                node = ((<MinPairingHeapNode> node)._meld(left))
                left = tmp

            return node

    def _children(self):
        cdef PyObject* node = self.first_child
        while node != NULL:
            yield <MinPairingHeapNode>node
            node = (<MinPairingHeapNode>node).right

    cpdef void print_tree(self, int indent=0):
        cdef MinPairingHeapNode c

        if self.first_child != NULL:
            print(" " * indent + "{} => {}".format(self, [c for c in self._children()]))
            for c in self._children():
                c.print_tree(indent + 2)
        else:
            print(" " * indent + "{} => {}".format(self, None))

    cdef clear_subtree(self):
        cdef MinPairingHeapNode node
        for node in self._children():
            node.clear_subtree()
            Py_DECREF(node)
        self.first_child = NULL

cdef class MinPairingHeap:
    def __init__(self, l=()):
        self.root = NULL
        for x in l:
            self.push(x)

    def __bool__(self):
        return self.root != NULL

    cpdef MinPairingHeapNode first(self):
        if self.root == NULL:
            return None
        else:
            return <MinPairingHeapNode> (self.root)

    cpdef void push(self, MinPairingHeapNode node):
        assert node.left == NULL
        assert node.right == NULL
        assert node.first_child == NULL

        Py_INCREF(node)
        if self.root == NULL:
            self.root = <PyObject*> node
        else:
            self.root = (<MinPairingHeapNode> (self.root))._meld(<PyObject*> node)

    cpdef MinPairingHeapNode pop(self):
        cdef MinPairingHeapNode node
        if self.root == NULL:
            return None
        else:
            node = <MinPairingHeapNode> (self.root)
            self.root = (<MinPairingHeapNode> (self.root))._pop()
            Py_DECREF(node)
            return node

    cpdef void notify_dec(self, MinPairingHeapNode node):
        if node.left != NULL:
            node._detach()
            self.root = (<MinPairingHeapNode> (self.root))._meld(<PyObject*> node)

    cpdef clear(self):
        if self.root:
            (<MinPairingHeapNode>self.root).clear_subtree()
            Py_DECREF(<MinPairingHeapNode>self.root)
            self.root = NULL
