# rain.math.saturating

Sometimes we neither want math operations to error nor wrap around on an overflow
or underflow. In the case of transferring assets an error may cause assets to be
locked in an irretrievable state within the erroring contract, e.g. due to a tiny
rounding/calculation error. We also can't have assets underflowing and attempting
to approve/transfer "infinity" when we wanted "almost or exactly zero" but some
calculation bug underflowed zero.

Ideally there are no calculation mistakes, but in guarding against bugs it may be
safer pragmatically to saturate arithmatic at the numeric bounds.

Note that saturating div is not supported because 0/0 is undefined.