# Strict DNS-over-TLS, pinned to Cloudflare.
#
# This deliberately reverses the roaming compromise that bc9f663 introduced and
# that 2736c25 left in place for this host. Read that reasoning before undoing
# this: the reason the EliteBook kept `opportunistic` is that it leaves the
# building, and strict DoT fails shut by design, so on a captive-portal network
# the portal's own hostname will not resolve and you cannot log in to get online
# at all. That cost is accepted here, knowingly, rather than overlooked.
#
# The escape hatch is manual, on purpose -- no helper is installed. On a network
# that demands a portal login:
#
#   link=$(ip route | awk '/^default/{print $5; exit}')
#   resolvectl dns "$link" "$(ip route | awk '/^default/{print $3; exit}')"
#   resolvectl dnsovertls "$link" no
#   ...complete the portal login...
#   resolvectl revert "$link"        # back to fail-shut DoT
#
# `resolvectl revert` also happens implicitly when the link is brought back up,
# so the cleartext window does not survive a reconnect or a reboot.
#
# Why strict and not opportunistic: opportunistic is not a weaker DoT, it is no
# DoT. It falls back to cleartext without complaint, so a network that strips
# :853 reads every query anyway and the config above becomes decoration. Strict
# is the only setting that actually keeps the operator out of your DNS.
#
# Verified 2026-09-15 on this line (TT, gateway 192.168.1.1): 1.1.1.1, 1.0.0.1
# and 9.9.9.9 all answer on :853, TLS1.3, CA- and hostname-validated under
# `kdig +tls +tls-ca +tls-hostname=...`. Unlike the desktop's router, this one
# does not refuse :853 -- but nothing here depends on that, since the link is
# taken out of the resolver path below regardless.
{ ... }:
{
  services.resolved.settings.Resolve = {
    # Cert names are not decoration: without them strict DoT validates the chain
    # but not *who* presented it, so a resolver on the path can answer with any
    # CA-signed cert it holds. The `#name` form is what makes the hostname checked.
    DNS = [
      "1.1.1.1#cloudflare-dns.com"
      "1.0.0.1#cloudflare-dns.com"
    ];
    DNSOverTLS = "true"; # strict; "opportunistic" would silently downgrade

    # Only consulted when no DNS= is configured at all, so in practice this never
    # fires. Kept cert-named anyway so it cannot become the one cleartext path if
    # the list above is ever emptied. Matches the desktop.
    FallbackDNS = [ "9.9.9.9#dns.quad9.net" ];
  };

  # Required, not optional. A link scope that offers servers beats the global
  # one, so while wlp195s0 carries the DHCP resolver every query goes there in
  # cleartext and none of the above is reached. No profile on this host pins
  # ipv4.dns by hand (checked 2026-09-15), so setting the defaults is enough --
  # there is nothing to clear imperatively the way there was on the desktop.
  networking.networkmanager.connectionConfig = {
    "ipv4.ignore-auto-dns" = true;
    "ipv6.ignore-auto-dns" = true;
  };
}
