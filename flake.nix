{
  description = "Flake for the bar tab frontend application (tab-ui)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = {
    self,
    nixpkgs,
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
        }));
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    packages = forAllSystems (pkgs: {
      default = self.packages.${pkgs.system}.tab-ui;
      tab-ui = pkgs.stdenv.mkDerivation rec {
        pname = "tab-ui";

        # tab-ui does not have versioned releases. To still keep track of some sort of version (a Nix package requires
        # it and it's also convenient for debugging) and not having to make up something arbitrary like "1.0", we'll
        # use the Nix builtin substring function to extract the first 7 characters of the git commit hash that the
        # build of this package is based on and use that as the version indicator.
        # To avoid duplication or creating extra variables through let bindings, we'll make the attribute set passed to
        # the mkDerivation function above recursive by adding the `rec` keyword. This allows us to reference the
        # revision attribute in the fetchgit function below through `src.rev`.
        version = builtins.substring 0 7 src.rev;

        src = pkgs.fetchgit {
          url = "https://github.com/voidwarranties/tab-ui.git";
          rev = "90c0d413625e53826605c5b92fcc02e5b4a8b736";
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
        ];
      };
    });

    overlays.default = final: prev: {
      inherit (self.packages.${prev.system}) tab-ui;
    };
  };
}
