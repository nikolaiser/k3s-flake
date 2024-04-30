{ pkgs, lib, conf, ... }:

let
  bgpConfig = pkgs.writeText "${conf.nodeIp}.conf" ''
    log syslog informational
    !ipv6 forwarding
    !service integrated-vtysh-config
    !
    !
    router bgp ${conf.bgpAs}
     bgp ebgp-requires-policy
     bgp router-id ${conf.nodeIp}
     neighbor V4 peer-group
     neighbor V4 remote-as ${conf.remoteBgpAs}
     neighbor ${conf.bgpRemoteIp} peer-group V4
     !
     address-family ipv4 unicast
      redistribute connected
      neighbor V4 route-map IMPORT in
      neighbor V4 route-map EXPORT out
     exit-address-family
     !
    route-map EXPORT deny 100
    !
    route-map EXPORT permit 1
     match interface lo
     set origin igp
    !
    route-map IMPORT deny 1
    !
    line vty
    !
  '';

  makeServers = port: lib.lists.imap1 (i: ip: "server server-${toString i} ${ip}:${port} check\n") conf.targetServers;

  backends = builtins.map
    (port: ''
      backend target-${port}
        mode tcp
        option tcp-check
        balance roundrobin
        default-server inter 10s downinter 5s
        ${lib.concatStrings (makeServers port)} 

    '')
    conf.targetPorts;

  frontends = builtins.map
    (port: ''
      frontend target-${port}
        bind *:${port}
        mode tcp
        option tcplog
        default_backend traefik-ui 

    '')
    conf.targetPorts;

  haproxyConfig = "${frontends}${backends}";
in
{
  services.haproxy = {
    enable = true;
    config = haproxyConfig;
  };

  services.frr.bgp = {
    enable = true;
    configFile = bgpConfig;
  };

  networking.interfaces."lo".ipv4.addresses = [
    { address = conf.floatingIp; prefixLength = 32; }
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      197 # BGP
    ] ++ builtins.map lib.strings.toInt conf.targetPorts;
  };



}

