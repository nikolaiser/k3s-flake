{ conf, lib, ... }:

let
  isLeader = conf.leaderIp == conf.nodeIp;

  k3sFlags = "--flannel-backend=none --disable-kube-proxy --disable=traefik --disable=servicelb --disable=local-storage --disable-network-policy --egress-selector-mode=disabled --write-kubeconfig-mode 644";

  nodesTlsFlags = builtins.map (ip: "--tls-san ${ip} ") conf.allNodes;
  clusterIpTlsFlag = if builtins.hasAttr "clusterIp" conf then "--tls-san ${conf.clusterIp}" else "";
  tlsFlags = "${clusterIpTlsFlag} ${lib.concatStrings nodesTlsFlags}";

  flags = "--node-ip ${conf.nodeIp} --node-external-ip ${conf.nodeIp} ${k3sFlags} ${tlsFlags}";
in
{
  services.k3s = {
    enable = true;
    role = "server";
    token = conf.token;
    clusterInit = isLeader;
    serverAddr = if !isLeader then "https://${conf.leaderIp}:6443" else "";
    extraFlags = flags;

  };

  boot.kernelModules = [ "br_netfilter" "ip_conntrack" "ip_vs" "ip_vs_rr" "ip_vs_wrr" "ip_vs_sh" "overlay" "iptable_raw" "xt_socket" ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
  };

  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true;

  systemd.services.k3s.after = [ "network-online.service" "firewall.service" ];
  systemd.services.k3s.serviceConfig.KillMode = lib.mkForce "control-group";
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];

  services.openiscsi = {
    enable = true;
    name = "iqn.2000-05.edu.example.iscsi:${conf.hostname}";
  };


  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [
        6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
        2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
        2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
        10250
        197 # BGP
        3784 # BFD
      ];
      allowedUDPPorts = [
        51820
        51821
        8472
        3784 # BFD
      ];

      #extraCommands = ''
      #  iptables -A INPUT -i cni+ -j ACCEPT
      #'';
      trustedInterfaces = [ "cni+" ];
    };

    nameservers = [ "10.10.0.22" ];
  };

  systemd.network.enable = true;
  systemd.network.config = {
    networkConfig = {
      ManageForeignRoutes = false;
      ManageForeignRoutingPolicyRules = false;
    };
  };

  # cilium writes its own config to /etc/cni/net.d, so we need to make sure it's writable/empty/whatever
  environment.etc."cni/net.d".enable = false;
}
