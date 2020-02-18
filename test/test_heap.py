from math import inf
from random import randint

from pesim.pairing_heap import MinPairingHeap, MinPairingHeapNode

class Node(MinPairingHeapNode):
    def __init__(self, key):
        self.key = key

    def cmp(self, other):
        return self.key < other.key

if __name__ == '__main__':

    M = 1000000
    heap = MinPairingHeap()

    xs = []
    for i in range(1000000):
        n = Node(randint(0, M))
        heap.push(n)
        xs.append(n)

    # for i in [71, 55, 62, 56, 41]:
    #     heap.push(MinPairingHeapNode(i))

    # heap.root.print_tree()

    for x in xs:
        x.key -= randint(0, M)
        heap.notify_dec(x)
        # heap.dec_key(x, x.key - randint(0, M))

    i = 0
    last_k = -inf
    while heap:
        i += 1
        k = heap.pop()
        assert k.key >= last_k
        last_k = k.key
        # print("[_pop]", heap._pop().key)
        # if heap:
        #     heap.root.print_tree()
        # else:
        #     print("None")
    print("Count:", i)
