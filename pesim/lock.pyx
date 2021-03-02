"""This module defines for synchronisation primitives: :obj:`Lock`, :obj:`Semaphore`, :obj:`RLock` and :obj:`Condition`.

:obj:`Lock`, :obj:`Semaphore` and :obj:`RLock` all have methods of :meth:`acquire()` and :meth:`release()`.
:meth:`acquire()` waits on the primitive object until it becomes unlocked, and then turns its state to lock.
Meanwhile :meth:`release()` is used to unlocked a previously locked primitive object.
The calling of :meth:`acquire()` can be blocking or non-blocking.
If it's non-blocking and the object is currently locked, the calling will return immediately with a return value of False.
If it's blocking (default), it can be used in the `yield` statement inside process logics.
The process will be reactivated once the object's state turns to unlocked again::

    def consumer(self, task_queue, sem:Semaphore):
        while True:
            yield sem.acquire(self)
            #retrieve a task from task_queue and process the task

    def producer(self, task_queue, sem:Semaphore):
        while True:
            yield self.time + 5, TIME_REACHED
            #push a new task into task_queue
            sem.release()

:obj:`Condition` does not have methods :meth:`acquire()` and :meth:`release()`.
Instead, it has two method :meth:`set` and :meth:`wait`, \
where :meth:`set` sets the condition and :meth:`wait` waits until the condition is set.
"""

from .define cimport _TIME_FOREVER, _TIME_PASSED, _LOCK_RELEASED, _TIME_REACHED
from cpython.mem cimport PyMem_Malloc, PyMem_Free, PyMem_Realloc
from collections import OrderedDict

cdef class _SyncObj:
    _ALLOC_STEP = 16

    def __init__(self, int value, int wait_max=16, **kwargs):
        self.wait_max = wait_max
        self.num_wait = 0
        self.wait_processes = <PyObject**> PyMem_Malloc(sizeof(PyObject*) * self.wait_max)
        self.value = value
        self.args = kwargs

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

    cdef void _release(self, int change, int acquire_change, int reason):
        self.value += change
        while self.num_wait and self.value > 0:
            self.value -= acquire_change
            self.num_wait -= 1
            (<Process> self.wait_processes[self.num_wait]).activate(-1, reason)

cdef class Lock(_SyncObj):
    """Lock()
    The class implementing primitive lock objects.
    Once a process has acquired a lock, subsequent attempts to acquire it will block, until it is released.
    """
    def __init__(self, **kwargs):
        super(Lock, self).__init__(1, **kwargs)

    def acquire(self, Process proc, bint sync=True):
        """acquire(proc, sync=True)
        Acquire the lock

        Args:
            proc(Process): the process to acquire the lock. \
            So that the lock can know, when it is released, which process shall be waked. \
            In most of the cases, this argument is :obj:`self`.
            sync(bool): `True` for a blocking call, and `False` for a non-blocking call.

        Returns:
            If `sync=False`, returns `True` or `False` to indicate if the acquiring is succeed. \
            If `sync=True`, returns a 2-tuple (time, reason) which can be used in a `yield` statement.
        """
        if sync:
            return self._acquire(proc, 1)
        else:
            return self._async_acquire(proc, 1)

    def release(self, reason=_LOCK_RELEASED):
        """release(reason=LOCK_RELEASED)
        Release the lock.

        Args:
            reason(int): If there is a process currently waiting for acquiring the object,
                the process will be activated with the given reason.
                If there are more than one processes waiting, only one of them will be activated.
        """
        self._release(1, 1, reason)

cdef class Semaphore(_SyncObj):
    """Semaphore(value)
    A Semaphore object has a internal counter.
    The value of the counter can never go below zero.
    If the counter value is zero, the :meth:`acquire()` will block until the value goes greater than 0.
    A successful :meth:`acquire()` decreases internal counter by 1, and :meth:`release()` increases the counter by 1.

    Args:
        value(int): The initial value of the internal counter.

    Attributes:
        value(int): Current value of the internal counter.

    """
    def __init__(self, value, **kwargs):
        super(Semaphore, self).__init__(value, **kwargs)

    def acquire(self, Process proc, bint sync=True):
        """acquire(self, proc, sync=True)

        Args:
            proc(Process): The process to acquire the semaphore.
            sync(bool): Blocking or non-blocking.

        Returns:
            `True` or `False` when `sync=False`, otherwise a 2-tuple (time, reason) to be used with `yield`.

        See :meth:`Lock.acquire()` for more information.
        """
        if sync:
            return self._acquire(proc, 1)
        else:
            return self._async_acquire(proc, 1)

    def release(self, reason=_LOCK_RELEASED):
        """release(reason=LOCK_RELEASED)
        Release the semaphore and increase the internal counter by 1.

        Args:
            reason(int): If there is a process currently waiting for acquiring the object,
                the process will be activated with the given reason.
                If there are more than one processes waiting, only one of them will be activated.
        """
        self._release(1, 1, reason)

