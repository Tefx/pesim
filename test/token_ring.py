exec(open("./init.py").read())

from pesim import Environment, TIME_REACHED
from random import randint


def token(self, players):
    for _ in range(10):
        for p in players:
            yield self.time + randint(5, 10), TIME_REACHED
            p.activate(-1, 0)


def player(self, name):
    yield
    print("[{}] {} gets the token".format(self.time, name))


if __name__ == '__main__':
    with Environment() as env:
        players = [env.process(player, idx, loop_forever=True)
                   for idx in range(5)]
        _ = env.process(token, players)
