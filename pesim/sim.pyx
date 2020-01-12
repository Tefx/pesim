import heapq

from .math cimport flt, fle, feq
from .define cimport _TIME_FOREVER
from .queue cimport ProcessQueue


cdef class Environment:
    def __init__(self):
        # self.pqs = {}
        self.pq_heap = []
        self.current_time = 0
        self.processes = []

    cpdef Process add(self, Process process):
        self.processes.append(process)
        heapq.heappush(self.pq_heap, process.pq)
        return process

    cdef float next_time(self):
        ev = self.first()
        if ev:
            return ev.time
        else:
            return _TIME_FOREVER

    cpdef pre_ev_hook(self, time):
        pass

    cpdef post_ev_hook(self, time):
        pass

    cdef timeout(self, Process process, float time, int priority):
        cdef Event event
        cdef ProcessQueue pq

        if flt(time, self.current_time):
            time = self.current_time
        event = Event(time, process, priority)
        pq = process.pq
        pq.push(event)
        heapq.heapify(self.pq_heap)

    cpdef activate(self, Process process, float time, int priority):
        cdef ProcessQueue pq
        cdef Event ev

        if flt(time, self.current_time):
            time = self.current_time

        pid = process.id
        pq = process.pq
        # pq = self.pqs[pid]
        if flt(time, pq.first().time):
            ev = pq.pop()
            ev.time = time
            ev.priority = priority
            pq.push(ev)
            heapq.heapify(self.pq_heap)

    cdef Event pop(self):
        cdef ProcessQueue pq
        cdef Event ev

        if self.pq_heap and self.pq_heap[0]:
            pq = heapq.heappop(self.pq_heap)
            event = pq.pop()
            heapq.heappush(self.pq_heap, pq)
            return event
        else:
            return None

    cdef Event first(self):
        cdef ProcessQueue pq
        if self.pq_heap and self.pq_heap[0]:
            pq = self.pq_heap[0]
            return pq.first()
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
        cdef ProcessQueue pq

        ev = self.first()
        while ev and fle(ev.time, ex_time):
            ev = self.pop()
            self.current_time = max(self.current_time, ev.time)
            try:
                self.pre_ev_hook(self.current_time)
                time, priority = ev.process.send(self.current_time)
                self.timeout(ev.process, time, priority)
                self.post_ev_hook(self.current_time)
            except StopIteration:
                pass
            ev = self.first()
        self.current_time = ex_time
        if proc_next:
            pq = proc_next.pq
            # pq = self.pqs[proc_next.id]
            if pq:
                ev = pq.first()
                if feq(ev.time, _TIME_FOREVER):
                    ev = self.first()
                    return ev.time
                else:
                    return ev.time
            else:
                print("error proc has empty event queue")
        else:
            ev = self.first()
            if ev:
                return ev.time
            else:
                return _TIME_FOREVER