cdef class RLock:
    """ RLock()
    A reentrant lock is a synchronization primitive that may be acquired multiple times,
    if these acquiring are all associated to a same object.
    This is useful when several processes want to cooperate on some task using some shared resources,
    while still want to blocking some other process to access the resources.

    One example use case: two equipment needs to go to a same area to cooperatively finish one task.
    When the task is conducting, no other equipment can enter this area.
    We can create a `RLock()` to represent the area, and let the equipment acquire the lock with the task.
    In this way, once one equipment has successfully acquired the lock,
    the equipment working on the same task (so it will acquire with the same task) can acquire this lock again.
    But other equipment's acquiring (using other tasks) will fail.

    There is an additional argument `obj` in :meth:`RLock.acquire()`, which indicates the associated resources.
    """
    def __init__(self, **kwargs):
        self.holder = NULL
        self.wait_objs = OrderedDict()
        self.value = 1
        self.args = kwargs

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
        """acquire(self, proc, sync=True, obj=None)

        If the `self` is unlocked, the acquiring will associate the `obj` to the `self` object and lock it.
        The subsequent attempts will be successful only if they are acquiring with the same `obj`.

        Args:
            proc(Process): The process to acquire the lock.
            sync(bool): Blocking or non-blocking.
            obj(object): A object associated to this acquiring.

        Returns:
            `True` or `False` when `sync=False`, otherwise a 2-tuple (time, reason) to be used with `yield`.
        """
        if obj is None:
            obj = proc
        if sync:
            return self._acquire(proc, obj)
        else:
            return self._async_acquire(proc, obj)

    def release(self, reason=_LOCK_RELEASED):
        """release(reason=LOCK_RELEASED)
        Release the lock and unlink the object associated.

        Args:
            reason(int): If there is a process currently waiting for acquiring the lock,
                the process will be activated with the given reason and the new obj will be associated.
                If there are more than one processes are waiting with different objects, only one objects
                will be chosen, and all the processes acquiring with this object will be activated.
        """
        cdef Process proc
        self.value += 1
        if self.value > 0:
            self.holder = NULL
            if self.wait_objs:
                obj, procs = self.wait_objs.popitem(False)
                self.holder = <PyObject*> obj
                self.value -= 1
                for proc in procs:
                    proc.activate(-1, reason)

cdef class Condition(_SyncObj):
    """Condition()
    This class implements condition objects.
    A condition variable allows one or more process to wait until they are notified by another process.

    Examples:
        In the following example, a `producer` generates a new task only after the previously has been processed::

            def consumer(self, task_queue, task_sem, complete_cond):
                while True:
                    yield task_sem.acquire(self)
                    #get a task from task_queue and process
                    complete_cond.set()

            def producer(self, task_queue, task_sem, complete_cond):
                while True:
                    #add a task to task_queue
                    task_sem.release()
                    yield complete_cond.wait(self)

    Attributes:
        value(int): 0 if the condition is not set, 1 if the condition is set.
    """
    def __init__(self, max_waits=16, **kwargs):
        super(Condition, self).__init__(0, max_waits, **kwargs)

    def wait(self, Process proc, bint sync=True):
        """wait(proc, sync=True)
        Wait on a condition.

        Args:
            proc(Process): The waiting process.
            sync(bool): Blocking or non-blocking.

        Returns:
            `True` or `False` when `sync=False`, otherwise a 2-tuple (time, reason) to be used with `yield`.
        """
        if sync:
            return self._acquire(proc, 0)
        else:
            return self._async_acquire(proc, 0)

    def set(self, reason=_LOCK_RELEASED):
        """set(reason=LOCK_RELEASED)
        Set the condition.

        Args:
            reason: Activation reason. When the condition is set, all the processes waiting on the condition
                will be activated with the given reason.
        """
        if self.value == 0:
            self._release(1, 0, reason)

    def clear(self):
        """clear()
        Unset a condition variable.
        """
        self.value = 0

    def is_set(self):
        """is_set()
        Whether the condition has been set.

        Returns:
            `True` or `False`
        """
        return self.value > 0

    def __enter__(self):
        self.set()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.clear()

__all__ = ["Lock", "Semaphore", "RLock", "Condition"]