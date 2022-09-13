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
        readmeFiles = ["README.md" "SECURITY.md" "LICENSE" "CHANGELOG.md" "CODE_OF_CONDUCT.md"];
        nixFiles = [(nix-filter.matchExt "nix")];
      };

      # Common derivation arguments used for all builds
      commonArgs =  {
        name = "jupyter";
        root = ./.;
      };

      # Use a standard way of naming derivations package names.
      packageName = suffix: commonArgs.name + "-" + suffix;
      
      cadCAD = with pkgs; with python39Packages; buildPythonPackage rec {
        pname = "cadCAD";
        version = "0.4.23";
        src = fetchurl {
            url = "https://files.pythonhosted.org/packages/8b/ea/39cf41e5b515027cfff44940e8e95f993ca74d8bafacbe0c7f25fc0c5905/cadCAD-0.4.23.tar.gz";
            sha256 = "6c9fcc2cff34e0eae00f33ec3291f8ffc7452c8621c0aa6d900d1dfe2acd1625";
            };
        
        propagatedBuildInputs = [ ppft multiprocess pox dill pathos pytz pandas funcy fn ];
        doCheck = false;
      };

      # Build all the Hugo website dependencies and make them available for development of
      # the website.
      jupyterEnv = pkgs.mkShell rec {
        name = packageName "jupyter-environment";        
        buildInputs = [ (pkgs.python39.withPackages (ps: with ps; [ ipython jupyter numpy pandas matplotlib plotly statsmodels ])) cadCAD ];
        src =  nix-filter {
          root = commonArgs.root; 
          exclude = commonFilters.readmeFiles;
        };
        shellHook = ''
        export PS1="\u@\H ~ "
        '';
      };

    in 
    {
      packages = rec {
        nixCad = cadCAD;
        default = nixCad;
      };
      devShells.default = jupyterEnv;
    });
  }