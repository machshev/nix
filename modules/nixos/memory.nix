{
  config,
  lib,
  ...
}:
with lib; {
  options = {
    machshev.memoryTuning = mkOption {
      type = types.bool;
      default = true;
      description = "Tune reclaim and writeback to avoid latency collapse under memory pressure.";
    };
  };

  config = mkIf config.machshev.memoryTuning {
    # zswap keeps a compressed pool in RAM in front of the real swap device.
    # Most swap traffic is served from it and never reaches the disk, which
    # matters here because swap sits behind dm-crypt (randomEncryption) on the
    # same NVMe as the filesystem, so every swapped page costs an encrypt plus
    # a queue slot that the filesystem is also competing for.
    boot.kernelParams = [
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.zpool=zsmalloc"
      "zswap.max_pool_percent=20"
    ];

    boot.kernel.sysctl = {
      # Reclaim cold page cache before anonymous memory. The default of 60
      # treats them as near-equals, so a large read-once cache (a build, a
      # repo scan) can push live process memory out to swap.
      "vm.swappiness" = 10;

      # kswapd's headroom, in units of 0.01% of RAM. The default of 10 is
      # 0.1%, which on a 32GB machine is ~30MB, far too little to absorb a
      # burst: allocations outrun kswapd and fall into *direct* reclaim, where
      # each one stalls synchronously inside the page fault. 200 gives ~2%
      # (~600MB) so reclaim stays in the background where it belongs.
      "vm.watermark_scale_factor" = 200;

      # Cap dirty pages by absolute size rather than by ratio. The default
      # ratios (20%/10%) scale with RAM, so on 32GB they permit ~6GB dirty
      # before throttling and ~3GB before writeback even starts. Flushing a
      # backlog that size through dm-crypt stalls every other reader on the
      # device. Setting the _bytes form zeroes the corresponding _ratio.
      "vm.dirty_background_bytes" = 256 * 1024 * 1024;
      "vm.dirty_bytes" = 1024 * 1024 * 1024;

      # Read one page per swap-in fault instead of eight. Readahead is a poor
      # trade when each page has to be decrypted and the access pattern into
      # swap is essentially random.
      "vm.page-cluster" = 0;
    };
  };
}
