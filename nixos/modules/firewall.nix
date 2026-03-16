{ config, pkgs, lib, ... }:

{
  # Отключаем стандартный NixOS firewall в пользу nftables
  networking.firewall.enable = false;

  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet filter {
        chain input {
          type filter hook input priority 0; policy drop;

          # Loopback
          iifname "lo" accept

          # Established/related
          ct state established,related accept

          # ICMP
          ip protocol icmp accept
          ip6 nexthdr icmpv6 accept

          # SSH
          tcp dport 22 accept

          # HTTP/HTTPS (Traefik)
          tcp dport { 80, 443 } accept

          # x3-ui admin panel (через Traefik)
          tcp dport 2053 accept

          # MTProto proxy
          tcp dport 8443 accept

          # AmneziaWG
          udp dport 51820 accept

          # k3s API (только для локального доступа)
          tcp dport 6443 accept
        }

        chain forward {
          type filter hook forward priority 0; policy accept;
        }

        chain output {
          type filter hook output priority 0; policy accept;
        }
      }

      table ip mangle {
        chain prerouting {
          type filter hook prerouting priority mangle; policy accept;

          # TPROXY: перенаправление трафика с awg0 на xray dokodemo-door
          iifname "awg0" meta l4proto tcp tproxy to 127.0.0.1:12345 meta mark set 1
          iifname "awg0" meta l4proto udp tproxy to 127.0.0.1:12345 meta mark set 1
        }
      }

      table ip route {
        chain output {
          type route hook output priority mangle; policy accept;

          # Маркированные пакеты (от xray direct) идут напрямую
          meta mark 255 accept
        }
      }
    '';
  };

  # ip rule для TPROXY
  networking.localCommands = ''
    ip rule add fwmark 1 table 100 2>/dev/null || true
    ip route add local 0.0.0.0/0 dev lo table 100 2>/dev/null || true
  '';
}
