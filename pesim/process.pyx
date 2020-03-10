from inspect import isgenerator

from .math_aux cimport flt
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
        if not flt(self.time, time):
            time = self.time
        self.env.activate(self, time, priority)

    def __call__(self):
        while True:
            self.time = yield self._wait()
            p = self._process()
            if isgenerator(p):
                yield from p

    def setup(self):
        self.process = self()
        self.env.add(self)

    cdef tuple send(self, double time):
        if time < 0:
            return self.process.send(None)
        else:
            return self.process.send(time)

    def next_event_time(self):
        assert self.next_event
        return self.next_event.time
