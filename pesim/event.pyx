from .math_aux cimport feq, flt

cdef class Event(MinPairingHeapNode):
    def __cinit__(self, double time, Process process, int priority):
        self.time = time
        self.process = process
        self.priority = priority

    cpdef bint cmp(self, MinPairingHeapNode other):
        if feq(self.time, (<Event>other).time):
            return self.priority < (<Event>other).priority
        else:
            return flt(self.time, (<Event>other).time)

    def __repr__(self):
        return "<{}|{}|{}>".format(self.time, self.priority, id(self.process) % 1000)
