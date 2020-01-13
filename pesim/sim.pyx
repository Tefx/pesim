import heapq

from .math cimport flt, fle, feq
from .define cimport _TIME_FOREVER


cdef class Environment:
    def __init__(self):
        self.ev_heap = []
        self.current_time = 0
        self.processes = []

    cpdef Process add(self, Process process):
        self.processes.append(process)
        return process

    cdef float next_time(self):
        cdef Event ev = self.first()
        if ev is not None:
            return ev.time
        else:
            return _TIME_FOREVER

    cpdef pre_ev_hook(self, float time):
        pass

    cpdef post_ev_hook(self, float time):
        pass

    cdef timeout(self, Process process, float time, int priority):
        cdef Event ev

        if flt(time, self.current_time):
            time = self.current_time

        ev = Event(time, process, priority)
        process.next_event = ev
        heapq.heappush(self.ev_heap, ev)

    cpdef activate(self, Process process, float time, int priority):
        cdef Event ev

        if flt(time, self.current_time):
            time = self.current_time

        ev = process.next_event
        if flt(time, ev.time):
            ev.time = time
            ev.priority = priority
            i = self.ev_heap.index(ev)
            heapq._siftdown(self.ev_heap, 0, i)

    cdef Event first(self):
        if self.ev_heap:
            return self.ev_heap[0]
        else:
            return None

    cpdef start(self):
        cdef float time
        cdef int priority
        cdef Process process

        for process in self.processes:
            time, priority = process.send(-1)
            self.timeout(process, time, priority)

    cpdef float run_until(self, float ex_time, Process proc_next=None):
        cdef Event ev
        cdef float time
        cdef int priority

        ev = self.first()
        while ev is not None and fle(ev.time, ex_time):
            ev = heapq.heappop(self.ev_heap)
            self.current_time = max(self.current_time, ev.time)
            # try:
            self.pre_ev_hook(self.current_time)
            time, priority = ev.process.send(self.current_time)
            self.timeout(ev.process, time, priority)
            self.post_ev_hook(self.current_time)
            # except StopIteration:
            #     pass
            ev = self.first()
        self.current_time = ex_time
        if proc_next is not None:
            ev = proc_next.next_event
            if feq(ev.time, _TIME_FOREVER):
                ev = self.first()
            return ev.time
        else:
            ev = self.first()
            if ev is not None:
                return ev.time
            else:
                return _TIME_FOREVER
