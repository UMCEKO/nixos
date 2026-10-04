# DPI bypass, roaming variant.
#
# hosts/desktop/zapret.nix carries the same strategy but is NOT importable here,
# and the difference is one parameter. That file pins `--dpi-desync-ttl=5`, which
# is not a tuning knob so much as a measurement: it encodes the hop count from
# the desktop's position on the 192.168.0.1 line to TT's DPI (hop1 router, hop2
# BNG), chosen so the fake packet lands past the DPI and dies before the real
# server. This machine is on a different router (192.168.1.1) and by design does
# not stay on either, so a hardcoded hop count is wrong here by construction.
#
# `--dpi-desync-autottl` measures instead of assuming: nfqws estimates the
# distance to the server from the TTL of its inbound packets and sets the fake's
# TTL to distance-1, so it still expires one hop short of the server wherever
# that server happens to be. Same intent as the desktop's 5, re-derived per
# connection instead of baked in.
#
# Why this matters more than it did for DNS: strict DoT fails SHUT, so a wrong
# setting announces itself immediately. A mistuned TTL fails OPEN and silent --
# it breaks sites that were working and gives no hint why. That is what happened
# to sahibinden/hepsiburada in 2026-07.
#
# UNVERIFIED on this line as of 2026-09-15. `fake,disorder2` + `md5sig` is
# inherited from the desktop's line, not measured on this one, and TT's DPI is
# not guaranteed identical at both connections. Confirm with:
#
#   nix-shell -p iptables zapret --command blockcheck
#
# If a site breaks on some network, the blast radius knob is `whitelist` -- it
# restricts the bypass to the domains listed and leaves everything else
# untouched, which is the safer shape for a host that lands on strange networks.
# Left empty (bypass all) to match the desktop; narrow it if this misbehaves.
{ ... }:
{
  services.zapret = {
    enable = true;

    params = [
      "--dpi-desync=fake,disorder2"
      "--dpi-desync-fooling=md5sig"
      # Upstream's default for this flag, written out rather than left implicit:
      # delta -1 (one hop short of the server), clamped to 3-20 hops so a bad
      # estimate cannot produce a TTL that dies on the LAN or overshoots.
      "--dpi-desync-autottl=-1:3-20"
    ];

    # QUIC (UDP 443) deliberately unhandled, same as the desktop: enabling it
    # needs --dpi-desync-any-protocol, which also changes how TCP is treated,
    # and one nfqws serves both. Blocked sites over QUIC fail and the browser
    # falls back to TCP, which IS bypassed -- costs a round trip, breaks nothing.
    udpSupport = false;
  };
}
