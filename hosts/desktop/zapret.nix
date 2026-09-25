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
# NOT in modules/common.nix on purpose: that is shared with the roaming
# EliteBook, and a fixed-TTL fake tuned for this TT line is wrong on any other
# network -- a mistuned TTL is what broke sahibinden/hepsiburada in 2026-07.
{ ... }:
{
  services.zapret = {
    enable = true;

    # No fake/disorder2: api.pttavm.com's origin RSTs any ClientHello that uses them.
    params = [
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
