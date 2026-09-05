# rain.math.saturating

Math operations that clamp at the numeric bounds rather than error or wrap.

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
[`LICENSES/`](LICENSES/LicenseRef-DCL-1.0.txt).

This repo is [REUSE 3.2](https://reuse.software/spec-3.2/) compliant.

## Contributions

Welcome under the same license. Contributors warrant that their contributions
are compliant.
