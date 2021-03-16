from .math_aux cimport d2l, l2d
from .define cimport _TIME_FOREVER, _TIME_PASSED
from .event cimport Event
from libc.stdint cimport int64_t


cdef class Environment:
    """Environment(start=False, stop_time=TIME_FOREVER)
    The simulation environment::

        e = Environment(start=True)
        #add some processes
        e.run_until(3600, TIME_PASSED)
        #add some other process or do sth else
        e.join() #or e.run_until(TIME_FOREVER, TIME_PASSED)
        e.finish()

    Instead of using :meth:`start` and :meth:`finish` explicitly, the :obj:`Environment` can also be used with context::

        with Environment() as e:
            #add some processes
            e.run_until(3600, TIME_PASSED)
            #add some other processes or do sth else

    In this case, the environment will be automatically started (when entering the context), \
    joined and finished (when exiting the context).

    Args:
        start(bool): Start the simulation immediately. Optional, default is `False`. If it is `False`, the environment \
        needs to be started by `start()` explicitly.
        stop_time(double): Maximum time of simulation run. Used in :meth:`join`. Default is TIME_FOREVER.

    Attributes:
        time(float): Current time in the simulation environment.
        started(bool): Whether the simulation is started.
        stop_time(double): Maximum time of simulation run.
    """

    def __init__(self, start=False, double stop_time=_TIME_FOREVER):
        self.ev_heap = MinPairingHeap()
        self.time_i64 = 0
        self.processes = []
        self.started = False
        self.stop_time = stop_time
        if start:
            self.start()

    cpdef void add(self, Process process):
        self.processes.append(process)

    cdef inline void timeout(self, Event ev, double time, int reason):
        ev.time_i64 = max(self.time_i64, d2l(time))
        ev.reason = reason
        self.ev_heap.push(ev)

    cpdef void start(self) except *:
        """start()
        Start the simulation.
        """
        cdef double time
        cdef int priority
        cdef Process process

        for process in self.processes:
            process.start()

        self.started = True

    cpdef void finish(self):
        """finish()
        Finish the simulation.
        """
        cdef Process process
        for process in self.processes:
            process.finish()

    cpdef double run_until(self, double ex_time, int after_reason=_TIME_PASSED):
        """run_until(ex_time, after_reason=TIME_PASSED)
        Run the simulation until a specific time.
        
        Args:
            ex_time(double):  A time.
            after_reason(int): A reason. If a event has a triggering time of `ex_time` and a reason \
            that is greater than `after_reason`, it will not be processed and the simulation will \
            stop before it.

        Returns:
            Current time (`float`) in the simulation after the running.

        """
        cdef Event ev
        cdef int64_t ex_time_i64 = d2l(ex_time)

        ev = self.ev_heap.first()
        while ev.time_i64 < ex_time_i64 or \
                (ev.time_i64 == ex_time_i64 and ev.reason <= after_reason):
            ev = self.ev_heap.pop()
            if self.time_i64 < ev.time_i64:
                self.time_i64 = ev.time_i64
            ev.process.run_step()
            ev = self.ev_heap.first()

        if self.time_i64 < ex_time_i64:
            self.time_i64 = ex_time_i64

        return l2d(self.time_i64)

    cpdef double join(self):
        """join()
        Process all the remaining events. In other words, this call runs the simulation until `self.stop_time`.
        """
        if self.stop_time != _TIME_FOREVER:
            self.run_until(self.stop_time, _TIME_PASSED)
        else:
            self.run_until(_TIME_FOREVER-1, _TIME_PASSED)

    def __enter__(self):
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.join()
        self.finish()

    @property
    def time(self):
        return l2d(self.time_i64)

    cpdef double next_event_time(self):
        """next_event_time()
        Time of the next event in the simulation environment.
        
        Returns: 
            Time as a `float` number.
        """
        cdef Event ev = self.ev_heap.first()
        if ev is not None:
            return l2d(ev.time_i64)
        else:
            return _TIME_FOREVER

    cpdef Event next_event(self):
        return self.ev_heap.first()

    def process(self, func, *args, loop_forever=False, **kwargs):
        """process(func, *args, loop_forever=False, **kwargs)
        Turn a generator function to a Process. The resulting process will be added to the environment automatically.

        The following code turns the `tick` function into a process, which will print the time every 5 seconds::

            env = Environment()

            def tick(self, interval):
                yield self.time + interval, TIME_PASSED
                print("tick!", self.time)

            p0 = env.process(tick, 5, loop_forever=True)

        Args:
            func: A generator function contains at least one `yield` statement.
            *args: Positional arguments to be passed to `func`.
            loop_forever: Whether to loop the execution of `func`.
            **kwargs: Optional arguments to be passed to `func`.

        Returns:
            The resulting process (:obj:`Process`).

        """
        class _Process(Process):
            def __call__(self):
                if loop_forever:
                    while True:
                        yield from func(self, *args, **kwargs)
                else:
                    yield from func(self, *args, **kwargs)
                yield _TIME_FOREVER, _TIME_PASSED
        return _Process(self)
