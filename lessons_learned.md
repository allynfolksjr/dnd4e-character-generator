# Lessons Learned


## 2012-08-26

* Instead of doing weird things where you explicitly init race-specific functions, just use initialize for both and run a "super" call in initialize of the child class in order to have the parent also run its init scripts.
* Try using mixins and "include blah" instead of "Cheese < Blah" next time
