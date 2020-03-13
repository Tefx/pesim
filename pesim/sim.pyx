from .math_aux cimport d2l, l2d, d2d
from .define cimport _TIME_FOREVER, _PRIORITY_MAX
from .event cimport Event
from libc.stdint cimport int64_t
cimport cython

cdef class Environment:
    def __init__(self):
        self.ev_heap = MinPairingHeap()
        self.time = 0
        self.processes = []

    cpdef Process add(self, Process process):
        self.processes.append(process)
        return process

    cdef void timeout(self, Process process, double time, int priority):
        if time < self.time:
            process.next_event = Event(d2l(self.time), process, priority)
        else:
            process.next_event = Event(d2l(time), process, priority)
        self.ev_heap.push(process.next_event)

    cdef void activate(self, Process process, double time, int priority):
        cdef Event ev
        cdef int64_t time_i64

        if time < self.time:
            time_i64 = d2l(self.time)
        else:
            time_i64 = d2l(time)

        ev = process.next_event
        if time_i64 < ev.time_i64:
            ev.time_i64 = time_i64
            ev.priority = priority
            self.ev_heap.notify_dec(ev)

    cpdef void start(self) except *:
        cdef double time
        cdef int priority
        cdef Process process

        for process in self.processes:
            process.time = self.time
            time, priority = process.process.send(None)
            self.timeout(process, time, priority)

    cpdef double run_until(self, double ex_time, int current_priority=_PRIORITY_MAX):
        cdef Event ev
        cdef double time
        cdef int priority
        cdef int64_t ex_time_i64 = d2l(ex_time)

        ev = self.ev_heap.first()
        while ev.time_i64 < ex_time_i64 or \
                (ev.time_i64 == ex_time_i64 and ev.priority <= current_priority):
            ev = self.ev_heap.pop()
            if d2l(self.time) < ev.time_i64:
                self.time = l2d(ev.time_i64)
            ev.process.time = self.time
            time, priority = ev.process.process.send(None)
            self.timeout(ev.process, time, priority)
            ev = self.ev_heap.first()

        if d2l(self.time) < ex_time_i64:
            self.time = l2d(ex_time_i64)

        return self.time

    cpdef double next_event_time(self):
        cdef Event ev = self.ev_heap.first()
        if ev is not None:
            return l2d(ev.time_i64)
        else:
            return _TIME_FOREVER
