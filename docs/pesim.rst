APIs
=============

Environment
----------------

.. automodule:: pesim.sim

.. autoclass:: pesim.sim.Environment
   :members: time, started

   .. automethod:: pesim.sim.Environment.start
   .. automethod:: pesim.sim.Environment.join
   .. automethod:: pesim.sim.Environment.finish
   .. automethod:: pesim.sim.Environment.run_until
   .. automethod:: pesim.sim.Environment.process
   .. automethod:: pesim.sim.Environment.next_event_time

Process
--------------------

.. automodule:: pesim.process

.. autoclass:: pesim.process.Process
   :members: time

   .. automethod:: pesim.process.Process.__call__
   .. automethod:: pesim.process.Process._wait
   .. automethod:: pesim.process.Process._process
   .. automethod:: pesim.process.Process.activate
   .. automethod:: pesim.process.Process.next_activation_time

Constants
-------------------

.. automodule:: pesim.define
   :members:

Synchronisation Primitives
-----------------------------
.. automodule:: pesim.lock

.. autoclass:: pesim.lock.Lock
   :members: acquire, release

.. autoclass:: pesim.lock.Semaphore
   :members: value, acquire, release

.. autoclass:: pesim.lock.RLock
   :members: acquire, release

.. autoclass:: pesim.lock.Condition
   :members: value

   .. automethod:: pesim.lock.Condition.set
   .. automethod:: pesim.lock.Condition.wait
   .. automethod:: pesim.lock.Condition.clear
