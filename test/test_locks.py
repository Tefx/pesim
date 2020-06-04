import sys, os

sys.path = [os.path.realpath("../build/lib.linux-x86_64-3.8")] + sys.path

from enum import IntEnum, auto

from pesim import TIME_REACHED, make_process, Environment, TIME_FOREVER, TIME_PASSED
from pesim.lock import Lock, Semaphore, WaitEvent
from collections import deque
from random import randint

task_queue = deque()


class Reason(IntEnum):
    NewTask = auto()
    TaskAssign = auto()
    TaskDone = auto()


lock = Lock()


def proc_a(self):
    yield self.time + 10, TIME_PASSED
    yield lock.acquire(self)
    print("a", self.time, "acquired")
    yield self.time + 10, TIME_PASSED
    print("a", self.time, "to release")
    lock.release()


def proc_b(self):
    yield lock.acquire(self)
    yield self.time + 15, TIME_PASSED
    print("b", self.time, "to release")
    lock.release()
    yield lock.acquire(self)
    print("b", self.time, "acquired")


if __name__ == '__main__':
    env = Environment()

    a = make_process(env, proc_a)
    b = make_process(env, proc_b)

    env.start()
    env.run_until(TIME_FOREVER - 1, TIME_PASSED)
