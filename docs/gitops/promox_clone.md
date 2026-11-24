qm stop 6010; qm destroy 6010 --purge
qm clone 9999 6010 --name proxy --full 1 --storage nvmepool
qm set 6010 --net0 virtio,bridge=vmbr0,tag=66,firewall=1 --ipconfig0 ip=172.16.66.10/24,gw=172.16.66.1
qm start 6010
