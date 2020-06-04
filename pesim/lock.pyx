from .define cimport _TIME_FOREVER, _TIME_PASSED, _LOCK_RELEASED, _TIME_REACHED
from cpython.mem cimport PyMem_Malloc, PyMem_Free, PyMem_Realloc

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
            self._on_acquired(change)
            return True
        else:
            return False

    cdef tuple _acquire(self, Process proc, int change):
        if self.value > 0:
            self._on_acquired(change)
            return -1, _TIME_REACHED
        else:
            if self.num_wait == self.wait_max:
                self.wait_max += self._ALLOC_STEP
                self.wait_processes = <PyObject**> PyMem_Realloc(self.wait_processes, sizeof(PyObject*) * self.wait_max)
            self.wait_processes[self.num_wait] = <PyObject*> proc
            self.num_wait += 1
            return _TIME_FOREVER, _TIME_PASSED

    cdef void _release(self, int change):
        cdef Process proc
        while self.num_wait and change:
            self.num_wait -= 1
            change -= 1
            (<Process> self.wait_processes[self.num_wait]).activate(-1, _LOCK_RELEASED)
        self._on_released(change)

    cdef void _on_acquired(self, int change):
        self.value -= change

    cdef void _on_released(self, int change):
        self.value += change

cdef class Lock(_SyncObj):
    def __init__(self):
        super(Lock, self).__init__(1)

    def acquire(self, Process proc, bint sync=True):
        if sync:
            return self._acquire(proc, 1)
        else:
            return self._async_acquire(proc, 1)

    def release(self):
        self._release(1)

cdef class RLock(_SyncObj):
    def __init__(self):
        super(RLock, self).__init__(1)
        self.holder = NULL
        self._tmp_holder = NULL

    cdef void _on_acquired(self, int change):
        self.value -= change
        self.holder = self._tmp_holder

    cdef void _on_released(self, int change):
        self.value += change
        self.holder = NULL

    def acquire(self, Process proc, bint sync=True, object obj=None):
        if obj is None:
            self._tmp_holder = <PyObject*> proc
        else:
            self._tmp_holder = <PyObject*> obj
        if sync:
            return self._acquire(proc, 1)
        else:
            return self._async_acquire(proc, 1)

    def release(self):
        self._release(1)

cdef class Semaphore(_SyncObj):
    def __init__(self, value):
        super(Semaphore, self).__init__(value)

    def acquire(self, Process proc, bint sync=True):
        if sync:
            return self._acquire(proc, 1)
        else:
            return self._async_acquire(proc, 1)

    def release(self):
        self._release(1)

cdef class Condition(_SyncObj):
    def __init__(self, max_waits=16):
        super(WaitEvent, self).__init__(0, max_waits)

    def wait(self, Process proc, bint sync=True):
        if sync:
            return self._acquire(proc, 0)
        else:
            return self._async_acquire(proc, 0)

    def set(self):
        self._release(self.num_wait + 1)

    def clear(self):
        self.value = 0
