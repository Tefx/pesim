from .math_aux cimport d2l, l2d
from .define cimport _TIME_FOREVER, _TIME_PASSED
from .event cimport Event
from libc.stdint cimport int64_t

cdef class Environment:
    def __init__(self):
        self.ev_heap = MinPairingHeap()
        self.time_i64 = 0
        self.processes = []
        self.started = False

    cpdef Process add(self, Process process):
        self.processes.append(process)
        # if self.started:
        #     process.start()
            # time, reason = process.process.send(None)
            # self.timeout(process.event, time, reason)

    cdef inline void timeout(self, Event ev, double time, int reason):
        ev.time_i64 = max(self.time_i64, d2l(time))
        ev.reason = reason
        self.ev_heap.push(ev)

    cpdef void start(self) except *:
        cdef double time
        cdef int priority
        cdef Process process

        for process in self.processes:
            process.start()
            # time, reason = process.process.send(None)
            # self.timeout(process.event, time, reason)

        self.started = True

    cpdef void finish(self):
        cdef Process process
        for process in self.processes:
            process.finish()

    cpdef double run_until(self, double ex_time, int after_reason=_TIME_PASSED) except *:
        cdef Event ev
        # cdef double time
        # cdef int reason
        cdef int64_t ex_time_i64 = d2l(ex_time)

        ev = self.ev_heap.first()
        while ev.time_i64 < ex_time_i64 or \
                (ev.time_i64 == ex_time_i64 and ev.reason <= after_reason):
            ev = self.ev_heap.pop()
            if self.time_i64 < ev.time_i64:
                self.time_i64 = ev.time_i64
            ev.process.run_step()
            # time, reason = ev.process.process.send(ev.reason)
            # self.timeout(ev, time, reason)
            ev = self.ev_heap.first()

        if self.time_i64 < ex_time_i64:
            self.time_i64 = ex_time_i64

        return l2d(self.time_i64)

    @property
    def time(self):
        return l2d(self.time_i64)

    cpdef double next_event_time(self):
        cdef Event ev = self.ev_heap.first()
        if ev is not None:
            return l2d(ev.time_i64)
        else:
            return _TIME_FOREVER
