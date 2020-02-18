from .math_aux cimport flt, fle
from .define cimport _TIME_FOREVER
from .event cimport Event


cdef class Environment:
    def __init__(self):
        self.ev_heap = MinPairingHeap()
        self.current_time = 0
        self.processes = []

    cpdef Process add(self, Process process):
        self.processes.append(process)
        return process

    cdef void timeout(self, Process process, double time, int priority):
        cdef Event ev

        if flt(time, self.current_time):
            time = self.current_time

        ev = Event(time, process, priority)
        process.next_event = ev
        self.ev_heap.push(ev)

    cpdef void activate(self, Process process, double time, int priority):
        cdef Event ev

        if flt(time, self.current_time):
            time = self.current_time

        ev = process.next_event
        if flt(time, ev.time):
            ev.time = time
            ev.priority = priority
            self.ev_heap.notify_dec(ev)

    cpdef void start(self):
        cdef double time
        cdef int priority
        cdef Process process

        for process in self.processes:
            time, priority = process.send(-1)
            self.timeout(process, time, priority)

    cpdef void run_until(self, double ex_time, Process proc_next=None):
        cdef Event ev
        cdef double time
        cdef int priority

        ev = self.ev_heap.first()
        while ev is not None and fle(ev.time, ex_time):
            ev = self.ev_heap.pop()
            self.current_time = max(self.current_time, ev.time)
            time, priority = ev.process.send(self.current_time)
            self.timeout(ev.process, time, priority)
            ev = self.ev_heap.first()
        self.current_time = ex_time

    cpdef double next_event_time(self):
        ev = self.ev_heap.first()
        if ev is not None:
            return ev.time
        else:
            return _TIME_FOREVER
