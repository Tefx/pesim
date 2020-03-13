from inspect import isgenerator

from .math_aux cimport l2d, d2d
from .define cimport _PRIORITY_MAX, _TIME_FOREVER
from .sim cimport Environment

cdef class Process:
    def __init__(self, Environment env):
        self.env = env
        self.time = 0
        self.process = None
        self.id = id(self)
        self.next_event = None

    cpdef tuple _wait(self, int priority=_PRIORITY_MAX):
        return _TIME_FOREVER, priority

    cpdef _process(self):
        raise NotImplementedError

    cpdef void activate(self, double time, int priority):
        if time < self.time:
            self.env.activate(self, self.time, priority)
        else:
            self.env.activate(self, time, priority)

    def __call__(self):
        while True:
            yield self._wait()
            p = self._process()
            if isgenerator(p):
                yield from p

    def setup(self):
        self.process = self()
        self.env.add(self)

    def next_event_time(self):
        return l2d(self.next_event.time_i64)
