{
  lib,
  pkgs,
  user-helpers,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./fs.nix
  ];

  machshev = {
    hostName = "anan";
    machineID = "1c4c095a3728942bbc73011192e82ead";
    autoupdate.enable = false;
    graphics.enable = false;
    display = false;
    sound = false;
    vps = true;
    server = true;
  };

  users.users.david = user-helpers.mkUserCfg {
    inherit pkgs;
    name = "david";
  };

  # The provider exposes no console, serial or otherwise, so anything that waits
  # for input at boot is indistinguishable from a dead machine and cannot be
  # cleared. Fail forward instead: never enter emergency mode, and reboot rather
  # than sit on a panic. A boot loop is recoverable remotely; a hang is not.
  systemd.enableEmergencyMode = false;
  boot.initrd.systemd.emergencyAccess = false;
  boot.kernelParams = [
    "panic=10"
    "boot.panic_on_fail"
  ];
  systemd.settings.Manager.CrashAction = "reboot";

  # The provider's console viewer renders output but does not reliably deliver
  # keystrokes, so logging in to inspect a broken boot is not possible. Print the
  # state we would otherwise have to ask for directly onto tty1, on a loop, so it
  # can simply be read off the screen.
  systemd.services.netdiag = {
    description = "Print network state to the console";
    wantedBy = ["multi-user.target"];
    after = ["systemd-networkd.service" "sshd.service"];
    serviceConfig = {
      Type = "simple";
      StandardOutput = "tty";
      StandardError = "tty";
      TTYPath = "/dev/tty1";
      Restart = "always";
      RestartSec = 20;
    };
    script = ''
      echo "================ NETDIAG $(date -Is) ================"
      ${pkgs.iproute2}/bin/ip -o link show | ${pkgs.gnused}/bin/sed 's/\\/ /'
      echo "-- addresses --"
      ${pkgs.iproute2}/bin/ip -4 -o addr show
      echo "-- routes --"
      ${pkgs.iproute2}/bin/ip -4 route
      echo "-- units --"
      systemctl is-active systemd-networkd sshd nftables | tr '\n' ' '; echo
      echo "-- networkd --"
      ${pkgs.systemd}/bin/networkctl --no-pager --no-legend status 2>&1 | head -12
      echo "-- listening --"
      ${pkgs.iproute2}/bin/ss -tlnp 2>/dev/null | head -6
      echo "-- last networkd log --"
      journalctl -b -u systemd-networkd --no-pager -n 8 -o cat 2>&1
      echo "===================================================="
      sleep 3600
    '';
  };

  # The provider assigns one permanent public address, handed out as a /32 whose
  # gateway sits outside that prefix and is only reachable because DHCP also
  # supplies a link-scoped route to it. Configure the whole thing statically
  # instead: on a machine whose only practical access is the network it is
  # bringing up, a DHCP round trip is a failure mode that cannot be diagnosed.
  # This replaces the DHCP network that nixos-facter generates for this link.
  # Matched on link type rather than name: this VPS has exactly one ethernet
  # device, and a name that fails to match would silently leave it unconfigured
  # on a machine with no other way in. Sorts before the generated 40-/99- units,
  # and networkd applies only the first match.
  systemd.network.networks."10-wan" = {
    matchConfig.Type = "ether";
    address = ["87.106.54.175/32"];
    routes = [
      {
        Gateway = "87.106.54.1";
        # Required: with a /32 the gateway is not on-link by prefix, so without
        # this the default route is rejected as unreachable.
        GatewayOnLink = true;
      }
    ];
    networkConfig.IPv6PrivacyExtensions = "kernel";
    linkConfig.RequiredForOnline = "routable";
  };

  # Console login must work even with no network at all. initialHashedPassword
  # only applies when an account is first created, which is too conditional to
  # rely on as the sole way in.
  users.users.root.hashedPassword = "$6$z8fXf0P0ap18L20y$NCe1iQXlG.Rv.br/sAnj7cpIQk5pvpikddLfxQKebJU0xJhsGj9/Pyu.MQ2vW/9St7unvHQo5AoqsjUX8bqZl1";

  # A non-critical mount must never hold up the boot that gives us SSH back.
  fileSystems."/boot".options = ["nofail" "x-systemd.device-timeout=10s"];
  fileSystems."/boot/efi".options = ["nofail" "x-systemd.device-timeout=10s"];

  system.stateVersion = "24.11";
}
