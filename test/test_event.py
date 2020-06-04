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


wev = WaitEvent()


def proc_a(self):
    yield wev.wait(self)
    print("a", self.time, "received event")
    yield self.time + 10, TIME_PASSED
    yield wev.wait(self)
    print("a", self.time, "received event")
    print("a", self.time, "to set event")
    wev.set()


def proc_b(self):
    yield self.time + 15, TIME_PASSED
    print("b", self.time, "to set event")
    wev.set()
    yield self.time + 7, TIME_PASSED
    print("b", self.time, "received event")


if __name__ == '__main__':
    env = Environment()

    a = make_process(env, proc_a)
    b = make_process(env, proc_b)

    env.start()
    env.run_until(TIME_FOREVER - 1, TIME_PASSED)
