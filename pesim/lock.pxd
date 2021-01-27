from .process cimport Process
from cpython cimport PyObject


cdef class _SyncObj:
    cdef PyObject** wait_processes
    cdef int wait_max
    cdef int num_wait
    cdef readonly int value
    cdef readonly dict args

    cdef bint _async_acquire(self, Process proc, int change)
    cdef tuple _acquire(self, Process proc, int change)
    cdef void _release(self, int change, int acquire_change, int reason)

cdef class Semaphore(_SyncObj):
    pass

cdef class Lock(_SyncObj):
    pass

cdef class Condition(_SyncObj):
    pass

cdef class RLock:
    cdef PyObject* holder
    cdef object wait_objs
    cdef readonly int value
    cdef readonly dict args

    cdef bint _async_acquire(self, Process proc, object obj)
    cdef tuple _acquire(self, Process proc, object obj)


