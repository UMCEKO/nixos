# Keyring / Secret Service.
#
# Your real secrets came from Hyprland-on-CachyOS, which used gnome-keyring
# (~/.local/share/keyrings/login.keyring — migrated). So gnome-keyring is the
# Secret Service for BOTH sessions here:
#   - pam_gnome_keyring unlocks login.keyring with your SDDM login password
#     (works for whichever session you pick; no autologin, so a password exists).
#   - gnome-keyring-daemon claims org.freedesktop.secrets proactively at login,
#     which is more reliable than KDE's ksecretd (it waited and lost a startup
#     race, leaving a passwordless daemon owning the bus → the unlock prompts).
#
# plasma6 also wires pam_kwallet onto `login`; we disable it so kwallet's
# ksecretd doesn't race gnome-keyring for the bus. KDE Wallet Manager still
# opens manually if ever needed, but the shared Secret Service is gnome-keyring.
#
# Caveat: login.keyring decrypts with the password it was created under (your
# CachyOS login password). If that differs from your NixOS login password,
# gnome-keyring will prompt to unlock it once; matching the passwords (or the
# same password on both installs) makes it seamless.
{ lib, ... }:
{
  services.gnome.gnome-keyring.enable = true;

  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.login.kwallet.enable = lib.mkForce false;
}
