exec(open("./init.py").read())

from enum import IntEnum, auto
from pesim import Process, Environment, Condition, Semaphore
from collections import deque
from random import randint

class Reason(IntEnum):
    NewTask = auto()
    TaskDone = auto()


class Consumer(Process):
    def __init__(self, env):
        self.task_queue = deque()
        self.sem = Semaphore(0)
        super(Consumer, self).__init__(env)

    def _wait(self):
        return self.sem.acquire(self)

    def _process(self):
        task, cond = self.task_queue.popleft()
        print("[{}]C gets task: {}".format(self.time, task))
        yield self.time + randint(50, 100), Reason.TaskDone
        cond.set()
        print("[{}]C completes task: {}".format(self.time, task))


class Producer(Process):
    def __init__(self, env, idx, consumer, task_num):
        self.idx = idx
        self.consumer = consumer
        self.task_num = task_num
        super(Producer, self).__init__(env)

    def _process(self):
        for i in range(self.task_num):
            task = "{}_{}".format(self.idx, i)
            cond = Condition()
            self.consumer.task_queue.append((task, cond))
            self.consumer.sem.release()
            print("[{}]P{} puts task: {}".format(self.time, self.idx, task))
            yield cond.wait(self)


if __name__ == '__main__':
    with Environment(start=True) as env:
        c = Consumer(env)
        for idx in range(2):
            p = Producer(env, idx, c, 5)
            p.activate(0, Reason.NewTask)
