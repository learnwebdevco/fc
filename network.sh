printf "step: remove tap device\n"
ip tuntap del tap0 mode tap
iptables -F
sh -c "echo 0 > /proc/sys/net/ipv4/ip_forward"

printf "step: create tap device\n"
ip tuntap add tap0 mode tap
ip addr add 172.16.0.1/24 dev tap0
ip link set tap0 up
sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i tap0 -o eth0 -j ACCEPT

printf "step: network interface\n"
curl --unix-socket /tmp/firecracker.socket -i \
  -X PUT "http://localhost/network-interfaces/eth0" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{
    \"iface_id\": \"eth0\",
    \"guest_mac\": \"AA:FC:00:00:00:01\",
    \"host_dev_name\": \"tap0\"
  }"