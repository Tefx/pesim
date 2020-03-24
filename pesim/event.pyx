from .math_aux cimport d2l, l2d
from libc.stdint cimport int64_t

cdef class Event(MinPairingHeapNode):
    def __init__(self, int64_t time_i64, Process process, int reason):
        self.time_i64 = time_i64
        self.process = process
        self.reason = reason

    cpdef bint key_lt(self, MinPairingHeapNode other):
        cdef int64_t other_time_i64 = (<Event>other).time_i64
        cdef int other_reason = (<Event>other).reason
        if self.time_i64 > other_time_i64:
            return False
        else:
            return self.time_i64 < other_time_i64 or self.reason < other_reason

    @property
    def time(self):
        return l2d(self.time_i64)

    def __repr__(self):
        return "<{}|{}|{}>".format(l2d(self.time_i64), self.reason, id(self.process) % 1000)
