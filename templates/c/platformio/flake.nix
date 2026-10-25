{
  description = "PlatformIO embedded development environment";

  inputs = {
    nixpkgs.url = "github:Nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Default PlatformIO environment name (-e flag). Override with
        # `PIO_ENV=someenv nix run .#flash` or just edit platformio.ini.
        defaultEnv = "";
        envFlag = if defaultEnv == "" then "" else "-e ${defaultEnv}";

        mkPioApp =
          name: text:
          {
            type = "app";
            program = pkgs.lib.getExe (
              pkgs.writeShellApplication {
                inherit name;
                runtimeInputs = with pkgs; [
                  platformio-core
                  udev
                ];
                inherit text;
              }
            );
          };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            platformio-core
            esptool # flashing ESP32/ESP8266 outside of pio if needed
            avrdude # flashing AVR/Arduino outside of pio if needed
            picocom # lightweight serial monitor alternative
            usbutils # lsusb, for finding boards
          ];

          shellHook = ''
            echo "PlatformIO devShell loaded!"
            echo "Useful commands: pio run | pio run -t upload | pio device monitor | pio device list"
          '';
        };

        # `nix run .#build`    -> compile the firmware (.pio/build/<env>/firmware.*)
        # `nix run .#flash`    -> build (if needed) + upload the firmware to the board
        # `nix run .#monitor`  -> open the serial monitor
        # `nix run .#clean`    -> remove build artifacts
        # `nix run .#test`     -> run PlatformIO unit tests
        # `nix run .#check`    -> static analysis (cppcheck/clangtidy via pio check)
        # `nix run .#devices`  -> list connected serial devices/boards
        # `nix run .#erase`    -> erase the chip's flash
        apps = {
          build = mkPioApp "pio-build" ''
            pio run ${envFlag} "$@"
          '';

          flash = mkPioApp "pio-flash" ''
            echo "Building and flashing firmware..."
            pio run ${envFlag} --target upload "$@"
          '';
          upload = self.apps.${system}.flash;

          monitor = mkPioApp "pio-monitor" ''
            pio device monitor "$@"
          '';

          clean = mkPioApp "pio-clean" ''
            pio run --target clean "$@"
          '';

          test = mkPioApp "pio-test" ''
            pio test ${envFlag} "$@"
          '';

          check = mkPioApp "pio-check" ''
            pio check ${envFlag} "$@"
          '';

          devices = mkPioApp "pio-devices" ''
            pio device list "$@"
          '';

          erase = mkPioApp "pio-erase" ''
            pio run ${envFlag} --target erase "$@"
          '';
        };
      }
    );
}
