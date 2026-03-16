{ config, pkgs, lib, ... }:

{
  # Timezone и locale
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";

  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  # User
  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Добавить SSH ключ через cloud-init или вручную
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  # Базовые пакеты
  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    wget
    jq
    git
    wireguard-tools
    kubectl
    nftables
    iptables
    tcpdump
    dig
  ];

  # Включить IP forwarding (необходимо для VPN/прокси)
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.route_localnet" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
