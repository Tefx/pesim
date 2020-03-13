from .math_aux cimport d2l, l2d
from libc.stdint cimport int64_t

cdef class Event(MinPairingHeapNode):
    def __cinit__(self, int64_t time_i64, Process process, int priority):
        self.time_i64 = time_i64
        self.process = process
        self.priority = priority

    cpdef bint cmp(self, MinPairingHeapNode other):
        cdef int64_t other_time_i64 = (<Event>other).time_i64
        cdef int other_priority = (<Event>other).priority
        if self.time_i64 > other_time_i64:
            return False
        else:
            return self.time_i64 < other_time_i64 or self.priority < other_priority

    @property
    def time(self):
        return l2d(self.time_i64)

    def __repr__(self):
        return "<{}|{}|{}>".format(l2d(self.time_i64), self.priority, id(self.process) % 1000)
