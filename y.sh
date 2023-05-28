#!/bin/bash

# 检测发行版
if [ -f /etc/debian_version ]; then
os_release=”debian”
elif [ -f /etc/centos-release ]; then
os_release=”centos”
elif [ -f /etc/lsb-release ]; then
os_release=”ubuntu”
else
echo “Unsupported distribution!”
exit 1
fi

# 更新系统
case $os_release in
debian|ubuntu)
apt update && apt upgrade -y
;;
centos)
yum update -y
;;
*)
echo “Unsupported distribution!”
exit 1
;;
esac

# 启用KSM
echo 1 > /sys/kernel/mm/ksm/run
echo 1000 > /sys/kernel/mm/ksm/sleep_millisecs

# 启用透明大页
echo always > /sys/kernel/mm/transparent_hugepage/enabled

# 禁用巨型页
echo never > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages

# 启用CPU超线程
echo on > /sys/devices/system/cpu/smt/control

# 启用嵌套虚拟化
echo “options kvm_intel nested=1” > /etc/modprobe.d/kvm_intel.conf
echo “options kvm_amd nested=1” > /etc/modprobe.d/kvm_amd.conf
rmmod kvm_intel kvm_amd
modprobe kvm_intel kvm_amd

# 优化虚拟机磁盘性能
echo “options virtio_blk add_host_latency_ns=0” > /etc/modprobe.d/virtio_blk.conf
rmmod virtio_blk
modprobe virtio_blk

# 修改I/O调度器
echo noop > /sys/block/sda/queue/scheduler

# 开启NUMA架构优化
if [[ “$(lscpu | grep -i numa)” ]]; then
case $os_release in
debian|ubuntu)
apt install -y numactl
;;
centos)
yum install -y numactl
;;
*)
echo “Unsupported distribution!”
exit 1
;;
esac
fi

# 升级内核到最新最稳定版本
case $os_release in
debian|ubuntu)
apt install -y linux-image-generic
;;
centos)
yum install -y kernel
;;
*)
echo “Unsupported distribution!”
exit 1
;;
esac

# 添加8GB的swap
fallocate -l 8G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo “/swapfile none swap sw 0 0” >> /etc/fstab

# 内核网络性能优化和高并发优化

#创建内核参数优化配置文件

cat <<EOF > /etc/sysctl.d/99-kvm-optimization.conf

# 启用IP转发

net.ipv4.ip_forward = 1

net.ipv6.conf.all.forwarding = 1

# TCP内存分配优化

net.core.wmem_max = 16777216

net.core.rmem_max = 16777216

net.ipv4.tcp_rmem = 4096 87380 16777216

net.ipv4.tcp_wmem = 4096 65536 16777216

# TCP连接跟踪优化

net.netfilter.nf_conntrack_max = 1000000

net.netfilter.nf_conntrack_tcp_timeout_established = 1200

# 启用TCP Fast Open

net.ipv4.tcp_fastopen = 3

# 调整TCP Keepalive设置 net.ipv4.tcp_keepalive_time = 1200

net.ipv4.tcp_keepalive_probes = 5

net.ipv4.tcp_keepalive_intvl = 15

# 禁用ICMP重定向

net.ipv4.conf.all.accept_redirects = 0

net.ipv4.conf.default.accept_redirects = 0

#禁用TCP慢启动

net.ipv4.tcp_slow_start_after_idle = 0

#开启TCP连接复用

net.ipv4.tcp_tw_reuse = 1

#提高系统文件描述符限制

fs.file-max = 100000

#调整内核参数以适应高并发场景

net.core.somaxconn = 65535

net.core.netdev_max_backlog = 65535

net.ipv4.tcp_max_syn_backlog = 65535

net.ipv4.tcp_syncookies = 1

#优化TCP性能

net.ipv4.tcp_tw_reuse = 1

net.ipv4.tcp_tw_recycle = 0

net.ipv4.tcp_fin_timeout = 30

net.ipv4.tcp_keepalive_time = 1200

net.ipv4.tcp_keepalive_probes = 5

net.ipv4.tcp_keepalive_intvl = 15

net.ipv4.tcp_rmem = 4096 87380 16777216

net.ipv4.tcp_wmem = 4096 65536 16777216

#优化UDP性能

net.ipv4.udp_rmem_min = 8192

net.ipv4.udp_wmem_min = 8192

#开启反向路径过滤

net.ipv4.conf.all.rp_filter = 1

net.ipv4.conf.default.rp_filter = 1

#防止网络攻击

net.ipv4.tcp_syncookies = 1

net.ipv4.tcp_max_syn_backlog = 20480

# 防止ICMP Flood攻击

net.ipv4.icmp_echo_ignore_broadcasts = 1

net.ipv4.icmp_ignore_bogus_error_responses = 1

net.ipv4.icmp_ratelimit = 1000

# 防止SYN Flood攻击

net.ipv4.tcp_syncookies = 1

net.ipv4.tcp_synack_retries = 2

net.ipv4.tcp_syn_retries = 5

# 调整TIME-WAIT套接字重用等待时间

net.ipv4.tcp_fin_timeout = 30

EOF

应用内核参数优化配置

sysctl –system

echo “KVM virtualization optimization completed. Please reboot the system for all changes to take effect.”

 

将此脚本保存为`kvm_optimization.sh`，然后使用root权限运行它：

chmod +x kvm_optimization.sh
sudo ./kvm_optimization.sh
