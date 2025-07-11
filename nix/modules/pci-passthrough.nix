let 
  # gpuIDs = [
  #   "10de:2704" # Graphics
  #   "10de:22bb" # Audio
  # ];
  gpuIDs = [
    "10de:2bb1" # Graphics
    "10de:22e8" # Audio
  ];
in { pkgs, lib, config, ... }: {
  boot = {
    initrd.kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"

      # "nvidia"
      # "nvidia_modeset"
      # "nvidia_uvm"
      # "nvidia_drm"
    ];

    kernelParams = [
      "intel_iommu=on"
      ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs)
    ];
     
  };
}