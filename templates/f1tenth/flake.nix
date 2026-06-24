{
  description = "F1Tenth ROS 2 Jazzy development environment";

  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";
    nixgl.url = "github:nix-community/nixGL";
    nixgl.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [
      "https://ros.cachix.org"
    ];
    extra-trusted-public-keys = [
      "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
    ];
    max-jobs = 2;
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-ros-overlay,
      nixgl,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgs = import nixpkgs {
        overlays = [ nix-ros-overlay.overlays.default ];
      };

      sharedRosPackages =
        ros: with ros; [
          ackermann-msgs
          diagnostic-aggregator
          geometry-msgs
          joint-state-publisher
          nav-msgs
          nav2-lifecycle-manager
          nav2-map-server
          plotjuggler-ros
          rosidl-default-generators
          rosidl-default-runtime
          sensor-msgs
          teleop-twist-keyboard
          tf2-geometry-msgs
          tf2-ros
          xacro
          nav2-mppi-controller # Model Predictive Controller
          navigation2
          nav2-controller
        ];

      sharedRosPythonDependencies =
        pkgs: with pkgs; [
          # Use Python 3.13 consistently
          python313
          python313Packages.numpy
          python313Packages.transforms3d
          python313Packages.scikit-image
          python313Packages.pip
          python313Packages.opencv4
          python313Packages.numba
          python313Packages.scipy
          python313Packages.pyyaml
          python313Packages.pyglet
          python313Packages.pyopengl
          python313Packages.pillow
        ];

    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ nix-ros-overlay.overlays.default ];
          };
          ros = pkgs.rosPackages.jazzy;

        in
        {
          clean = pkgs.stdenv.mkDerivation {
            name = "Clean";
            buildPhase = ''
              echo "Deleting directories"
              rm -rf install/
              rm -rf log/
            '';
          };

          default = pkgs.stdenv.mkDerivation {
            name = "f1tenth-build";
            src = ./.;

            dontUseCmakeConfigure = true;
            dontWrapQtApps = true;

            nativeBuildInputs = [
              ros.ros-environment
              ros.ament-cmake
              ros.ament-cmake-ros
              ros.ament-lint-auto
              pkgs.colcon
              pkgs.python3
              pkgs.python3Packages.setuptools
            ];

            propagatedBuildInputs = [
            ]
            ++ (sharedRosPackages ros)
            ++ (sharedRosPythonDependencies pkgs);

            buildPhase = ''
              export COLCON_EXTENSION_BLACKLIST=colcon_ros.prefix_path.ament
              export PYTHONPATH="${pkgs.python3Packages.setuptools}/${pkgs.python3.sitePackages}:$PYTHONPATH"

              colcon build --install-base ./install
              colcon build --install-base ./install --packages-select f1tenth_gym
              colcon build --install-base ./install --packages-select f1tenth_gym_ros
            '';

            installPhase = ''
              mkdir -p $out
              cp -r ./install/* $out/

              # Ensure launch and config are at the root as requested by Docker logic or previous structure
              # But usually ROS expects them in share/<package>/
              # We will keep them at $out/launch and $out/config for now to match previous attempt
              cp -r $src/launch $out/
              cp -r $src/config $out/
            '';
          };

          docker = pkgs.dockerTools.buildLayeredImage {
            name = "f1tenth-ros2-jazzy";
            tag = "latest";
            contents =
              with pkgs;
              [
                bashInteractive
                coreutils
                git
                tmux
                vim
                sudo
                xterm
                ros.ros-environment
                ros.rviz2
                ros.rqt-gui
                ros.rqt-common-plugins
                ros.rqt-reconfigure
                ros.diagnostic-aggregator
                ros.plotjuggler-ros
              ]
              ++ (sharedRosPackages ros)
              ++ (sharedRosPythonDependencies pkgs)
              ++ [ self.packages.${system}.default ];

            config = {
              Entrypoint = [ "${pkgs.bashInteractive}/bin/bash" ];
              Cmd = [ ];
              WorkingDir = "/arc2026/ws";
              Env = [
                "TERM=xterm-256color"
                "SHELL=/bin/bash"
                "ROS_DISTRO=jazzy"
                "ROS_PYTHON_VERSION=3"
              ];
              User = "ros";
            };

            fakeRootCommands = ''
              # Create the ros user
              echo "ros:x:1000:1000:ROS User:/home/ros:/bin/bash" > ./etc/passwd
              echo "ros:x:1000:" > ./etc/group
              mkdir -p ./home/ros
              chown 1000:1000 ./home/ros

              # Set up tmux config matching the Dockerfile
              printf "set -g mouse on\nset-option -g history-limit 100000\nset -g pane-border-format \"#{pane_index} #{pane_title}\"\nset -g pane-border-status bottom\n" > ./home/ros/.tmux.conf

              # Set up .bashrc to source ROS environment
              # We use a wildcard to find the setup.bash in the store path of our built package
              printf "source /nix/store/*/setup.bash\n" >> ./home/ros/.bashrc

              chown 1000:1000 ./home/ros/.tmux.conf ./home/ros/.bashrc

              # Sudoers
              mkdir -p ./etc/sudoers.d
              echo "ros ALL=(root) NOPASSWD:ALL" > ./etc/sudoers.d/ros
              chmod 0440 ./etc/sudoers.d/ros

              # Setup the workspace directory structure
              mkdir -p ./arc2026/ws
              chown -R 1000:1000 ./arc2026
            '';
          };
        }
      );

      #### APPS ####
      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = nixpkgs.lib;
          mkSimApp = launchFile: {
            type = "app";
            program = lib.getExe (
              pkgs.writeShellApplication {
                name = "run-${launchFile}";
                text = ''
                  echo "Starting ROS 2 simulation for ${launchFile}..."
                  set +u
                  # shellcheck disable=SC1091
                  source install/local_setup.bash
                  set -u
                  ros2 launch launch/${launchFile}
                '';
              }
            );
          };

        in
        {
          sim = mkSimApp "sim.py";
          pure_pursuit = mkSimApp "pure_pursuit_sim.py";
        }
      );

      #### DEV SHELL ####
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ nix-ros-overlay.overlays.default ];
          };
          rosShell = nix-ros-overlay.devShells.${system}.example-ros2-desktop-jazzy;
          ros = pkgs.rosPackages.jazzy;

          # Explicitly grab the nixGL wrapper for your system
          nixGLDefault = nixgl.packages.${system}.nixGLIntel;

          build_colcon = pkgs.writeShellScriptBin "build_colcon" ''
            colcon build
            colcon build --symlink-install --packages-select f1tenth_gym
            colcon build --symlink-install --packages-select f1tenth_gym_ros
          '';

          helper-script = pkgs.writeShellApplication {
            name = "helpers";
            runtimeInputs = [ pkgs.gum ];
            text = ''
              ACTIONS=("print tf tree" "build" "clean build")

              echo "Choose an action to perform:"
              CHOSEN=$(printf "%s\n" "''${ACTIONS[@]}" | gum choose)

              if [ "$CHOSEN" = "print tf tree" ]; then
                  gum style --foreground 212 "Printing the tf tree to a pdf file"
                  ros2 run tf2_tools view_frames

              elif [ "$CHOSEN" = "build" ]; then
                  gum style --foreground 57 "Building the application"
                  build_colcon

              elif [ "$CHOSEN" = "clean build" ]; then
                  gum style --foreground 82 "Doing a clean build"
                  rm -rf install/ logs/
                  build_colcon

              else
                  echo "No valid selection made."
                  exit 1
              fi
            '';
          };

          rviz2_wrapped = pkgs.writeShellScriptBin "rviz2" ''
            # Force EGL to fix FBConfig mismatch in Jazzy (Qt6)
            export QT_XCB_GL_INTEGRATION=xcb_egl
            exec ${nixGLDefault}/bin/nixGLIntel ${ros.rviz2}/bin/rviz2 "$@"
          '';

          rqt_wrapped = pkgs.writeShellScriptBin "rqt_reconfigure" ''
            exec ${nixGLDefault}/bin/nixGLIntel ${ros.rqt-reconfigure}/bin/rqt_reconfigure "$@"
          '';
        in
        {
          default = pkgs.mkShell {
            name = "f1tenth-jazzy-shell";
            inputsFrom = [ rosShell ];

            packages =
              with pkgs;
              [
                # Hardware Acceleration
                nixGLDefault
                glxinfo

                # Development tools
                bashInteractive
                just
                git
                gum
                gimp # to edit maps
                tmux
                lazygit
                rsync
                python3
                uv

                # Scripts
                build_colcon
                helper-script
                rviz2_wrapped
                rqt_wrapped
              ]
              ++ (sharedRosPackages ros)
              ++ (sharedRosPythonDependencies pkgs);

            ROS_DOMAIN_ID = 69;

            shellHook = ''
              export COLCON_EXTENSION_BLACKLIST=colcon_ros.prefix_path.ament

              # --- Local Python Virtual Environment ---
              export LOCAL_PYTHON_ENV="$PWD/.venv"
              export PYTHONPATH="$LOCAL_PYTHON_ENV/lib/python3.13/site-packages:$PWD/gym:$PWD/f1tenth_gym/gym:$PYTHONPATH"
              export PATH="$LOCAL_PYTHON_ENV/bin:$PATH"

              if [ ! -d "$LOCAL_PYTHON_ENV" ]; then
                echo "Creating local Python virtual environment..."
                python3 -m venv "$LOCAL_PYTHON_ENV" --system-site-packages
                unset SOURCE_DATE_EPOCH
                "$LOCAL_PYTHON_ENV/bin/pip" install setuptools wheel
                if [ ! -d "gym" ]; then
                  git clone https://github.com/openai/gym -b 0.19.0 --depth 1
                  sed -i "/extras_require/d" gym/setup.py
                fi
                "$LOCAL_PYTHON_ENV/bin/pip" install -e ./gym

                if [ ! -d "f1tenth_gym" ]; then
                  git clone https://github.com/f1tenth/f1tenth_gym
                  sed -i "/numpy/d" f1tenth_gym/setup.py
                fi
                "$LOCAL_PYTHON_ENV/bin/pip" install -e ./f1tenth_gym
              fi
              # ----------------------------------------

              # --- Graphics Fix (via nixGL) ---
              export QT_QPA_PLATFORM=xcb
              export QT_XCB_GL_INTEGRATION=xcb_egl
              export Ogre_GL_Config=GLX

              # Set up nixGL and Mesa drivers
              export LIBGL_DRIVERS_PATH="${pkgs.mesa}/lib/dri"
              export LD_LIBRARY_PATH="${nixGLDefault}/lib:${pkgs.mesa}/lib:${
                pkgs.lib.makeLibraryPath [
                  pkgs.stdenv.cc.cc.lib
                  pkgs.glib
                  pkgs.libGL
                  pkgs.libxcb
                  pkgs.xorg.libX11
                  pkgs.xorg.libSM
                  pkgs.xorg.libICE
                  pkgs.xorg.libXext
                  pkgs.zlib
                ]
              }:$LD_LIBRARY_PATH"

              # Add wrapped GUI tools to PATH
              export PATH="${rviz2_wrapped}/bin:${rqt_wrapped}/bin:$PATH"

              # --- Setup Consistency Symlinks ---
              mkdir -p src
              [ -L src/f1tenth_gym_ros ] || ln -s ../f1tenth_data src/f1tenth_gym_ros
              [ -L src/your_code ] || ln -s . src/your_code

              # Shell Aliases
              alias nv='nvim'
              alias lg='lazygit'

              # Dynamically patch sim.yaml in install space for local Nix usage
              ros2() {
                local target="install/f1tenth_gym_ros/share/f1tenth_gym_ros/config/sim.yaml"
                if [ -f "$target" ] && grep -q "/arc2026" "$target"; then
                  rm -f "$target"
                  sed "s|/arc2026|$PWD|g" src/f1tenth_gym_ros/config/sim.yaml > "$target"
                fi
                
                # Wrap GUI-heavy commands with nixGL to ensure rviz2/rqt work
                if [[ "$1" == "launch" || "$1" == "run" ]]; then
                  ${nixGLDefault}/bin/nixGLIntel ros2 "$@"
                else
                  command ros2 "$@"
                fi
              }

              echo "--- F1Tenth ROS 2 Jazzy (Nix) ---"
              echo "Graphics: Wrapped in nixGL (Impure mode)"
              echo "Aliases: nv -> nvim, lg -> lazygit"
            '';
          };
        }
      );
    };
}
