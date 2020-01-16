from .math cimport feq, flt
cimport cython

@cython.freelist(1024)
cdef class Event:
    def __cinit__(self, double time, Process process, int priority):
        self.time = time
        self.process = process
        self.priority = priority

    def __lt__(self, Event other):
        if feq(self.time, other.time):
            return self.priority < other.priority
        else:
            return flt(self.time, other.time)

    def __repr__(self):
        return "<{}|{}|{}>".format(self.time, self.priority, id(self.process))
