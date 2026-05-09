# rain.math.saturating

Math operations that clamp at the numeric bounds rather than error or wrap.

For asset transfers, an overflow error can lock assets in an erroring contract
over a tiny rounding/calculation slip; an underflow that wraps to "infinity" can
cause approve/transfer of more than intended. Saturating arithmetic is the
pragmatic guard: bounded mistakes stay bounded.

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

Tasks exposed via the shell:

- `rainix-sol-test` — `forge test`
- `rainix-sol-static` — slither
- `rainix-sol-legal` — `reuse lint`

Use the nix-pinned `forge` for all development.

## Publish

Tag `v<x.y.z>` on `main`. The
[`Publish to Soldeer`](.github/workflows/publish-soldeer.yaml) wrapper delegates
to rainix's reusable workflow, which derives the package name from the repo name
(`rain.math.saturating` → `rain-math-saturating`).

## License

DecentraLicense 1.0 (DCL-1.0) — full text in
[`LICENSES/`](LICENSES/LicenseRef-DCL-1.0.txt). Roughly `CAL-1.0`
([opensource.org](https://opensource.org/license/cal-1-0)) plus user-data
disclosure obligations consistent with permissionless-blockchain assumptions.

This repo is [REUSE 3.2](https://reuse.software/spec-3.2/) compliant. Verify
locally:

```sh
nix develop -c rainix-sol-legal
```

## Contributions

Welcome under the same license. Contributors warrant that their contributions
are compliant.
