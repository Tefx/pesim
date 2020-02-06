import heapq
from enum import Enum

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

    # cdef double next_time(self):
    #     cdef Event ev = self.first()
    #     if ev is not None:
    #         return ev.time
    #     else:
    #         return _TIME_FOREVER
    #
    # cpdef void pre_ev_hook(self, double time):
    #     pass
    #
    # cpdef void post_ev_hook(self, double time):
    #     pass

    cdef void timeout(self, Process process, double time, int priority):
        cdef Event ev

        if flt(time, self.current_time):
            time = self.current_time

        ev = Event(time, process, priority)
        process.next_event = ev
        heapq.heappush(self.ev_heap, ev)
        # print(self.current_time, "PUSH", ev.time, ev.priority, ev.priority.value if isinstance(ev.priority, Enum) else None, self.ev_heap[:3])

    cpdef void activate(self, Process process, double time, int priority):
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

    cpdef void start(self):
        cdef double time
        cdef int priority
        cdef Process process

        for process in self.processes:
            time, priority = process.send(-1)
            self.timeout(process, time, priority)

    cpdef double run_until(self, double ex_time, Process proc_next=None):
        cdef Event ev
        cdef double time
        cdef int priority

        cdef Event last_ev = None

        ev = self.first()
        while ev is not None and fle(ev.time, ex_time):
            ev = heapq.heappop(self.ev_heap)
            # if last_ev:
            #     print(self.current_time, "LAST", last_ev.time, last_ev.priority, last_ev.priority.value if isinstance(last_ev.priority, Enum) else None, self.ev_heap[:3])
            # print(self.current_time, "CURRENT", ev.time, ev.priority, ev.priority.value if isinstance(ev.priority, Enum) else None, self.ev_heap[:3])
            # assert last_ev is None or last_ev <= ev
            last_ev = ev
            self.current_time = max(self.current_time, ev.time)
            # try:
            # self.pre_ev_hook(self.current_time)
            time, priority = ev.process.send(self.current_time)
            self.timeout(ev.process, time, priority)
            # self.post_ev_hook(self.current_time)
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
            return self.next_event_time()

    cpdef double next_event_time(self):
        ev = self.first()
        if ev is not None:
            return ev.time
        else:
            return _TIME_FOREVER
