from .math cimport feq, flt

cdef class Event:
    def __init__(self, float time, process, int priority):
        self.time = time
        self.process = process
        self.priority = priority

    def __lt__(self, Event other):
        return self.ltcmp(other)

    cdef bint ltcmp(self, Event other):
        if feq(self.time, other.time):
            return self.priority < other.priority
        else:
            return flt(self.time, other.time)

    def __repr__(self):
        return "<{}|{}|{}>".format(self.time, self.priority, id(self.process))
