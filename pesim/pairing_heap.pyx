cdef class MinPairingHeapNode:
    def __cinit__(self):
        self.left = None
        self.right = None
        self.first_child = None

    cpdef bint cmp(self, other):
        raise NotImplementedError

    cdef MinPairingHeapNode _insert_first_child(self, MinPairingHeapNode node):
        if self.first_child is not None:
            self.first_child.left = node
            node.right = self.first_child
        node.left = self
        self.first_child = node
        return self

    cdef bint _is_first_child(self):
        return self.left.first_child is self

    cdef void _detach(self):
        if self.right is not None:
            self.right.left = self.left
        if self._is_first_child():
            self.left.first_child = self.right
        else:
            self.left.right = self.right

    cdef MinPairingHeapNode _meld(self, MinPairingHeapNode other):
        if self.cmp(other):
            return self._insert_first_child(other)
        else:
            return other._insert_first_child(self)

    cdef MinPairingHeapNode _pop(self):
        cdef MinPairingHeapNode node, right, tmp, last_node
        if self.first_child is None:
            return None
        else:
            node = self.first_child
            self.first_child = None
            node.left = None

            last_node = None
            while True:
                right = node.right
                if right is not None:
                    tmp = right.right
                    right.right = None
                    right.left = None
                    node.right = None
                    node = node._meld(right)

                    node.left = last_node
                    last_node = node

                    if tmp is not None:
                        node = tmp
                        node.left = None
                    else:
                        break
                else:
                    node.left = last_node
                    break

            left = node.left
            while left is not None:
                tmp = left.left
                left.left = None
                node.left = None
                node = node._meld(left)
                left = tmp

            return node

    def children(self):
        cdef MinPairingHeapNode node = self.first_child
        while node:
            yield node
            node = node.right

    cpdef void print_tree(self, int indent=0):
        cdef MinPairingHeapNode c

        if self.first_child:
            print(" " * indent + "{} => {}".format(self, [c for c in self.children()]))
            for c in self.children():
                c.print_tree(indent + 2)
        else:
            print(" " * indent + "{} => {}".format(self, None))

cdef class MinPairingHeap:
    def __init__(self):
        self.root = None

    def __bool__(self):
        return self.root is not None

    cpdef MinPairingHeapNode first(self):
        return self.root

    cpdef void push(self, node):
        if self.root is None:
            self.root = node
        else:
            self.root = self.root._meld(node)

    cpdef MinPairingHeapNode pop(self):
        cdef MinPairingHeapNode node = self.root
        self.root = node._pop()
        return node

    cpdef void notify_dec(self, MinPairingHeapNode node):
        if node.left is not None:
            node._detach()
            self.root = self.root._meld(node)

