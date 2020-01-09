from inspect import isgenerator

from .math cimport flt
from .define cimport _PRIORITY_MAX, _TIME_FOREVER
from .sim cimport Environment

cdef class Process:
    cdef public Environment env
    cdef public float time
    cdef public object process

    def __init__(self, Environment env):
        self.env = env
        self.time = 0
        self.process = None

    def _wait(self, int priority=_PRIORITY_MAX):
        return _TIME_FOREVER, priority

    def _process(self):
        raise NotImplementedError

    def activate(self, float time, int priority):
        if not flt(self.time, time):
            time = self.time
        self.env.activate(self.process, time, priority)

    def __call__(self):
        while True:
            self.time = yield self._wait()
            p = self._process()
            if isgenerator(p):
                yield from self._process()

    def setup(self):
        self.process = self()
        self.env.add(self.process)