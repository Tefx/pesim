exec(open("./init.py").read())
from enum import IntEnum, auto
from pesim import make_process, Environment, TIME_FOREVER, TIME_PASSED
from collections import deque
from random import randint

task_queue = deque()


class Reason(IntEnum):
    NewTask = auto()
    TaskDone = auto()


def consumer(self):
    while True:
        if task_queue:
            task = task_queue.popleft()
            print("[{}]C gets task: {}".format(self.time, task))
            yield self.time + randint(50, 100), Reason.TaskDone
            print("[{}]C completes task: {}".format(self.time, task))
        else:
            yield TIME_FOREVER, TIME_PASSED


def producer(self, idx, consumer, num):
    for i in range(num):
        task = "{}_{}".format(idx, i)
        task_queue.append(task)
        print("[{}]P{} puts task: {}".format(self.time, idx, task))
        if consumer.next_event_time == TIME_FOREVER:
            consumer.activate(self.time, Reason.NewTask)
        yield self.time + randint(50, 100), Reason.NewTask


if __name__ == '__main__':
    with Environment(start=True) as env:
        c = env.process(consumer)
        for idx in range(2):
            env.process(producer, idx, c, 5)
