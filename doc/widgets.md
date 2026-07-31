The bridge between the reactive graph and the widget tree.

`Observer` runs its builder under dependency tracking: every reactive value
read inside subscribes the widget, and the subscriptions are rediscovered on
every build, so conditional reads stay correct. `Observer.withChild` keeps a
heavy static subtree out of the rebuilt region.

In debug mode an observer whose builder tracks nothing throws, since it would
never rebuild.
