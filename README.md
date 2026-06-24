# pi-block-cpu-cores

Routes hardware interrupts (IRQs) to CPU core 0, isolating cores 1–3 for real-time workloads on Raspberry Pi. Designed for use with [picam-rtsp](../picam-rtsp).

## How it works

The service writes `0x1` (core 0 only) to `/proc/irq/*/smp_affinity` for every moveable IRQ at boot, then sets the default affinity so new IRQs created later also land on core 0. This keeps interrupt handling off the isolated cores so real-time tasks run with minimal jitter.

## Installation

### From `.deb` package

```bash
sudo dpkg -i pi-block-cpu-cores_*.deb
```

The post-install script enables and starts the `irq-affinity` systemd service automatically.

### Complete CPU isolation (required for full effect)

Add the following to `/boot/firmware/cmdline.txt` (all on one line):

```
isolcpus=1,2,3 nohz_full=1,2,3 rcu_nocbs=1,2,3 irqaffinity=0
```

Then reboot. Without these kernel parameters the OS scheduler may still place threads on cores 1–3.

## Building the package

```bash
dpkg-buildpackage -us -uc -b
```

The built `.deb` will appear in the parent directory.

## Service management

```bash
# Check status
systemctl status irq-affinity

# View logs
journalctl -u irq-affinity
```

## License

MIT — see [debian/copyright](debian/copyright).
