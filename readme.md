# CadCAD with Nix Flakes

This flake reproduces the build for Jupyter notebook and cadCAD version 0.4.23.
legacy commands are supported such as nix-shell and nix-build which also work alongside with the flake commands.

## Enter the environment

To run an environment with Jupyter run this:

```bash
nix develop github:yumiai/cadCAD-Flake -c jupyter notebook
```