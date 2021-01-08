"""
Attributes:
    TIME_FOREVER(float): A pre-defined time which can be considered as :obj:`+inf`.
    TIME_PASSED(int): A pre-defined reason which can be considered as :obj:`+inf`.\
    When a process is activated at time `t` with this reason, all the events at time `t` have been processed.
    TIME_REACHED(int): A pre-defined reason which can be considered as :obj:`-inf`.\
    When a process is activated at time `t` with this reason, all the events at time `t` have not been processed.
    LOCK_RELEASED(int): A pre-defined reason representing a sync primitive is "released".
"""

_TIME_FOREVER = 100 * 365 * 24 * 60 * 60

_TIME_PASSED = 100000
_TIME_REACHED = -_TIME_PASSED
_LOCK_RELEASED = _TIME_REACHED

TIME_FOREVER = _TIME_FOREVER

TIME_PASSED = _TIME_PASSED
TIME_REACHED = _TIME_REACHED
LOCK_RELEASED  = _LOCK_RELEASED
