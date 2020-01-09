cdef class ProcessQueue:
    def __init__(self):
        self.event = None

    def __lt__(self, ProcessQueue other):
        if self.event is None:
            return other.event is None
        else:
            return other.event is None or self.event.ltcmp(other.event)

    def __bool__(self):
        return self.event is not None

    cdef push(self, Event item):
        self.event = item

    cdef Event pop(self):
        cdef Event ev = self.event
        self.event = None
        return ev

    cdef Event first(self):
        return self.event
