# pesim: A Minimalist Discrete Event Simulation Library in Python 

## About

I write this as the underlying simulation engine of my container yard simulator, with the goals of:

1. Simple interfaces.
2. Cython-ised for speed
3. DO ONE THING WELL

So what is the one thing for a discrete event simulation? Making the events happen on right time and in right order. This is the only thing `pesim` do. 

(I am definitely inspired by [SimPy](https://simpy.readthedocs.io/en/latest/), and I like the way it uses generator and `yield` statement to represent activities. However, for my projects, SimPy is too heavy and too slow. )

## Install

```python
pip install pesim
```

[Cython](https://pypi.org/project/Cython/) is needed if there is not a corresponding pre-built `wheel` for the targeting platform.

## Documentation
See [Documentation](https://pesim.readthedocs.io/en/latest/).

## Tutorial

### A Minimal Example

```python
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
```

### A Producer-consumer Example

Let's simulate the classical producer-consumer scenario. Suppose there are two producers and one consumer. Each producer repeatedly produces **tasks** for every 50-100s, while the consumer also takes 50-100s to process one **task**. Let's define the `t_j`-th **task** produced by the `p_i`-th producer as `(p_i, t_j)`(both count from 0, for example `(0,0)` is the first task produced by the first produce). 

`pesim` is a **process-based discrete event simulation engine**. The basic active components are modelled as **processes** (From now on, we use **process** to represent the process in simulation, and *OS process* to represent the processes in operation system).  There are two ways to define a **process**: 

1. Transforming a generator function into a **process**; or
2. Inheriting the `Process` base class.

I will show the two ways, respectively. Before starting, let's first import some auxiliary functions and classes.

```python
from collections import deque
from random import randint
```

We will use a `deque()` list as the task queue, and use `randint` to randomise task intervals and processing time.

### Defining Processes

The first way to define a process is using a generator function.

#### Consumer

The consumer process can be defined as such:

```python
from pesim import TIME_FOREVER, TIME_PASSED

class Reason(IntEnum):
    TaskDone = auto()
    NewTask = auto()
    
def consumer(self, task_queue):
    while True:
        while task_queue:
            task = task_queue.popleft()
            print("[{}]Consumer gets task: {}".format(self.time, task))

            yield self.time + randint(50, 100), Reason.TaskDone
            print("[{}]Consumer completes task: {}".format(self.time, task))

        reason = yield TIME_FOREVER, TIME_PASSED
        print("[{}]Consumer activated by reason {}".format(cur_time, reason))
```

The function takes two arguments. The first one is `self`, which is compulsive and represents the simulation **process** (object of class `Process`). The most important attribute of the `self` is `self.time` (of type `float`), which is the current simulated time. All the **processes** in one simulation **Environment** (we will create the environment later) share the same time, while we can access it from any **process**'s `time` value.

From second arguments, there are data that can be passed to the process by users. Here we pass in a **task queue** created by `deque()`. To remain simple, `pesim` itself does not provide any additional data structure to represent shared resources among different **processes**. All the **processes** will be executed in a single thread of a single *OS process*, so it will be safe to just use any suitable Python object to share information.

One can easily find that the function is actually a **generator** function, which periodically `yield`s a 2-tuple. These `yield` statements are the core to represent activities. So, when the **process** need to do something for a time period, it need to `yield` the execution, and when the predefined amount of time is passed, the execution will be resumed. The first item in the tuple is a time, which is the **process**'s supposed *next activation time* as a `float`, and the second item is a *reason* as an `int`. If the activity is completed as expected, the **process** will be "activated" again at the *next activation time*, and the reason is returned by the `yield` statement. 

The activity may also be interrupted externally with another reason. In this case, the **process** will be activated at an earlier time point, and the statement's returned value will tell the reason. Another usage of the *reason* is to order the events. That is, when multiple **processes** are supposed to be activated at the same time, the one yields the **least**  *reason* will be awaken first. Here we define two reasons:

```python
class Reason(IntEnum):
    TaskDone = auto()
    NewTask = auto()
```

Note that, this *reason* needn't to be exactly of `int` type, any type that can be casted to `int` can be used. As you can see, here we use the `IntEnum` to assign values to the reasons automatically.

Knowing this, the line 

```python
yield self.time + randint(50, 100), Reason.TaskDone 
```

is clear. It randomises a task processing time between 50s and 100s, and pauses the **process** until the task is completed. If everything is normal, when re-activated, the reason `Reason.TaskDone` will be returned.

There is another `yield` statement in the code:

```python
reason = yield TIME_FOREVER, TIME_PASSED
```

There is also a pre-defined *reason*: `TIME_PASSED`, which is an infinite number. The **process** yields with this reason will always be resumed last. Also, `TIME_FOREVER` can be considered as an infinite time. So, when the task queue is emptied, this `yield` statement will put the **process** into a forever sleeping, as the consumer does not know when the next task will arrive. But don't worry, this **process** can be activated externally by a producer later when a new task is created.

Finally, we need to put the code into an infinite loop, so the consumer can keep processing incoming tasks.

#### Producer

Then, the producer is defined as such:

```python
def producer(self, idx, consumer, task_queue, num_task):
    for _ in range(num_task):
        task = idx, i
        task_queue.append(task)
        print("[{}]P{} creates task: {}".format(self.time, idx, task))
        if consumer.next_activation_time() == TIME_FOREVER:
            consumer.activate(self.time, Reason.NewTask)
        yield self.time + randint(50, 100), Reason.NewTask
```

Except for the `self` and `task_queue` arguments, the producer **process** also takes an `idx` argument as its index, the consumer **process**, and also the maximum number or tasks to be produced. The logic is simple, after creating a task and inserting it into the task queue, the line

```python
yield self.time + randint(50, 100), Reason.NewTask
```

makes the **process** wait for a random time interval between 50s and 100s until it can create another task.

Besides, after creating the task and before the **process** being paused, the producer will check whether the `consumer`'s next activation time is `TIME_FOREVER`. If so, it will externally activate the consumer with the reason `Reason.NewTask`:

```python
if consumer.next_activation_time() == TIME_FOREVER:
    consumer.activate(self.time, Reason.NewTask)
```

(Later we will show another notification way using *Synchronisation Primitives*.)

### Running Simulation

Now, let's set up and start the simulation.

```python
if __name__ == '__main__':
    from pesim import Environment

    env = Environment()

    task_queue = deque()
    c = env.process(consumer, task_queue)
    for idx in range(2):
        env.process(producer, idx, c, task_queue, 10)

    env.start()
    env.join()
    env.finish()
```

To run the simulation, we need to create an `Environment` instance, and then use `Environment.process()` to transform the producer and consumer functions into **process**. After that, `env.start()` starts the simulation, `env.join()` runs the simulation until `TIME_FOREVER`, and after that, `env.finish()` dose some finishing and cleaning work. 

If we do not want the simulation to be executed until `TIME_FOREVER`, the `env.join()` can be replaced with `env.run_until(time)`. Also, the **process** needs not to be created before the `Environment` instance is started. The following code shows another scenario: one producer and one consumer are started first, and then after 1 hour, another producer will join. Also, we don't want to simulate the scenario until forever; instead, we only simulate it for 24 hours.

```python
env = Environment(start=True)
task_queue = deque()

env.start()
c = env.process(consumer, task_queue)
p0 = env.process(producer, 0, c, task_queue, 100)
env.run_until(3600)
p1 = env.process(producer, 1, c, task_queue, 100)
env.run_until(24 * 3600)

env.finish()
```

The `Environment` can also be used with the `with` statement. It will `start` when entering the context and `join` /`finish` automatically when exiting. The following code is equivalent to the code above.

```python
with Environment() as env:
    task_queue = deque()
    c = env.process(consumer, task_queue)
    p0 = env.process(producer, 0, c, task_queue, 100)
    env.run_until(3600)
    p1 = env.process(producer, 1, c, task_queue, 100)
```

### Method 2: Inheriting `Process` Class

A **process** can also been created by inheriting the `Process` class. The above code implements same logics as we shown in last section, except that we now make `task_queue` an attribute of `Consumer` and create a new method `submit` to push the task into the queue and check/activate the `Consumer` **process**.

```python
from pesim import Process

class Consumer(Process):
    def __init__(self, env):
        self.task_queue = deque()
        super(Consumer, self).__init__(env)
        
    def submit(self, task):
        self.task_queue.append(task)
        if self.next_activation_time() == TIME_FOREVER:
            self.activate(self.time, Reason.NewTask)
        
    def _wait(self):
        if self.task_queue:
            return self.time, Reason.NewTask
        else:
            return super(Consumer, self)._wait()

    def _process(self):
        task = self.task_queue.popleft()
        print("[{}]Consumer gets task: {}".format(self.time, task))
        yield self.time + randint(50, 100), Reason.TaskDone
        print("[{}]Consumer completes task: {}".format(self.time, task))


class Producer(Process):
    def __init__(self, env, idx, consumer, num_task):
        self.idx = idx
        self.consumer = consumer
        self.num_task = num_task
        super(Producer, self).__init__(env)
        
    def __call__(self):
        for i in range(self.num_task):
            task = self.idx, i
            print("[{}]P{} creates task: {}".format(self.time, self.idx, task))
            self.consumer.submit(task)
            yield self.time + randint(50, 100), Reason.NewTask
```

There are three methods `_wait`, `_process` and `__call__` can be overloaded. If the `__call__` is overloaded, the code inside will be executed as the **process** logic. On the other hand, the `_wait` and `_process` methods make creating **processes** that do repeated jobs easy. If `__call__` is not overloaded, `_process` will be executed for processing one task, which contains the `yield` statements, and when `_process` is finished, `_wait` method is called to determine the next job's time, which is also a 2-tuple of time and reason. Similarly, `_wait` can just return `(TIME_FOREVER, TIME_PASSED)` to sleep forever and wait others to awake the **process** later (this is `_wait`'s default implementation). 

In this example, use the following code to run the simulation.

```python
with Environment() as env:
    c = Consumer(env)
    p0 = Producer(env, 0, c, 100)
    env.run_until(3600)
    p1 = Producer(env, 1, c, 100)
```

### Synchronisation Primitives

`pesim` provides some basic synchronisation primitives including `Lock`, `Semaphore`, `Condition` and `RLock` (re-entrant lock). Note that, all the simulation **processes**' code are running within one thread, so there is no need to use these primitives to avoid data conflicts. Instead, these primitives are designed for *coordinating* different **processes**. For example, if one **process** wants to do something first, and then pass the task to another **process**, wait another **process** to do some other work on the task, and then continue the processing, using `Condition` make the thing easy.

Let's slightly modify our producer-consumer example: *now we want the producer to create a new task after its previous task is processed, instead of waiting for a random time interval*.

 To do so, we can create a `Condition` for each task, and make the producer wait on that `Condition`. Here is the code:

```python
from pesim import Process, Condition

class Consumer(Process):
    # __init__ and _wait as previous

    def submit(self, task, condition):
        self.task_queue.append((task, condition))
        if self.next_activation_time() == TIME_FOREVER:
            self.activate(self.time, Reason.NewTask)

    def _process(self):
        task, condition = self.task_queue.popleft()
        print("[{}]Consumer gets task: {}".format(self.time, task))
        yield self.time + randint(50, 100), Reason.TaskDone
        condition.set(Reason.TaskDone) #reason is optional
        print("[{}]Consumer completes task: {}".format(self.time, task))


class Producer(Process):
    # __init__ as previous

    def __call__(self):
        for i in range(self.num_task):
            task = self.idx, i
            print("[{}]P{} creates task: {}".format(self.time, self.idx, task))
            condition = Condition() #by default it is cleared
            self.consumer.submit(task, condition)
            yield condition.wait(self)
```

Now, the  `Consumer.submit()` takes arguments of not only a task, but also a `Condition` object. Once the task is processed, the consumer will call `Condition.set(reason)` on the corresponding condition.

 On the producer side, after submit a task, the `yield` statement is now 

```python
yield condition.wait()
```

Instead of pausing the producer **process** for a certain amount of time, now, this statement will pause the producer until the `condition` is set. If the condition is already set, it will resume the **process** immediately. The `Condition.wait()` needs one argument, which is the **process** that needs to be activated when the condition is set.



Now, let's make one step further. In our current implementation, when the task queue is emptied, the consumer will sleep forever, and it is producers' responsibility to check consumer's state and activate it now and them. This is not elegant at all. Instead, we can use a `Semaphore` to do the coordination. Here is the code.

```python
from pesim import Process, Condition, Semaphore

class Consumer(Process):
    def __init__(self, env):
        self.task_queue = deque()
        self.sem = Semaphore(0)
        super(Consumer, self).__init__(env)
        
    def submit(self, task, condition):
        self.task_queue.append((task, condition))
        self.sem.release()

    def _wait(self):
        return self.sem.acquire(self)

    def _process(self):
        task, condition = self.task_queue.popleft()
        print("[{}]Consumer gets task: {}".format(self.time, task))
        yield self.time + randint(50, 100), REASON_TASK_DONE
        condition.set()
        print("[{}]Consumer completes task: {}".format(self.time, task))


class Producer(Process):
    # __init__ as previous

    def __call__(self):
        for i in range(self.num_task):
            task = self.idx, i
            condition = Condition()
            self.consumer.submit(task, condition)
            print("[{}]P{} creates task: {}".format(self.time, self.idx, task))
            yield condition.wait()
```

First, we add an attribute `sem` of type `Semaphore` to `Consumer`. Every `Semaphore` has an internal value, and two methods `acquire()` and `release()` are available. Whenever the `Semaphore.release()` is called, the internal value will increased by 1. On the other hand, when `Semaphore.acquire()` is called, there are two situations. If the internal value is equal or less than 0, the **process** will be paused, until the value because greater than 0. After that, the value will be decreased by 1 again. Otherwise, if the internal value is already greater than 0, it will directly decrease by 1 and does not pause the **process**.

In our code, we set the `sem` with the initial value of 0. Whenever a task is submitted, `sem.release()` is called, and before processing the task, in `Consumer._wait()`, the consumer needs to `acquire` the `sem` first. In this way, the value of `sem` is always the number of tasks in queue, and when the queue is empty, calling `sem.acquire()` pauses the **process** until a new task is inserted.



There are also `Lock` and `RLock` (re-entrant lock) that can be used in other scenarios.



====================================================


Above are all the functionalities provided by `pesim`.
