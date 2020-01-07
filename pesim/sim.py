import heapq
from inspect import isgenerator

TIME_FOREVER = 10 * 365 * 24 * 60 * 60
PRIORITY_MAX = 100000
EPSILON = 1e-3


def feq(a, b):
    return -EPSILON < a - b < EPSILON


def flt(a, b):
    return b - a > EPSILON


def fle(a, b):
    return b - a > -EPSILON

class Event:
    def __init__(self, time, process, priority):
        self.time = time
        self.process = process
        self.priority = priority

    def __lt__(self, other):
        if feq(self.time, other.time):
        # if self.time == other.time:
            return self.priority < other.priority
        else:
            return flt(self.time, other.time)
            # return self.time < other.time

    def __repr__(self):
        return "<{}|{}|{}>".format(self.time, self.priority, id(self.process))


class ProcessQueue:
    def __init__(self):
        self.queue = []

    def __lt__(self, other):
        if len(self.queue) == 0:
            return len(self.queue) == 0
        else:
            return self.queue[0] < other.queue[0]

    def __len__(self):
        return len(self.queue)

    def push(self, item):
        heapq.heappush(self.queue, item)
        assert (len(self.queue) == 1)

    def pop(self):
        assert (len(self.queue) == 1)
        return heapq.heappop(self.queue)

    def first(self):
        return self.queue[0]


class Process:
    def __init__(self, env):
        self.env = env
        self.time = 0
        self.process = None

    def _wait(self, priority=PRIORITY_MAX):
        return TIME_FOREVER, priority

    def _process(self):
        raise NotImplementedError

    def activate(self, time, priority):
        # self.env.activate(self.process, time if time > self.time else self.time, priority)
        self.env.activate(self.process, time if flt(self.time, time) else self.time, priority)

    def __call__(self):
        while True:
            self.time = yield self._wait()
            p = self._process()
            if isgenerator(p):
                yield from self._process()

    def setup(self):
        self.process = self()
        self.env.add(self.process)


class Environment:
    def __init__(self):
        self.pqs = {}
        self.pq_heap = []
        self.current_time = 0
        self.processes = []

    def add(self, process):
        self.processes.append(process)
        return process

    def next_time(self):
        ev = self.first()
        if ev:
            return ev.time
        else:
            return TIME_FOREVER

    def pre_ev_hook(self, time):
        pass

    def post_ev_hook(self, time):
        pass

    def timeout(self, process, time, priority):
        if flt(time, self.current_time):
        # if time < self.current_time:
            time = self.current_time
        event = Event(time, process, priority)

        pid = id(process)
        if pid not in self.pqs:
            pq = ProcessQueue()
            self.pqs[pid] = pq
            pq.push(event)
            heapq.heappush(self.pq_heap, pq)
        else:
            self.pqs[pid].push(event)
            heapq.heapify(self.pq_heap)

    def activate(self, process, time, priority):
        if flt(time, self.current_time):
        # if time < self.current_time:
            time = self.current_time
        pq = self.pqs[id(process)]
        if flt(time, pq.first().time):
        # if time < pq.first().time:
            ev = pq.pop()
            ev.time = time
            ev.priority = priority
            pq.push(ev)
            heapq.heapify(self.pq_heap)

    def pop(self):
        if len(self.pq_heap) > 0 and len(self.pq_heap[0]) > 0:
            pq = heapq.heappop(self.pq_heap)
            event = pq.pop()
            heapq.heappush(self.pq_heap, pq)
            return event
        else:
            return None

    def first(self):
        if len(self.pq_heap) > 0 and len(self.pq_heap[0]) > 0:
            return self.pq_heap[0].first()
        else:
            return None

    def start(self):
        for process in self.processes:
            time, priority = process.send(None)
            self.timeout(process, time, priority)

    def run_until(self, ex_time, proc_next=None):
        # assert ex_time >= self.current_time
        assert fle(self.current_time, ex_time)
        ev = self.first()
        while ev and fle(ev.time, ex_time):
        # while ev and ev.time <= ex_time:
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
            pq = self.pqs[id(proc_next)]
            if len(pq) > 0:
                time = pq.first().time
                if time == TIME_FOREVER:
                    return self.first().time
                else:
                    return time
            else:
                print("error proc has empty event queue")
        else:
            ev = self.first()
            if ev:
                return ev.time
            else:
                return TIME_FOREVER
