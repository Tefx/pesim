from inspect import isgenerator

from libc.stdint cimport int64_t
from .math_aux cimport l2d, d2l
from .define cimport _PRIORITY_MAX, _TIME_FOREVER
from .env cimport Environment

cdef class Process:
    def __init__(self, Environment env):
        self.env = env
        self.time = 0
        self.process = None
        self.id = id(self)
        self.ev_heap = None
        self.event = Event(0, self, _PRIORITY_MAX)

    cpdef tuple _wait(self, int priority=_PRIORITY_MAX):
        return _TIME_FOREVER, priority

    cpdef _process(self):
        raise NotImplementedError

    def __call__(self):
        while True:
            yield self._wait()
            p = self._process()
            if isgenerator(p):
                yield from p

    cpdef void activate(self, double time, int priority):
        cdef Event ev
        cdef int64_t time_i64 = d2l(max(self.env.time, time))
        if time_i64 < self.event.time_i64:
            self.event.time_i64 = time_i64
            self.event.priority = priority
            self.ev_heap.notify_dec(self.event)

    def setup(self):
        self.process = self()
        self.env.add(self)
        self.ev_heap = self.env.ev_heap

    def next_event_time(self):
        return l2d(self.event.time_i64)
