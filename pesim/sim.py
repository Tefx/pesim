import heapq

TIME_FOREVER = 10 * 365 * 24 * 60 * 60


class Event:
    def __init__(self, time, process, priority):
        self.time = time
        self.process = process
        self.priority = priority

    def __lt__(self, other):
        if self.time == other.time:
            return self.priority < other.priority
        else:
            return self.time < other.time

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
        assert(len(self.queue) == 1)

    def pop(self):
        assert(len(self.queue) == 1)
        return heapq.heappop(self.queue)

    def first(self):
        return self.queue[0]


class Environment:
    def __init__(self):
        self.pqs = {}
        self.pq_heap = []
        self.current_time = 0
        self.processes = []

    def add(self, process):
        self.processes.append(process)
        return process

    def timeout(self, process, time, priority):
        if time < self.current_time: time = self.current_time
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
        if time < self.current_time: time = self.current_time
        pq = self.pqs[id(process)]
        if time < pq.first().time:
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
        ev = self.first()
        while ev and ev.time <= ex_time:
            ev = self.pop()
            self.current_time = max(self.current_time, ev.time)
            try:
                time, priority = ev.process.send(self.current_time)
                self.timeout(ev.process, time, priority)
            except StopIteration:
                pass
            ev = self.first()
        self.current_time = ex_time
        if proc_next:
            pq = self.pqs[id(proc_next)]
            if len(pq) > 0:
                time = pq.first().time
                if time == TIME_FOREVER:
                    # print(self.first(), self.pq_heap[0].queue)
                    return self.first().time
                else:
                    return time
            else:
                print("error proc has empty event queue")
        else:
            return self.first().time
