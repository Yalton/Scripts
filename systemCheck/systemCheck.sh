#!/bin/bash

echo "Performing System Checks"

echo "System Log Check:"
journalctl -p 0..3 -xn
echo "If you see any suspicious output above, investigate it further."

echo "Installing Memtest86+ for memory test:"
sudo apt-get install memtest86+ -y
echo "Memtest86+ installed. Please reboot your system and select Memtest86+ from the boot menu to perform memory tests."

echo "Installing smartmontools for disk check:"
sudo apt-get install smartmontools -y
echo "Running Disk Checks:"
for disk in $(lsblk -d -o name | tail -n +2); do
    echo "Checking /dev/$disk"
    sudo smartctl -a /dev/$disk
done

echo "Installing lm-sensors for temperature monitoring:"
sudo apt-get install lm-sensors -y
echo "Running Sensor-detect:"
sudo sensors-detect --auto
echo "Temperature Data:"
sensors

echo "Checks complete. Investigate any suspicious output."
