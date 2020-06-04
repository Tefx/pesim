from .process cimport Process
from cpython cimport PyObject


cdef class _SyncObj:
    cdef PyObject** wait_processes
    cdef int wait_max
    cdef int num_wait
    cdef int value

    cdef bint _async_acquire(self, Process proc, int change)
    cdef tuple _acquire(self, Process proc, int change)
    cdef void _release(self, int change)
    cdef void _on_acquired(self, int change)
    cdef void _on_released(self, int change)

cdef class Semaphore(_SyncObj):
    pass

cdef class Lock(_SyncObj):
    pass

cdef class RLock(_SyncObj):
    cdef PyObject* holder
    cdef PyObject* _tmp_holder
    cdef void _on_acquired(self, int change)
    cdef void _on_released(self, int change)

cdef class Condition(_SyncObj):
    pass

