let 
  gpuIDs = [
    "10de:2704" # Graphics
    "10de:22bb" # Audio
  ];
in { pkgs, lib, config, ... }: {
  boot = {
    initrd.kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
      "vfio_virqfd"

      # "nvidia"
      # "nvidia_modeset"
      # "nvidia_uvm"
      # "nvidia_drm"
    ];

    kernelParams = [
      "intel_iommu=on"
    ] ++ 
      # isolate the GPU
      ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs);
  };
}