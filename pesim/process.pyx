from inspect import isgenerator

from .math_aux cimport l2d, d2l
from .define cimport _TIME_PASSED, _TIME_FOREVER
from .sim cimport Environment
from libc.stdint cimport int64_t


cdef class Process:
    def __init__(self, Environment env):
        # self.time = 0
        self.process = None
        self.ev_heap = None
        self.event = Event(0, self, _TIME_PASSED)
        self.setup_env(env)

    cpdef void setup_env(self, env):
        self.env = env
        self.env.add(self)
        self.ev_heap = self.env.ev_heap

    cpdef tuple _wait(self):
        return _TIME_FOREVER, _TIME_PASSED

    cpdef _process(self):
        raise NotImplementedError

    cpdef void activate(self, double time, int reason):
        cdef Event ev
        cdef int64_t time_i64 = max(self.env.time_i64, d2l(time))
        if time_i64 < self.event.time_i64:
            self.event.time_i64 = time_i64
            self.event.reason = reason
            self.ev_heap.notify_dec(self.event)

    def __call__(self):
        while True:
            yield self._wait()
            p = self._process()
            if isgenerator(p):
                yield from p

    cpdef void start(self):
        self.process = self()

    cpdef void finish(self):
        pass

    def next_event_time(self):
        return l2d(self.event.time_i64)

    @property
    def time(self):
        return self.env.time

def make_process(func):
    def wrapped(env, *args, **kwargs):
        class _Process(Process):
            def __call__(self):
                return func(env, *args, **kwargs)
        return _Process(env)
    return wrapped

