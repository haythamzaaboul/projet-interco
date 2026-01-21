#!/bin/bash
set -e

### Interface
ip link set dev enp1s0f0 up

### Adresse IP
ip a a 120.0.66.8/24 dev enp1s0f0 || true

### Route par défaut vers le routeur 9
ip route add default via 120.0.66.1
