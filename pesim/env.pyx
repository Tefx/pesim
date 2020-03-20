from .math_aux cimport d2l, l2d
from .define cimport _TIME_FOREVER, _PRIORITY_MAX
from .event cimport Event
from libc.stdint cimport int64_t


cdef class Environment:
    def __init__(self):
        self.ev_heap = MinPairingHeap()
        self.time = 0
        self.processes = []

    cpdef Process add(self, Process process):
        self.processes.append(process)
        return process

    cdef inline void timeout(self, Event ev, double time, int priority):
        ev.time_i64 = d2l(max(self.time, time))
        ev.priority = priority
        self.ev_heap.push(ev)

    cpdef void start(self) except *:
        cdef double time
        cdef int priority
        cdef Process process

        for process in self.processes:
            process.time = self.time
            time, priority = process.process.send(None)
            self.timeout(process.event, time, priority)

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
            self.timeout(ev, time, priority)
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
