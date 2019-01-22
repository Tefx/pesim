import sys;
from math import ceil

sys.path.extend(["../", "../../amcp/python"])

from pesim import Environment, TIME_FOREVER
from amcp import RemoteFunction as rf, DataType as dt, AMCPEngine

from random import randint, choice
from collections import deque


class Load:
    gid = 0

    def __init__(self):
        self.finished = 0
        self.time = randint(80, 120)
        self.worker = None
        self.id = self.__class__.gid
        self.__class__.gid += 1

    def assign_to(self, env, time, worker):
        worker.add(self)
        self.worker = worker
        env.activate(worker.proc, time, 10)

    def __repr__(self):
        return "[LOAD-{}/{}]".format(self.id, self.time)


class Worker:
    gid = 0

    def __init__(self):
        self.queue = deque()
        self.closed = False
        self.proc = None
        self.id = self.__class__.gid
        self.__class__.gid += 1

    def add(self, load):
        self.queue.append(load)

    def close(self):
        self.closed = True

    def __call__(self):
        time = 0
        while not self.closed:
            if len(self.queue) > 0:
                load = self.queue.popleft()
                print(time, "Start", load, "on", self.id)
                time = yield time + load.time, 0
                print(time, "Finish", load, "on", self.id)
                load.finished = True
            else:
                time = yield TIME_FOREVER, 100


class Dispatcher(AMCPEngine):
    def __init__(self, num_worker):
        super(Dispatcher, self).__init__()
        self.env = Environment()
        self.workers = []
        for i in range(num_worker):
            worker = Worker()
            worker.proc = self.env.add(worker())
            self.workers.append(worker)
        self.loads = {}
        self.env.start()

    @rf
    def create_load(self) -> dt.INT:
        load = Load()
        self.loads[load.id] = load
        return load.id

    @rf
    def process(self, time: dt.REAL, load_id: dt.INT) -> dt.REAL:
        time = ceil(time)
        load = self.loads[load_id]
        worker = choice(self.workers)
        load.assign_to(self.env, time, worker)
        return self.env.run_until(time, proc_next=worker.proc)

    @rf
    def check_done(self, time: dt.REAL, load_id: dt.INT) -> dt.REAL:
        time = ceil(time)
        load = self.loads[load_id]
        time = self.env.run_until(time, proc_next=load.worker.proc)
        if load.finished:
            del self.loads[load_id]
            return -1
        else:
            return time


if __name__ == '__main__':
    dispatcher = Dispatcher(10)
    print(dispatcher.gen_c(path=None))
    dispatcher.serve_forever("tcp://*:5555", silence=True)


