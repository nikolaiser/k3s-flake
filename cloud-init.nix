{
  services.cloud-init = {
    enable = true;
    network.enable = true;

    config = ''
      system_info:
        distro: nixos
        network:
          renderers: [ 'networkd' ]
        default_user:
          name: ops

      users:
          - default

      ssh_pwauth: false

      chpasswd:
        expire: false

      preserve_hostname: false
      create_hostname_file: true

      cloud_init_modules:
        - migrator
        - seed_random
        - growpart
        - resizefs
        - set_hostname
        - update-hostname
      cloud_config_modules:
        - disk_setup
        - mounts
        - set-passwords
        - ssh
      cloud_final_modules: []
    '';
  };
}
