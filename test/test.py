from pesim import Environment, TIME_FOREVER

from random import randint, choice
from collections import deque


class Load:
    gid = 0

    def __init__(self):
        self.finished = 0
        self.time = randint(80, 120)
        self.id = self.__class__.gid
        self.__class__.gid += 1

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
                print(time, "Start", load)
                time = yield time + load.time, 0
                print(time, "Finish", load)
                load.finished = True
            else:
                time = yield TIME_FOREVER, 100


def dispatch(env, workers):
    env.start()

    time = 0
    for i in range(100):
        load = Load()
        print(time, "Create", load)
        worker = choice(workers)
        worker.add(load)
        env.activate(worker.proc, time, 10)
        time = env.run_until(time, proc_next=worker.proc)
        while not load.finished:
            time = env.run_until(time, proc_next=worker.proc)
        time = env.current_time + randint(0, 10)
    for worker in workers:
        worker.close()


class Dispatcher:
    def __init__(self, env, workers):
        self.env = env
        self.workers = workers

    def process(self, time, load):
        worker = choice(self.workers)
        worker.add(load)
        self.env.activate(worker.proc, time, 10)
        return self.env.run_until(time, proc_next=worker.proc)

    def check_done(self, time, load):
        time = self.env.run_until(time, proc_next=worker.proc)
        if load.finished:
            return 0
        else:
            return time


if __name__ == '__main__':
    env = Environment()
    workers = []
    for i in range(1):
        worker = Worker()
        worker.proc = env.add(worker())
        workers.append(worker)
    dispatch(env, workers)
