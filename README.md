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

### From the APT repository

CI publishes to a signed APT repository (shared with other aipicam Raspberry Pi packages) hosted on Cloudflare R2, with two channels:

- **`main`** — pushing a `v*` tag publishes the clean release version here.
- **`nightly`** — every push (to any branch, and PRs) publishes a dev build here, versioned with a `+git<shortsha>` suffix.

Add the repo and its signing key, then install normally:

```bash
curl -fsSL https://apt.aipicam.com/pubkey.asc | sudo gpg --dearmor -o /usr/share/keyrings/aipicam.gpg

# stable releases
echo "deb [signed-by=/usr/share/keyrings/aipicam.gpg] https://apt.aipicam.com main main" | sudo tee /etc/apt/sources.list.d/aipicam.list

# or nightly builds instead
echo "deb [signed-by=/usr/share/keyrings/aipicam.gpg] https://apt.aipicam.com nightly main" | sudo tee /etc/apt/sources.list.d/aipicam.list

sudo apt-get update
sudo apt-get install pi-block-cpu-cores
```

#### CI setup

The `build.yml` workflow needs these repository secrets:

| Secret | Purpose |
| --- | --- |
| `R2_ACCOUNT_ID` | Cloudflare account ID (used to build the R2 S3 endpoint URL) |
| `R2_ACCESS_KEY_ID` | R2 API token access key ID |
| `R2_SECRET_ACCESS_KEY` | R2 API token secret access key |
| `GPG_PRIVATE_KEY` | ASCII-armored, **passphrase-less** private key used to sign the repo (`gpg --export-secret-keys --armor <key-id>`) |
| `GPG_KEY_ID` | Full fingerprint of that key |

To generate a dedicated signing key:

```bash
gpg --batch --passphrase '' --quick-generate-key "pi-block-cpu-cores repo signing <you@example.com>" rsa4096 sign never
gpg --export-secret-keys --armor <key-id>   # -> GPG_PRIVATE_KEY secret
```

The workflow exports the matching public key to `pubkey.asc` at the bucket root on every run, so it stays in sync automatically (including after key rotation) — no manual upload needed.

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
