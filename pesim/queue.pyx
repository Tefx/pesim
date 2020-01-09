import heapq


cdef class ProcessQueue:
    def __init__(self):
        self.queue = []

    def __lt__(self, ProcessQueue other):
        if not self.queue:
            return not other.queue
        else:
            return not other.queue or self.queue[0] < other.queue[0]

    def __len__(self):
        return len(self.queue)

    def __bool__(self):
        return bool(self.queue)

    cdef push(self, Event item):
        heapq.heappush(self.queue, item)
        # assert len(self.queue) == 1

    cdef Event pop(self):
        # assert len(self.queue) == 1
        return heapq.heappop(self.queue)

    cdef Event first(self):
        return self.queue[0]