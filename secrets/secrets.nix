let
  # SSH ключ пользователя для шифрования секретов
  admin = "ssh-ed25519 AAAAC3... admin@workstation";
  # SSH host key сервера
  server = "ssh-ed25519 AAAAC3... root@yc-nixos";
  allKeys = [ admin server ];
in
{
  "xray-upstream.age".publicKeys = allKeys;
  "amneziawg-private.age".publicKeys = allKeys;
  "mtproto-secret.age".publicKeys = allKeys;
}
