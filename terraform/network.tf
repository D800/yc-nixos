resource "yandex_vpc_network" "main" {
  name = "yc-nixos-network"
}

resource "yandex_vpc_subnet" "main" {
  name           = "yc-nixos-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}

resource "yandex_vpc_security_group" "nixos" {
  name       = "yc-nixos-sg"
  network_id = yandex_vpc_network.main.id

  # SSH
  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # x3-ui admin panel
  ingress {
    protocol       = "TCP"
    port           = 2053
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # MTProto proxy
  ingress {
    protocol       = "TCP"
    port           = 8443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # AmneziaWG
  ingress {
    protocol       = "UDP"
    port           = 51820
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outgoing traffic
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
