# gnome-keyring is the Secret Service for both sessions (secrets migrated from
# CachyOS's login.keyring). kwallet-pam disabled so ksecretd doesn't race it
# for org.freedesktop.secrets. pam unlocks it with the SDDM login password
# (/etc/pam.d/sddm is `substack login`, so the login stack below covers SDDM).
{ lib, ... }:
{
  services.gnome.gnome-keyring.enable = true;

  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.login.kwallet.enable = lib.mkForce false;

  # plasma6 defines a second stack, `kde` (used by the screen unlocker), which
  # ships its own pam_kwallet5. Without this it keeps unlocking — and creating —
  # a wallet that nothing is supposed to be using any more, which is how
  # ksecretd stays alive to race gnome-keyring for org.freedesktop.secrets.
  security.pam.services.kde.kwallet.enable = lib.mkForce false;

  # ── Why the browsers logged you out on every session switch ──────────────
  # Chromium picks its password-store backend from XDG_CURRENT_DESKTOP at
  # startup, NOT from whoever owns org.freedesktop.secrets:
  #
  #   XDG_CURRENT_DESKTOP=KDE       -> kwallet backend, talks to kwalletd6
  #                                    directly over org.kde.kwalletd6
  #   XDG_CURRENT_DESKTOP=Hyprland  -> "OTHER" desktop -> `basic` backend,
  #                                    key obfuscated in plaintext in Local State
  #
  # So the AES key that encrypts the cookie jar ("Brave Safe Storage") was
  # written to KWallet under Plasma and to Local State under Hyprland. Each
  # session found no key where it looked, minted a fresh one, and every cookie
  # encrypted under the other key became undecryptable -> signed out of
  # everything. Pointing the Secret portal at gnome-keyring (modules/desktop.nix)
  # does not help, because this code path never goes through the portal.
  #
  # Pinning the backend explicitly makes both sessions read the same key out of
  # gnome-keyring, which is already running and pam-unlocked in both.
  nixpkgs.overlays = [
    (final: prev:
      let
        pinPasswordStore = pkg:
          pkg.override { commandLineArgs = "--password-store=gnome-libsecret"; };
      in
      {
        brave = pinPasswordStore prev.brave;
        google-chrome = pinPasswordStore prev.google-chrome;
        chromium = pinPasswordStore prev.chromium;
      })
  ];
}
