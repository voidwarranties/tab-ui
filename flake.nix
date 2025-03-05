{
  description = "Flake for the bar tab frontend application (tab-ui)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    devshell,
  } @ inputs: let
    # This list of architectures provides the supported systems to the wrapper function below.
    # It basically defines which architectures can build and run the tab-ui application.
    supportedSystems = [
      "aarch64-darwin"
      "x86_64-linux"
    ];

    # This helper function is used to make the flake outputs below more DRY. It looks a bit intimidating but that's
    # mostly because of the functional programming nature of Nix. I recommend reading
    # [Nix language basics](https://nix.dev/tutorials/nix-language.html) and search online for resources about
    # functional programming paradigms.
    #
    # Basically this function makes it so that instead of declaring outputs for every architecture as the flake schema
    # expects, e.g.:
    #
    # packages = {
    #   "x86_64-linux" = {
    #     ...
    #   };
    #   "aarch64-darwin" = {
    #     ...
    #   };
    # };
    #
    # we can define each output below (package, formatter, ...) once for all the architectures / systems.
    #
    # See https://ayats.org/blog/no-flake-utils to learn more.
    #
    forAllSystems = function:
      nixpkgs.lib.genAttrs supportedSystems (system:
        function (import nixpkgs {
          inherit system;
          overlays = [
            devshell.overlays.default
          ];
        }));
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    packages = forAllSystems (pkgs: {
      default = self.packages.${pkgs.system}.tab-ui;
      tab-ui = pkgs.stdenv.mkDerivation rec {
        pname = "tab-ui";

        version = builtins.substring 0 7 src.rev;

        src = pkgs.fetchgit {
          url = "https://github.com/0x20/tab-ui.git";
          rev = "ef92b6c9dcd62a7430d4bc4a0b9028b76047d99c";
          hash = "sha256-uQ/BIEYArVs0KIwfDNQbqxrTSbwZ6NIgW4KMwz7xSHk=";
          fetchSubmodules = true;
        };

        nativeBuildInputs = with pkgs; [
          qt5.qmake
        ];

        buildInputs = with pkgs; [
          qt5.qtquickcontrols2
          qt5.wrapQtAppsHook
        ];

        patches = [
          ./patches/0001-main.qml-change-window-title-for-voidwarranties.patch
          ./patches/0002-show-product-prices.patch
        ];
      };
    });

    devShells = forAllSystems (pkgs: {
      default = pkgs.devshell.mkShell {
        name = "tab-ui devshell";
        packages = with pkgs; [
          stdenv
          qt5.full
        ];
        commands = [
          {
            name = "run";
            help = "run";
            command = ''
              nix run '.?submodules=1#'            
            '';
          }
        ];
      };
    });

    overlays.default = final: prev: {
      inherit (self.packages.${prev.system}) tab-ui;
    };
  };
}
