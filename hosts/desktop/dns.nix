# Strict DNS-over-TLS.
#
# Desktop-only, deliberately. This box sits on one fixed TT line, so pinning
# public resolvers is safe here; on the roaming EliteBook it is not, because a
# captive portal has to be able to answer before you have logged in. That is
# what bc9f663 ("opportunistic DoT so roaming links can resolve") was about --
# the mistake was applying the roaming compromise to this machine too.
#
# Opportunistic is not a weaker DoT, it is no DoT: it silently falls back to
# cleartext, so an ISP that strips :853 gets your queries anyway. Strict is the
# only setting that actually keeps TT out of your DNS. It fails shut by design.
#
# Verified 2026-09-04: 1.1.1.1/9.9.9.9/8.8.8.8 all answer on :853 from this
# line, TLS1.3, CA-validated (`kdig +tls +tls-ca`). The router does NOT -- it
# refuses :853 outright, which is why it cannot stay in the path below.
{ ... }:
{
  services.resolved.settings.Resolve = {
    DNS = [
      "1.1.1.1#cloudflare-dns.com"
      "1.0.0.1#cloudflare-dns.com"
      "9.9.9.9#dns.quad9.net"
      "149.112.112.112#dns.quad9.net"
    ];
    DNSOverTLS = "true";
    FallbackDNS = [ "9.9.9.9#dns.quad9.net" ];
  };

  # A link scope with servers beats the global one, so eno1 must offer none at
  # all -- otherwise every query goes to 192.168.0.1 in cleartext and the DoT
  # config above is decoration. The hand-pinned ipv4.dns is cleared alongside this.
  networking.networkmanager.connectionConfig = {
    "ipv4.ignore-auto-dns" = true;
    "ipv6.ignore-auto-dns" = true;
  };
}
