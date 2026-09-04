# rain.math.saturating

Math operations that clamp at the numeric bounds rather than error or wrap.

For asset transfers, an overflow error can lock assets in an erroring contract
over a tiny rounding/calculation slip; an underflow that wraps to "infinity" can
cause approve/transfer of more than intended. Saturating arithmetic is the
pragmatic guard: bounded mistakes stay bounded.

The ceiling is `type(uint256).max`, which is also the ERC20 infinite allowance
value, so a saturated `add` or `mul` result must be bounded against a balance or
an explicit cap before it is used as an allowance.

Saturating `add`, `sub`, `mul` are supported. `div` is not — `0/0` is undefined.

## Install

Via [soldeer](https://soldeer.xyz):

```sh
forge soldeer install rain-math-saturating~<version>
```

## Develop

This repo uses [nix](https://nixos.org/download.html) for its dev shell. The
default shell is the slim `sol-shell` from
[rainix](https://github.com/rainlanguage/rainix) — no rust, node, or chromium.

```sh
nix develop          # enter the shell
forge soldeer install # install deps declared in foundry.toml
forge test
```

Use the nix-pinned `forge` for all development.

## License

DecentraLicense 1.0 (DCL-1.0) — full text in
[`LICENSES/`](LICENSES/LicenseRef-DCL-1.0.txt). Roughly `CAL-1.0`
([opensource.org](https://opensource.org/license/cal-1-0)) plus user-data
disclosure obligations consistent with permissionless-blockchain assumptions.

This repo is [REUSE 3.2](https://reuse.software/spec-3.2/) compliant.

## Contributions

Welcome under the same license. Contributors warrant that their contributions
are compliant.
