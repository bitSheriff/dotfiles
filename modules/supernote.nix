{
    config,
    pkgs,
    inputs,
    ...
}:
let
    # Common bash logic to find the IP (cached or via nmap scan)
    getSupernoteIpScript = ''
        CACHE_FILE="$HOME/.cache/supernote_ip"

        # If --scan is passed, or no cache exists, find the IP
        if [[ "''${1:-}" == "--scan" ]] || [ ! -f "$CACHE_FILE" ]; then
          echo "Determining Supernote IP..."
          
          # Get the primary network interface's subnet (ignores docker/tailscale/etc)
          INTERFACE=$(ip route get 8.8.8.8 | awk 'NR==1 {print $5}')
          SUBNET=$(ip -o -f inet addr show "$INTERFACE" | awk '{print $4}')
          
          echo "Scanning $SUBNET for port 8089 (this may take a few seconds)..."
          # Scan for the web filebrowser port to identify the device
          IP=$(nmap -p 8089 --open "$SUBNET" -oG - | awk '/Up$/{print $2}' | head -n 1)
          
          if [ -z "$IP" ]; then
            echo "Could not find Supernote on the network."
            echo "Make sure it is awake, on the same Wi-Fi, and screen mirroring/file sharing is enabled."
            exit 1
          fi
          
          echo "Found Supernote at $IP"
          mkdir -p "$HOME/.cache"
          echo "$IP" > "$CACHE_FILE"
        else
          IP=$(cat "$CACHE_FILE")
        fi

        echo "$IP"
    '';

    # Script to open the Screen Mirroring (Port 8080)
    supernote-mirror = pkgs.writeShellApplication {
        name = "supernote-mirror";
        runtimeInputs = with pkgs; [
            nmap
            iproute2
            xdg-utils
            coreutils
        ];
        text = ''
            ${getSupernoteIpScript}
            echo "Opening Screen Mirroring..."
            xdg-open "http://$IP:8080"
        '';
    };

    # Script to open the Web File Browser (Port 8089)
    supernote-files = pkgs.writeShellApplication {
        name = "supernote-files";
        runtimeInputs = with pkgs; [
            nmap
            iproute2
            xdg-utils
            coreutils
        ];
        text = ''
            ${getSupernoteIpScript}
            echo "Opening Web File Browser..."
            xdg-open "http://$IP:8089"
        '';
    };
in
{
    imports = [
    ];

    environment.systemPackages = with pkgs; [
        supernote-tool
        # Scripts
        supernote-mirror
        supernote-files
    ];

    environment.etc."libinput/local-overrides.quirks".text = ''
        [Supernote Supernote Nomad]
        MatchVendor=0x2207
        MatchProduct=0x07
        AttrEventCode=+BTN_STYLUS
        AttrPressureRange=197:194
    '';

    services.udev.extraHwdb = ''
        evdev:input:b0003v2207p0007*
         EVDEV_ABS_00=::20
         EVDEV_ABS_01=::20
    '';
}
