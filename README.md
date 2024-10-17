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

## Dev stuff

### Local environment & CI

Uses nixos.

Install `nix develop` - https://nixos.org/download.html.

Run `nix develop` in this repo to drop into the shell. Please ONLY use the nix
version of `foundry` for development, to ensure versions are all compatible.

Read the `flake.nix` file to find some additional commands included for dev and
CI usage.

## Legal stuff

Everything is under DecentraLicense 1.0 (DCL-1.0) which can be found in `LICENSES/`.

This is basically `CAL-1.0` which is an open source license
https://opensource.org/license/cal-1-0

The non-legal summary of DCL-1.0 is that the source is open, as expected, but
also user data in the systems that this code runs on must also be made available
to those users as relevant, and that private keys remain private.

Roughly it's "not your keys, not your coins" aware, as close as we could get in
legalese.

This is the default situation on permissionless blockchains, so shouldn't require
any additional effort by dev-users to adhere to the license terms.

This repo is REUSE 3.2 compliant https://reuse.software/spec-3.2/ and compatible
with `reuse` tooling (also available in the nix shell here).

```
nix develop -c rainix-sol-legal
```

## Contributions

Contributions are welcome **under the same license** as above.

Contributors agree and warrant that their contributions are compliant.