{
  description = "Dogmeat.nvim development environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        shell = pkgs.bash;

        pluginPkgs = with pkgs; [
          (lua5_2.withPackages (ps: with ps; [
            busted
            luafilesystem
            luacheck
            luarocks
          ]))
          neovim
        ];

        dogmeat_nvim = pkgs.stdenv.mkDerivation {
          name = "dogmeat.nvim for ${system}";
          src = ./.;
          doCheck = true;

          checkInputs = pluginPkgs;

          # NOTE: Configure the test environment
          configurePhase = ''
            export NVIM_BIN=${pkgs.neovim}/bin/nvim
          '';

          # NOTE: Run the tests
          checkPhase = ''

            echo "Running quick checks:"
            ${pkgs.lua54Packages.busted}/bin/busted lua
            ${pkgs.lua54Packages.luacheck}/bin/luacheck lua

            echo "Running tests: for ${system}"
            ${shell}/bin/bash ./nvim-test.sh
          '';

          buildPhase = ''
            echo "Building plugins for ${system}"
          '';
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = pluginPkgs;
        };

        packages = {
          default = dogmeat_nvim;
          dogmeat_nvim = dogmeat_nvim;
        };
    });
}
