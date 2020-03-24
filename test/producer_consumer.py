from enum import IntEnum, auto

from pesim import make_process, Environment, TIME_FOREVER, TIME_PASSED
from collections import deque
from random import randint

task_queue = deque()

class Reason(IntEnum):
    NewTask = auto()
    TaskAssign = auto()
    TaskDone = auto()

@make_process
def consumer(env):
    while True:
        while task_queue:
            task = task_queue[0]
            print("[{}]Get task: {}".format(env.time, task))
            yield env.time + randint(5, 10), Reason.TaskDone
            print("[{}]Done task: {}".format(env.time, task))
            task_queue.popleft()
        yield TIME_FOREVER, TIME_PASSED

@make_process
def producer(env, consumer, num):
    for i in range(num):
        if not task_queue:
            consumer.activate(env.time, Reason.TaskAssign)
        print("[{}]Put task: {}".format(env.time, i))
        task_queue.append(i)
        yield env.time + randint(5, 10), Reason.NewTask
    yield TIME_FOREVER, TIME_PASSED


if __name__ == '__main__':
    from time import time

    num = 10

    env = Environment()

    c = consumer(env)
    p = producer(env, c, num)

    env.start()

    t = time()
    env.run_until(TIME_FOREVER-1, TIME_PASSED)
    print(num / (time() - t))
