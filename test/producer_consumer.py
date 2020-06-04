from enum import IntEnum, auto

from pesim import make_process, Environment, TIME_FOREVER, TIME_PASSED
from collections import deque
from random import randint

task_queue = deque()

class Reason(IntEnum):
    NewTask = auto()
    TaskAssign = auto()
    TaskDone = auto()

def consumer(self):
    while True:
        while task_queue:
            task = task_queue[0]
            print("[{}]Get task: {}".format(self.time, task))
            yield self.time + randint(5, 10), Reason.TaskDone
            print("[{}]Done task: {}".format(self.time, task))
            task_queue.popleft()
        yield TIME_FOREVER, TIME_PASSED

def producer(self, consumer, num):
    for i in range(num):
        if not task_queue:
            consumer.activate(self.time, Reason.TaskAssign)
        print("[{}]Put task: {}".format(self.time, i))
        task_queue.append(i)
        yield self.time + randint(5, 10), Reason.NewTask


if __name__ == '__main__':
    from time import time

    num = 10

    env = Environment()

    c = make_process(env, consumer)
    p = make_process(env, producer, c, num)

    env.start()

    t = time()
    env.run_until(TIME_FOREVER-1, TIME_PASSED)
    print(num / (time() - t))
