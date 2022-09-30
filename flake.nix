{
  description = "A flake building jupyter Notebook with cadCAD.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs"; 
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    flake-compat.inputs.nixpkgs.follows = "nixpkgs";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, flake-compat, ... }:
    flake-utils.lib.eachDefaultSystem  ( system: 
    let
      pkgs = import nixpkgs { inherit system; };
      inherit (pkgs) lib stdenv;

      # Non-Flake input, so need to import it.
      # npmlock2nix = pkgs.callPackages inputs.npmlock2nix {};

      # Fix-up the flake introduced name for nix-filter for consistency.
      nix-filter = inputs.nix-filter.lib;

      # To get good build times it's vitally important to not have to rebuild 
      # derivation needlessly. The way Nix caches things is very simple: if 
      # any input file changed, derivation needs to be rebuild. Use nix-filter
      # to include or exlude files and directories from a derivation build.
      commonFilters = rec {
        markdownFiles = [(nix-filter.matchExt "md")];
        nixFiles = [(nix-filter.matchExt "nix")];
      };

      # Common derivation arguments used for all builds
      commonArgs =  {
        name = "jupyter";
        root = ./.;
      };

      # Use a standard way of naming derivations package names.
      packageName = suffix: commonArgs.name + "-" + suffix;
      
      # build cadCAD by pulling down the pypi package
      cadCAD = with pkgs; with python37; buildPythonPackage rec {
        pname = "cadCAD";
        version = "0.4.23";
        src = fetchPypi {
            inherit pname version;
            sha256 = "6c9fcc2cff34e0eae00f33ec3291f8ffc7452c8621c0aa6d900d1dfe2acd1625";
            };
        propagatedBuildInputs = [ ppft multiprocess pox dill pathos pytz pandas funcy fn ];
        doCheck = false;

      };
      # TODO: fix cadCAD build with lower versions of python.
      # ipython37 = with pkgs; with python37; buildPythonPackage rec {
      #   pname = "ipython";
      #   version = "7.3.1";
      #   src = fetchPypi {
      #       inherit pname version;
      #       sha256 = "cb6aef731bf708a7727ab6cde8df87f0281b1427d41e65d62d4b68934fa54e97";
      #       };
      #   doCheck = false;

      # };

    in 
    {
      devShells = {
        default = pkgs.mkShell rec { 
          name = packageName "jupyter-environment";        
          buildInputs = [ pkgs.python37.withPackages (ps: with ps; [ ipython jupyter] ) ];
          src =  nix-filter {
            root = commonArgs.root; 
            exclude = commonFilters.markdownFiles ++ commonFilters.nixFiles;
          };
          shellHook = ''
            export PS1="\u@\H ~ "
          '';
          };
        };
    });
  }