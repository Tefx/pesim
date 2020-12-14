exec(open("./init.py").read())

from enum import IntEnum, auto
from pesim import Process, Environment
from collections import deque
from random import randint

task_queue = deque()


class Reason(IntEnum):
    NewTask = auto()
    TaskDone = auto()


class Consumer(Process):
    def _wait(self):
        if task_queue:
            return self.time, Reason.NewTask
        else:
            return super(Consumer, self)._wait()

    def _process(self):
        task = task_queue.popleft()
        print("[{}]C gets task: {}".format(self.time, task))
        yield self.time + randint(50, 100), Reason.TaskDone
        print("[{}]C completes task: {}".format(self.time, task))


class Producer(Process):
    def __init__(self, env, idx, consumer, task_num):
        self.idx = idx
        self.consumer = consumer
        self.task_num = task_num
        super(Producer, self).__init__(env)

    def __call__(self):
        for i in range(self.task_num):
            task = "{}_{}".format(self.idx, i)
            task_queue.append(task)
            print("[{}]P{} puts task: {}".format(self.time, self.idx, task))
            if self.consumer._is_waiting:
                self.consumer.activate(self.time, Reason.NewTask)
            yield self.time + randint(50, 100), Reason.NewTask


if __name__ == '__main__':
    with Environment(start=True) as env:
        c = Consumer(env)
        for idx in range(2):
            p = Producer(env, idx, c, 5)
            p.activate(0, Reason.NewTask)
