# nginx reverse proxy for your *.umceko.com dev hosts (ported from old /etc/nginx/nginx.conf).
# NOTE: these vhosts assume *.umceko.com resolves to this machine (public DNS wildcard or
# /etc/hosts). Backends are your local dev servers on the listed ports.
{ ... }:
let
  # helper: websocket-capable proxy to a local port
  proxy = port: {
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      proxyWebsockets = true;
    };
    extraConfig = "proxy_read_timeout 86400s;";
  };
in
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;   # sets Host + X-Forwarded-* + HTTP/1.1
    recommendedOptimisation = true;
    clientMaxBodySize = "20M";         # global default (matched your old config)

    virtualHosts = {
      "dev.umceko.com"       = proxy 3000;
      "frontend.umceko.com"  = proxy 3000;
      "backend.umceko.com"   = proxy 3001;
      "test.umceko.com"      = proxy 3001;
      "gateway.umceko.com"   = proxy 3002;
      "kabinet.umceko.com"   = proxy 3100;
      "browser.umceko.com"   = proxy 6901;
      "cadrantech.umceko.com" = proxy 8080;
      # a1111 (stable-diffusion) needs a bigger upload limit
      "a1111.umceko.com" = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:7860";
          proxyWebsockets = true;
        };
        extraConfig = ''
          proxy_read_timeout 86400s;
          client_max_body_size 100M;
        '';
      };
      # default: 404 for unknown hosts
      "_" = {
        default = true;
        locations."/".return = "404";
      };
    };
  };

  # Firewall stays ON (your choice) — open HTTP for the reverse proxy.
  networking.firewall.allowedTCPPorts = [ 80 ];
}
