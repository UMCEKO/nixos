# gnome-keyring is the Secret Service for both sessions (secrets migrated from
# CachyOS's login.keyring). kwallet-pam disabled so ksecretd doesn't race it
# for org.freedesktop.secrets. pam unlocks it with the SDDM login password.
{ lib, ... }:
{
  services.gnome.gnome-keyring.enable = true;

  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.login.kwallet.enable = lib.mkForce false;
}
