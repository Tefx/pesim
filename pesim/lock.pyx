from .define cimport _TIME_FOREVER, _TIME_PASSED, _LOCK_RELEASED, _TIME_REACHED
from cpython.mem cimport PyMem_Malloc, PyMem_Free, PyMem_Realloc
from collections import OrderedDict

cdef class _SyncObj:
    _ALLOC_STEP = 16

    def __init__(self, int value, int wait_max=16):
        self.wait_max = wait_max
        self.num_wait = 0
        self.wait_processes = <PyObject**> PyMem_Malloc(sizeof(PyObject*) * self.wait_max)
        self.value = value

    def __dealloc__(self):
        PyMem_Free(self.wait_processes)

    cdef bint _async_acquire(self, Process proc, int change):
        if self.value > 0:
            self.value -= change
            return True
        else:
            return False

    cdef tuple _acquire(self, Process proc, int change):
        if self.value > 0:
            self.value -= change
            return -1, _TIME_REACHED
        else:
            if self.num_wait == self.wait_max:
                self.wait_max += self._ALLOC_STEP
                self.wait_processes = <PyObject**> PyMem_Realloc(self.wait_processes, sizeof(PyObject*) * self.wait_max)
            self.wait_processes[self.num_wait] = <PyObject*> proc
            self.num_wait += 1
            return _TIME_FOREVER, _TIME_PASSED

    cdef void _release(self, int change, int acquire_change):
        self.value += change
        while self.num_wait and self.value > 0:
            self.value -= acquire_change
            self.num_wait -= 1
            (<Process> self.wait_processes[self.num_wait]).activate(-1, _LOCK_RELEASED)

cdef class Lock(_SyncObj):
    def __init__(self):
        super(Lock, self).__init__(1)

    def acquire(self, Process proc, bint sync=True):
        if sync:
            return self._acquire(proc, 1)
        else:
            return self._async_acquire(proc, 1)

    def release(self):
        self._release(1, 1)

cdef class Semaphore(_SyncObj):
    def __init__(self, value):
        super(Semaphore, self).__init__(value)

    def acquire(self, Process proc, bint sync=True):
        if sync:
            return self._acquire(proc, 1)
        else:
            return self._async_acquire(proc, 1)

    def release(self):
        self._release(1, 1)

cdef class Condition(_SyncObj):
    def __init__(self, max_waits=16):
        super(Condition, self).__init__(0, max_waits)

    def wait(self, Process proc, bint sync=True):
        if sync:
            return self._acquire(proc, 0)
        else:
            return self._async_acquire(proc, 0)

    def set(self):
        self._release(self.num_wait + 1, 0)

    def clear(self):
        self.value = 0

    def __enter__(self):
        self.set()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.clear()

cdef class RLock:
    def __init__(self):
        self.holder = NULL
        self.wait_objs = OrderedDict()
        self.value = 1

    cdef bint _async_acquire(self, Process proc, object obj):
        if self.holder == NULL:
            self.holder = <PyObject*> obj
            self.value -= 1
            return True
        elif self.holder == <PyObject*> obj:
            self.value -= 1
            return True
        else:
            return False

    cdef tuple _acquire(self, Process proc, object obj):
        if self.holder == NULL:
            self.holder = <PyObject*> obj
            self.value -= 1
            return -1, _TIME_REACHED
        elif self.holder == <PyObject*> obj:
            self.value -= 1
            return -1, _TIME_REACHED
        else:
            if obj not in self.wait_objs:
                self.wait_objs[obj] = set()
            self.wait_objs[obj].add(proc)
            return _TIME_FOREVER, _TIME_PASSED

    def acquire(self, Process proc, bint sync=True, object obj=None):
        if obj is None:
            obj = proc
        if sync:
            return self._acquire(proc, obj)
        else:
            return self._async_acquire(proc, obj)

    def release(self):
        cdef Process proc
        self.value += 1
        if self.value > 0:
            self.holder = NULL
            if self.wait_objs:
                obj, procs = self.wait_objs.popitem(False)
                self.holder = <PyObject*> obj
                self.value -= 1
                for proc in procs:
                    proc.activate(-1, _LOCK_RELEASED)
