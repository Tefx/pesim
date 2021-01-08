from inspect import isgenerator

from .math_aux cimport l2d, d2l
from .define cimport _TIME_PASSED, _TIME_FOREVER
from .sim cimport Environment
from libc.stdint cimport int64_t
from cpython cimport PyObject


cdef class Process:
    """Process(env)
    Base class of all process.
    A process can be implemented by using :meth:`Environment.process`,
    or by directly inheriting this class.
    There are two ways to define a process by inheriting this class:

        #. overriding :meth:`__call__`
        #. overriding :meth:`_wait` and :meth:`_process`

    If :meth:`__call__` is overridden, any implementation of :meth:`_wait` and :meth:`_process`
    will be ignored. The content of :meth:`__call__` will be executed as the process logic. Note that
    :meth:`__call__` will be executed only once. So, if the process need to do something
    repeatedly, do not forget to wrap the code in a infinite loop.

    :meth:`_wait` amd :meth:`_process` are for convenience of create repeat tasks.
    :meth:`_wait` is supposed to return the process's next activation time and reason,
    and :meth:`_process` will do some actual work. This wait -> process pattern will be repeated infinitely.
    One can consider the default implementation of :meth:`__call__` as (not exactly, simplified)::

            while True:
                yield self._wait()
                p = self._process()
                if isgenerator(p):
                    yield from p

    :meth:`_process` can either be a generator or not, depends on whether the process need to wait
    when processing the task.

    Examples:

        Here is an example process defined in four ways

            #. Passing generator to :meth:`env.process()`::

                def tick(self):
                    while True:
                        yield self.time + 5, TIME_REACHED
                        print("tick", self.time)
                        yield self.time + 10, TIME_PASSED
                        print("tack", self.time)

                with Environment() as env:
                    p = env.process(tick)

            #. Passing generator to :meth:`env.process()` with `loop_forever=True`::

                def tick(self):
                    yield self.time + 5, TIME_REACHED
                    print("tick", self.time)
                    yield self.time + 10, TIME_PASSED
                    print("tack", self.time)

                with Environment() as env:
                    p = env.process(tick, loop_forever=True)

            #. Inheriting :class:`Process` and overriding :meth:`__call__`::

                class Tick(Process):
                    def __call__(self):
                        while True:
                            yield self.time + 5, TIME_REACHED
                            print("tick", self.time)
                            yield self.time + 10, TIME_PASSED
                            print("tack", self.time)

                with Environment() as env:
                    p = Tick(env)

            #. Inheriting :class:`Process` and overriding :meth:`_wait` and :meth:`_process`::

                class Tick(Process):
                    def _wait(self):
                        return self.time + 5, TIME_REACHED

                    def _process(self):
                        print("tick", self.time)
                        yield self.time + 10, TIME_PASSED
                        print("tack", self.time)

                with Environment() as env:
                    p = Tick(env)

    Args:
        env(:obj:`Environment`): The environment the process belongs to. \
        After creation, the process will be added to the environment automatically.

    Attributes:
        time(float): Current time in the simulation environment. This is just a alias of the corresponding \
        environment's `time` attribute. In other words, all the processes in the same environment shares the some time.

    """
    def __init__(self, Environment env):
        self.process = None
        self.ev_heap = None
        self.event = None
        self.setup_env(env)
        self._is_waiting = NotImplemented

        if env.started:
            self.start()

    cpdef void setup_env(self, env):
        self.env = env
        self.ev_heap = self.env.ev_heap
        self.env.add(self)

    cpdef tuple _wait(self):
        """_wait()
        Override this method to *return* next activation time and reason. 
        Note that this method is not a generator.
        
        :meta public: 
        
        Returns:
            time (`float`) and reason (`int`)

        """
        return _TIME_FOREVER, _TIME_PASSED

    cpdef _process(self):
        """_process()
        Override this method to perform one task.
        This method can be either implemented as a generator with `yield` statements, 
        or a normal method with optional `return` statement. If there is `yield` statements, 
        the process will be accordingly paused and reactivated to perform simulation logic.
           
        :meta public: 
        
        Yields:
            time (`float`) and reason (`int`)
            
        Returns:
            returns will be ignored.

        """
        raise NotImplementedError

    cpdef void activate(self, double time, int reason):
        """activate(double time, int reason)
        Activate a process at the `time` with a `reason`.
        
        Args:
            time(float): Activation time. The time must be equal or greater than current simulation time. \
            If a time earlier than current simulation is passed, the process will be activated immediately.
            reason(reason): The activation reason.
        """
        cdef Event ev
        cdef int64_t time_i64 = max(self.env.time_i64, d2l(time))
        if time_i64 < self.event.time_i64:
            self.event.time_i64 = time_i64
            self.event.reason = reason
            self.ev_heap.notify_dec_x(<PyObject*>(self.event))

    def __call__(self):
        """__call__()
        Override this for the main logic of the process.

        :meta public:

        Yields:
            time(float): next activation time
            reason(int): next activation reason
        """
        while True:
            self._is_waiting = True
            yield self._wait()
            self._is_waiting = False
            p = self._process()
            if isgenerator(p):
                yield from p

    cpdef void start(self):
        cdef double time
        cdef int reason

        self.process = self()
        time, reason = self.process.send(None)
        self.event = Event(max(self.env.time_i64, d2l(time)), self, reason)
        # self.event.time_i64 = max(self.env.time_i64, d2l(time))
        # self.event.reason = reason
        self.ev_heap.push_x(<PyObject*>(self.event))

    cdef void run_step(self) except *:
        cdef double time
        cdef int reason

        time, reason = self.process.send(self.event.reason)
        self.event.time_i64 = max(self.env.time_i64, d2l(time))
        self.event.reason = reason
        self.ev_heap.push_x(<PyObject*>(self.event))

    cpdef void finish(self):
        pass

    def next_event_time(self):
        return l2d(self.event.time_i64)

    def next_activation_time(self):
        """next_activation_time():
        The process's following activation time. This method can only be called when the process is paused.

        Returns:
            Time as a `float`
        """
        return l2d(self.event.time_i64)

    @property
    def time(self):
        return self.env.time