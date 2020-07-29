from inspect import isgenerator

from .math_aux cimport l2d, d2l
from .define cimport _TIME_PASSED, _TIME_FOREVER
from .sim cimport Environment
from libc.stdint cimport int64_t
from cpython cimport PyObject


cdef class Process:
    def __init__(self, Environment env):
        # self.time = 0
        self.process = None
        self.ev_heap = None
        # self.event = Event(0, self, _TIME_PASSED)
        self.event = None
        self.setup_env(env)

        if env.started:
            self.start()


    cpdef void setup_env(self, env):
        self.env = env
        self.ev_heap = self.env.ev_heap
        self.env.add(self)

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
            self.ev_heap.notify_dec_x(<PyObject*>(self.event))

    def __call__(self):
        while True:
            yield self._wait()
            p = self._process()
            if isgenerator(p):
                yield from p

    cpdef void start(self):
        cdef double time
        cdef int reason

        self.process = self()
        time, reason = self.process.send(None)
        self.event = Event(max(self.env.time_i64, d2l(time)), self, reason)
        # self.event.time_i64 = max(self.env.time_i64, d2l(time))
        # self.event.reason = reason
        self.ev_heap.push_x(<PyObject*>(self.event))

    cdef void run_step(self) except *:
        cdef double time
        cdef int reason

        time, reason = self.process.send(self.event.reason)
        self.event.time_i64 = max(self.env.time_i64, d2l(time))
        self.event.reason = reason
        self.ev_heap.push_x(<PyObject*>(self.event))

    cpdef void finish(self):
        pass

    def next_event_time(self):
        return l2d(self.event.time_i64)

    @property
    def time(self):
        return self.env.time

def make_process(env, func, *args, **kwargs):
    class _Process(Process):
        def __call__(self):
            yield from func(self, *args, **kwargs)
            yield _TIME_FOREVER, _TIME_PASSED
    return _Process(env)

