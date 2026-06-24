#!/bin/sh
# set-irq-affinity.sh
# Routes all hardware IRQs to CPU core 0, keeping cores 1-3 free
# for real-time tasks.
#
# Called by irq-affinity.service at boot, before picam-rtsp starts.
# Runs continuously: applies affinity once at startup, then sleeps
# indefinitely so systemd tracks it as an active simple service.
#
# smp_affinity is a hex bitmask of cores:
#   core 0 only  = 0x1
#   cores 0+1    = 0x3
#   all 4 cores  = 0xf

CORE0_MASK="1"

apply_affinity() {
    routed=0
    skipped=0

    for affinity_file in /proc/irq/*/smp_affinity; do
        # Extract IRQ number from path
        irq=$(echo "$affinity_file" | grep -o '[0-9]*')

        # Skip IRQ 0 (timer) — kernel manages this
        [ "$irq" = "0" ] && continue

        if echo "$CORE0_MASK" > "$affinity_file" 2>/dev/null; then
            routed=$((routed + 1))
        else
            skipped=$((skipped + 1))
        fi
    done

    echo "IRQ affinity: routed $routed IRQs to core 0, $skipped skipped (read-only)"

    # Also set the default affinity for any IRQs created after this runs
    echo "$CORE0_MASK" > /proc/irq/default_smp_affinity 2>/dev/null || true
}

apply_affinity

# Sleep indefinitely so the service stays active under systemd.
# The affinity settings persist in the kernel; this loop is just
# a placeholder to keep the process alive.
while true; do
    sleep 86400 &
    wait $!
done
