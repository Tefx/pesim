exec(open("./init.py").read())

from pesim import Environment, Lock, TIME_PASSED
from random import uniform


def player(self, name: str, ball: Lock):
    yield ball.acquire(self)                        # catch the ball
    print(name, self.time)                          # ping!
    yield self.time + uniform(5, 10), TIME_PASSED   # let the ball fly
    ball.release()                                  # so others can catch


if __name__ == '__main__':
    ball = Lock()
    with Environment(stop_time=1000) as env:
        env.process(player, "ping", ball, loop_forever=True)
        env.process(player, "pong", ball, loop_forever=True)
