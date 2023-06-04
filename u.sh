cat >/home/jiasu_run.sh <<\EOF
#!/bin/bash
echo "KCP/SpeederV2/Udp2raw一键启动脚本[服务端]"
cd `dirname $0`

publish_ip="0.0.0.0" #服务端IP地址
publish_kcp=29900 #KCP对外端口
publish_udp2raw=6002 #UDP2RAW监听端口

local_proxy=8388 #加速的代理端口,如SSR的8388
local_speederv2=6001 #speederv2本地服务端口

param=$1
if [ ! -d "./pid" ];then
  mkdir ./pid
fi

pid_kcptun=./pid/kcptun_$0.pid
pid_speederv2=./pid/speederv2_$0.pid
pid_udp2raw=./pid/udp2raw_$0.pid

function pid_exists(){
  local exists=`ps aux | awk '{print $2}'| grep -w $1`
  if [[ ! $exists ]]
  then
    return 0;
  else
    return 1;
  fi
}

function pid_status(){
  if [[ -f $1 ]];then
    pid_exists `cat $1`
    if [[ $? == 1 ]];then
      echo -e "\t $2: \033[32m运行中\033[0m"
    else
      echo -e "\t $2: \033[31m已停止\033[0m"
    fi
  else
    echo -e "\t $2: \033[31m已停止\033[0m"
  fi
}


function stop(){
  local pid=`cat $1`
  kill -9 $pid
  pid_exists $pid
  if [[ $pid == 1 ]]
  then
    echo "停止任务失败"
  fi
}

function start(){
  ./kcptun/server_linux_amd64 -l $publish_ip:$publish_kcp -t 127.0.0.1:$local_proxy -key "eller" -mtu 1400 -sndwnd 2048 -rcvwnd 2048 -mode fast2 >/dev/null 2>&1 &
  pid=$!
  echo $pid >$pid_kcptun
  sleep 2
  pid_exists $pid
  if [ $? == 1 ];then
    echo -e "KCP \033[32m启动成功\033[0m，对接端口：$publish_ip:$publish_kcp"
    #echo "KCP 启动成功，对接端口：$remote_ip:$remote_kcp"
  else
    echo -e "KCP \033[33m启动失败\033[0m"
  fi

  ./speederv2/speederv2_amd64 -s -l127.0.0.1:$local_speederv2 -r127.0.0.1:$local_proxy -k "eller" -f20:40 --timeout 1 >/dev/null 2>&1 &
  pid=$!
  echo $pid >$pid_speederv2
  sleep 2
  pid_exists $pid
  if [ $? == 1 ];then
    echo -e "SpeedV2 \033[32m启动成功\033[0m"
  else
    echo -e "SpeedV2 \033[33m启动失败\033[0m"
  fi

  ./udp2raw-tunnel/udp2raw_amd64 -s -l$publish_ip:$publish_udp2raw -r 127.0.0.1:$local_speederv2 -a -k "eller" --raw-mode faketcp >/dev/null 2>&1 &
  pid=$!
  echo $pid >$pid_udp2raw
  sleep 2
  pid_exists $pid
  if [ $? == 1 ];then
    echo -e "UDP2RAW \033[32m启动成功\033[0m"
  else
    echo -e "UDP2RAW \033[33m启动失败\033[0m"
  fi
}

function stop_proces(){
  stop $pid_kcptun
  stop $pid_speederv2
  stop $pid_udp2raw
}

if [[ "start" == $param ]];then
  echo "即将：启动脚本";
  start
elif  [[ "stop" == $param ]];then
  echo "即将：停止脚本";
  stop_proces;
elif  [[ "restart" == $param ]];then
  stop_proces
  start
else
  echo "当前配置(如不正确，请编辑脚本进行修改)："
  echo -e "\t 服务端IP：$publish_ip"
  echo -e "\t 服务端KCP端口: $publish_kcp"
  echo -e "\t 服务端UDP2RAW端口: $publish_udp2raw"
  echo -e "\t 本地加速端口: $local_proxy"
  echo -e "\t 本地udp2raw端口：$local_speederv2"
  echo "服务状态："

  pid_status $pid_kcptun "KCP"
  pid_status $pid_speederv2 "speederv2"
  pid_status $pid_udp2raw "udp2raw"

  echo "使用方式：  "
  echo -e "\t运行服务：bash $0 start "
  echo -e "\t停止服务：bash $0 stop "
  echo -e "\t重启服务：bash $0 restart "
fi
EOF
 
