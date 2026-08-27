# Face unlock (Howdy) on the IR camera.
#
# This is here because the obvious thing is not available: there is no
# fingerprint reader on this unit and there cannot be one — see the note in
# hardware.nix for the evidence, so that question stays closed.
#
# The IR camera is real and works:
#   /dev/video2   "HP IR Camera"   GREY (8-bit greyscale) 640x480 @ 30fps
# That is exactly what Howdy consumes, and /dev/video2 is already nixpkgs'
# default for video.device_path, so only dark_threshold is overridden below.
# Partial overrides are safe despite services.howdy.settings being types.attrs:
# the module's generateSettings merges cfg.settings over its own hardcoded
# defaults per block, so setting one key keeps the rest. Verified — the
# generated config.ini still carries all 30 keys across all five sections.
#
# ── Scope: the greeter, the lock screen, sudo and polkit ────────────────────
#
# This covers every interactive authentication on the machine. `login` is the
# one to note: /etc/pam.d/sddm is nothing but `auth substack login`, so putting
# Howdy in the login stack is what puts it in the SDDM greeter — and in TTY
# logins as a side effect. Log in by pressing Enter on an empty password field;
# pam_howdy runs ahead of pam_unix and `sufficient` short-circuits the rest.
#
# TWO CONSEQUENCES, both accepted deliberately:
#
#   1. gnome-keyring does NOT prompt, and must not start. The theory said it
#      would: pam_gnome_keyring unlocks the keyring from the password PAM
#      captured into PAM_AUTHTOK, a face match supplies none, and `sufficient`
#      short-circuits the auth stack before that module is reached anyway.
#      Verified in practice on this machine — face login at the SDDM greeter
#      produces no keyring prompt at all. That is the required behaviour, not a
#      lucky accident to be tolerated: if a keyring prompt ever starts appearing
#      after a face login, treat it as a regression. `login.howdy.enable` below
#      is the line to remove if it comes to that.
#
#   2. Cold boot is no longer something you know. Face unlock is now the first
#      and only gate after the LUKS passphrase, and Howdy's own manual says a
#      well-printed photo defeats it. This host carries the vCD token, the
#      kubeconfig and Terraform state and leaves the building (see the LUKS
#      assertion in default.nix). The LUKS passphrase is still the thing
#      protecting the disk at rest; this only affects a running, locked machine.
#
# nixpkgs defaults EVERY pam service's howdy.enable to security.pam.howdy.enable,
# which in turn defaults to services.howdy.enable. Setting the global to false
# flips the module from opt-out to opt-in, so the stacks below are exhaustive —
# nothing else picks up pam_howdy implicitly.
{ ... }:
{
  services.howdy = {
    enable = true;

    # The module defaults to "required", which means face AND password — a
    # second factor. We want face OR password, i.e. a convenience. Being
    # `sufficient` also means a failed or timed-out match can never lock you
    # out: it just falls through to pam_unix as usual.
    control = "sufficient";

    # The IR emitter works and needs no help — do not re-add
    # services.linux-enable-ir-emitter, and do not answer "No" to its
    # "Is the ir emitter flashing?" prompt to force a sweep. It genuinely flashes.
    #
    # What fooled a first look here: the camera STROBES the emitter, lighting only
    # every second frame. Measured off /dev/video2, per-frame mean brightness:
    #
    #     frame   0     1     2     3     4     5     6     7     8     9
    #     mean   1.0  65.8   1.0  65.8   0.9  41.7   0.8  41.4   0.8  33.3
    #
    # so any single grab has a 50% chance of reading ~1/255 and looking like dead
    # hardware. It is not. Howdy already knows to skip the dark half.
    #
    # dark_threshold is a CEILING on a darkness metric, not a floor on
    # brightness: higher means darker, and a frame is rejected when its measured
    # darkness reaches the threshold. Getting this backwards costs a rebuild —
    # measured here, both directions rejected:
    #
    #     threshold 60  ->  darkness 83.8  ->  rejected
    #     threshold 20  ->  darkness 81.3  ->  rejected   (stricter, not looser)
    #
    # This camera reports ~81-84 on a frame that plainly shows a face, because
    # the metric is essentially "how much of the image is dark" and an IR shot is
    # a lit face on a black background: the sampled lit frame had a median pixel
    # value of 7 with p95 at 135. That is normal for this sensor, not a fault,
    # and no exposure or gain control exists to change it (V4L2 offers only
    # region_of_interest and a read-only privacy bool).
    #
    # 90 passes the ~81-84 the lit frames actually report while still rejecting
    # the strobe's dark half, which sits near 100. If matching gets flaky, tune
    # `certainty` (3.5 default, lower is more permissive) — not this.
    settings.video.dark_threshold = 90;
  };

  security.pam.howdy.enable = false;

  security.pam.services = {
    sudo.howdy.enable = true;
    kde.howdy.enable = true; # kscreenlocker, i.e. the Plasma lock screen
    login.howdy.enable = true; # SDDM greeter (substacks login) and TTY logins
    polkit-1.howdy.enable = true; # Plasma's authentication dialogs
  };

  # Note on the lock screen: pam_howdy sits ahead of pam_unix in the stack, so
  # submitting a typed password can wait out Howdy's video.timeout (4s default)
  # before pam_unix ever sees it. If that gets annoying, lower the timeout by
  # overriding the whole `video` block in services.howdy.settings — see the
  # types.attrs caveat above — or drop kde from the list and keep sudo only.
}
