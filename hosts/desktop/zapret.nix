# DPI bypass. Moved off the ASUS router on 2026-08-20.
#
# It ran on the router (whole-LAN) from 2026-07-16 until nfqws v72.12 there
# started intermittently HANGING: it stopped draining NFQUEUE 200, so packets
# were held rather than dropped and every new TCP connection to :80/:443 from
# any LAN device stalled ~2min, while ICMP/DNS/SSH stayed perfectly fine.
# Six episodes captured over four days; evidence in ~/net-diag.
#
# nixpkgs ships 72.13, and this module already carries the mitigation for
# exactly that failure mode -- see the upstream unit: Restart="always" plus
# RuntimeMaxSec="1h", commented "This service loves to crash silently or cause
# network slowdowns."
#
# SCOPE CHANGE, deliberate: this protects THIS machine only. Phones, the TV and
# the Arch build box no longer get the bypass. Put it back on the router (or a
# future OpenWrt gateway) if whole-LAN coverage is wanted again.
#
# NOT in modules/common.nix on purpose: a fixed-TTL fake tuned for this TT line
# is wrong on any other network -- a mistuned TTL is what broke
# sahibinden/hepsiburada in 2026-07.
#
# The roaming EliteBook does run the bypass now (hosts/elitebook/zapret.nix,
# 2026-09-15), which is why this still cannot move into common.nix: it differs
# in exactly one parameter, measuring the hop count with --dpi-desync-autottl
# instead of hardcoding the 5 below. Keep the strategy flags in sync between the
# two files. Do NOT sync the TTL -- that number is specific to this line.
{ ... }:
{
  services.zapret = {
    enable = true;

    # No fake/disorder2: api.pttavm.com's origin RSTs any ClientHello that uses them.
    params = [
      # multidisorder alone lost ~1 in 5 to webshare.io on some routes; fake+md5sig went 20/20 (2026-10-02).
      "--filter-tcp=80,443"
      "--hostlist-domains=webshare.io"
      "--dpi-desync=fake,multidisorder"
      "--dpi-desync-split-pos=1,midsld"
      "--dpi-desync-fooling=md5sig"
      "--new"
      "--dpi-desync=multidisorder"
      "--dpi-desync-split-pos=1,midsld"
    ];

    # QUIC (UDP 443) is deliberately NOT handled here, unlike the router config.
    # Enabling it needs --dpi-desync-any-protocol, which would also change how
    # TCP is treated, and this module runs one nfqws for both. Blocked sites
    # over QUIC simply fail and the browser falls back to TCP, which IS
    # bypassed -- costs a round trip, breaks nothing.
  };
}
