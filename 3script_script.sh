#!/bin/sh
#copyright by hiboy
[ -f /tmp/script.lock ] && exit 0
touch /tmp/script.lock
### 创建子程序脚本【https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/3script_script.sh】
cat > "/tmp/sh_wifi_dog.sh" <<-\EEF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

IPT=/bin/iptables
WD_DIR="/usr/bin"
SVC_PATH=$WD_DIR/wifidog
if [ ! -f "$SVC_PATH" ] ; then
    WD_DIR="/opt/bin"
fi
#开关
wifidog_enable=`nvram get wifidog_enable`
wifidog_Daemon=`nvram get wifidog_Daemon`


#认证服务器
wifidog_Hostname=`nvram get wifidog_Hostname`
wifidog_HTTPPort=`nvram get wifidog_HTTPPort`
[ -z $wifidog_HTTPPort ] && wifidog_HTTPPort="80" && nvram set wifidog_HTTPPort=$wifidog_HTTPPort
wifidog_Path=`nvram get wifidog_Path`
[ -z $wifidog_Path ] && wifidog_Path="/" && nvram set wifidog_Path=$wifidog_Path

#高级设置
wifidog_id=`nvram get wifidog_id`
[ -z $wifidog_id ] && wifidog_id=$(/sbin/ifconfig br0  | sed -n '/HWaddr/ s/^.*HWaddr */HWADDR=/pg'  | awk -F"=" '{print $2}' |sed -n 's/://pg'| awk -F" " '{print $1}')  && nvram set wifidog_id=$wifidog_id
wifidog_lanif=`nvram get wifidog_lanif`
[ -z $wifidog_lanif ] && wifidog_lanif="br0" && nvram set wifidog_lanif=$wifidog_lanif
wifidog_wanif=`nvram get wifidog_wanif`
[ -z $wifidog_wanif ] && wifidog_wanif=$(nvram get wan0_ifname_t) && nvram set wifidog_wanif=$wifidog_wanif
wifidog_Port=`nvram get wifidog_Port`
[ -z $wifidog_Port ] && wifidog_Port="2060" && nvram set wifidog_Port=$wifidog_Port
wifidog_Interval=`nvram get wifidog_Interval`
[ -z $wifidog_Interval ] && wifidog_Interval="60" && nvram set wifidog_Interval=$wifidog_Interval
wifidog_Timeout=`nvram get wifidog_Timeout`
[ -z $wifidog_Timeout ] && wifidog_Timeout="5" && nvram set wifidog_Timeout=$wifidog_Timeout
wifidog_MaxConn=`nvram get wifidog_MaxConn`
[ -z $wifidog_MaxConn ] && wifidog_MaxConn="30" && nvram set wifidog_MaxConn=$wifidog_MaxConn
wifidog_MACList=`nvram get wifidog_MACList`
[ -z $wifidog_MACList ] && wifidog_MACList="00:00:DE:AD:BE:AF" && nvram set wifidog_MACList=$wifidog_MACList



start()
{
SVC_PATH=$WD_DIR/wifidog
if [ ! -f "$SVC_PATH" ] ; then
    SVC_PATH="/opt/bin/wifidog"
fi
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【Wifidog】" "自动安装 wifidog 程序"
    # 找不到 wifidog，安装 opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【Wifidog】" "找不到 $SVC_PATH 下载程序"
        wget --continue --no-check-certificate  -O  /opt/bin/wifidog "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/wifidog"
        chmod 755 "/opt/bin/wifidog"
        wget --continue --no-check-certificate  -O  /opt/bin/wdctl "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/wdctl"
        chmod 755 "/opt/bin/wdctl"
    else
        logger -t "【Wifidog】" "找到 $SVC_PATH"
    fi
    SVC_PATH=/opt/bin/wifidog
fi

[ ! -s "$SVC_PATH" ] && {  logger -t "【Wifidog】" "找不到 $SVC_PATH, 需要手动安装 $SVC_PATH"; }

{
rm -f /etc/storage/wifidog.conf  
# 将数值赋给WiFiDog官方的配置参数               
echo "
#WiFiDog 配置文件

#网关ID
GatewayID $wifidog_id

#内部网卡
GatewayInterface $wifidog_lanif

#外部网卡
ExternalInterface $wifidog_wanif 

#认证服务器
AuthServer {
Hostname $wifidog_Hostname
HTTPPort $wifidog_HTTPPort
Path $wifidog_Path
}

#守护进程
Daemon $wifidog_Daemon

#检查DNS状态(Check DNS health by querying IPs of these hosts)
PopularServers $wifidog_Hostname

#运行状态
HtmlMessageFile /www/wifidog-msg.html

#监听端口
GatewayPort $wifidog_Port

#心跳间隔时间
CheckInterval $wifidog_Interval

#心跳间隔次数
ClientTimeout $wifidog_Timeout

#HTTP最大连接数
HTTPDMaxConn $wifidog_MaxConn

#信任的MAC地址,加入信任列表将不用登录可访问
TrustedMACList $wifidog_MACList

#全局防火墙设置
FirewallRuleSet global {
FirewallRule allow tcp port 443
}

#新验证用户
FirewallRuleSet validating-users {
    FirewallRule allow to 0.0.0.0/0
}
#正常用户
FirewallRuleSet known-users {
    FirewallRule allow to 0.0.0.0/0
}

#未知用户
FirewallRuleSet unknown-users {
    FirewallRule allow udp port 53
    FirewallRule allow tcp port 53
    FirewallRule allow udp port 67
    FirewallRule allow tcp port 67
}

#锁住用户
FirewallRuleSet locked-users {
    FirewallRule block to 0.0.0.0/0
}
" >> /etc/storage/wifidog.conf
}
if [ "$wifidog_enable" = "1" ] ; then
    $WD_DIR/wifidog -c /etc/storage/wifidog.conf &
fi

    logger -t "【Wifidog】" "启动"
}

stop()
{
    logger -t "【Wifidog】" "关闭"
    echo "Stopping Wifidog ... "
    if $WD_DIR/wdctl status 2> /dev/null
    then
        if $WD_DIR/wdctl stop
        then
                echo "OK"
        else
                echo "FAILED:  wdctl stop exited with non 0 status"
        fi

    else
       echo "FAILED:  Wifidog was not running"
    fi
}

status()
{
    $WD_DIR/wdctl status
}

case "$1" in
  start)
    start
    ;;
  restart)
    stop
    sleep 2
    start
    ;;
  reload)
    stop
    sleep 2
    start
    ;;
  stop)
    stop
    ;;
  status)
    status
    ;;
  debug|test-module)
    ### Test ipt_mark with iptables
    test_ipt_mark () {
      IPTABLES_OK=$($IPT -A FORWARD -m mark --mark 2 -j ACCEPT 2>&1 | grep "No chain.target.match")
      if [ -z "$IPTABLES_OK" ] ; then
        $IPT -D FORWARD -m mark --mark 2 -j ACCEPT 2>&1
        echo 1
      else
        echo 0
      fi
    }
    ### Test ipt_mac with iptables
    test_ipt_mac () {
      IPTABLES_OK=$($IPT -A INPUT -m mac --mac-source 00:00:00:00:00:00 -j ACCEPT 2>&1 | grep "No chain.target.match")
      if [ -z "$IPTABLES_OK" ] ; then
        $IPT -D INPUT -m mac --mac-source 00:00:00:00:00:00 -j ACCEPT 2>&1
        echo 1
      else
        echo 0
      fi
    }

    ### Test ipt_REDIRECT with iptables
    test_ipt_REDIRECT () {
      IPTABLES_OK=$($IPT -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 2060 2>&1 | grep "No chain.target.match")
      if [ -z "$IPTABLES_OK" ] ; then
        $IPT -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 2060 2>&1
        echo 1
      else
        echo 0
      fi
    }

    ### Find a module on disk
    module_exists () {
    echo " Looking for a module on disk"
      EXIST=$(find /lib/modules/`uname -r` -name $1.*o 2>/dev/null)
      if [ -n "$EXIST" ] ; then
        echo 1
      else
        echo 0
      fi
    }

    ### Test if a module is in memory
    module_in_memory () {
      MODULE=$(lsmod | grep $1 | awk '{print $1}')
      if [ "$MODULE" = "$1" ] ; then
        echo 1
      else
        echo 0
      fi
    }

    echo "Testing for iptables modules"

    echo "  Testing ipt_mac"
    TEST_IPT_MAC=$(test_ipt_mac)
    if [ "$TEST_IPT_MAC" = "0" ] ; then
      echo "   iptables is not working with ipt_mac"
      echo "   Scanning disk for ipt_mac module"
      TEST_IPT_MAC_MODULE_EXISTS=$(module_exists "ipt_mac")
      if [ "$TEST_IPT_MAC_MODULE_EXISTS" = "0" ] ; then
        echo "   ipt_mac module is missing, please install it (kernel or module)"
        exit
      else
        echo "   ipt_mac module exists, trying to load"
        insmod ipt_mac > /dev/null
        TEST_IPT_MAC_MODULE_MEMORY=$(module_in_memory "ipt_mac")
        if [ "$TEST_IPT_MAC_MODULE_MEMORY" = "0" ] ; then
          echo "  Error: ipt_mac not loaded"
          exit
        else
          echo "  ipt_mac loaded sucessfully"
        fi
      fi
    else
      echo "   ipt_mac  module is working"
    fi

    echo "  Testing ipt_mark"
    TEST_IPT_MARK=$(test_ipt_mark)
    if [ "$TEST_IPT_MARK" = "0" ] ; then
      echo "   iptables is not working with ipt_mark"
      echo "   Scanning disk for ipt_mark module"
      TEST_IPT_MARK_MODULE_EXISTS=$(module_exists "ipt_mark")
      if [ "$TEST_IPT_MARK_MODULE_EXISTS" = "0" ] ; then
        echo "   iptables ipt_mark module missing, please install it (kernel or module)"
        exit
      else
        echo "   ipt_mark module exists, trying to load"
        insmod ipt_mark
        TEST_IPT_MARK_MODULE_MEMORY=$(module_in_memory "ipt_mark")
        if [ "$TEST_IPT_MARK_MODULE_MEMORY" = "0" ] ; then
          echo "   Error: ipt_mark not loaded"
          exit
        else
          echo "   ipt_mark loaded sucessfully"
        fi
      fi
      else
    echo "   ipt_mark module is working"
    fi

##TODO:  This will not test if required iptables userspace (iptables-mod-nat on Kamikaze) is installed
    echo "  Testing ipt_REDIRECT"
    TEST_IPT_MAC=$(test_ipt_REDIRECT)
    if [ "$TEST_IPT_MAC" = "0" ] ; then
      echo "   iptables is not working with ipt_REDIRECT"
      echo "   Scanning disk for ipt_REDIRECT module"
      TEST_IPT_MAC_MODULE_EXISTS=$(module_exists "ipt_REDIRECT")
      if [ "$TEST_IPT_MAC_MODULE_EXISTS" = "0" ] ; then
        echo "   ipt_REDIRECT module is missing, please install it (kernel or module)"
        exit
      else
        echo "   ipt_REDIRECT module exists, trying to load"
        insmod ipt_REDIRECT > /dev/null
        TEST_IPT_MAC_MODULE_MEMORY=$(module_in_memory "ipt_REDIRECT")
        if [ "$TEST_IPT_MAC_MODULE_MEMORY" = "0" ] ; then
          echo "  Error: ipt_REDIRECT not loaded"
          exit
        else
          echo "  ipt_REDIRECT loaded sucessfully"
        fi
      fi
    else
      echo "   ipt_REDIRECT  module is working"
    fi

    ;;

  *)
   echo "Usage: $0 {start|stop|restart|reload|status|test-module}"
A_restart=`nvram get wifidog_status`
B_restart="$wifidog_enable$wifidog_Daemon$wifidog_Hostname$wifidog_HTTPPort$wifidog_Path$wifidog_id$wifidog_lanif$wifidog_wanif$wifidog_Port$wifidog_Interval$wifidog_Timeout$wifidog_MaxConn$wifidog_MACList"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set wifidog_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi

if [ "$wifidog_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof wifidog`" ] && logger -t "【Wifidog】" "停止 wifidog"
$WD_DIR/wdctl stop
sleep 1
killall -9 wifidog wdctl
fi
if [ "$wifidog_enable" = "1" ] ; then
    port=$(iptables -t nat -L PREROUTING | grep 'Outgoing' | wc -l)
    if [ "$port" = 0 ] ; then
        logger -t "【Wifidog】" "检测:找不到 wifidog 转发规则, 重新添加"
        stop
        $WD_DIR/wdctl stop
        sleep 1
        killall -9 wifidog wdctl
        start
    fi
fi
if [ "$wifidog_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
$WD_DIR/wdctl stop
sleep 1
killall -9 wifidog wdctl
start
restart_dhcpd
fi
   exit 1
   ;;
esac
exit 0



EEF
chmod 777 "/tmp/sh_wifi_dog.sh"
cat > "/tmp/sh_tinyproxy.sh" <<-\EEF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
tinyproxy_port=`nvram get tinyproxy_port`
tinyproxy_enable=`nvram get tinyproxy_enable`
tinyproxy_path=`nvram get tinyproxy_path`
[ -z $tinyproxy_path ] && tinyproxy_path=`which tinyproxy` && nvram set tinyproxy_path=$tinyproxy_path
A_restart=`nvram get tinyproxy_status`
B_restart="$tinyproxy_enable$tinyproxy_path$tinyproxy_port$(cat /etc/storage/tinyproxy_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set tinyproxy_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$tinyproxy_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof tinyproxy`" ] && logger -t "【tinyproxy】" "停止 tinyproxy"
killall -9 tinyproxy tinyproxy_script.sh
fi
if [ "$tinyproxy_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
killall -9 tinyproxy tinyproxy_script.sh
SVC_PATH=$tinyproxy_path
if [ ! -f "$SVC_PATH" ] ; then
    SVC_PATH="/opt/bin/tinyproxy"
fi
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【tinyproxy】" "自动安装 tinyproxy 程序"
    # 找不到 tinyproxy，安装 opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【tinyproxy】" "找不到 $SVC_PATH 下载程序"
        wget --continue --no-check-certificate  -O  /opt/bin/tinyproxy "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/tinyproxy"
        chmod 755 "/opt/bin/tinyproxy"
    else
        logger -t "【tinyproxy】" "找到 $SVC_PATH"
    fi
    tinyproxy_path=`which tinyproxy` && nvram set tinyproxy_path=$tinyproxy_path
    SVC_PATH=$tinyproxy_path
fi

[ ! -s "$SVC_PATH" ] && {  logger -t "【tinyproxy】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; }

logger -t "【tinyproxy】" "运行 tinyproxy_script"
killall -9 tinyproxy tinyproxy_script.sh
$tinyproxy_path -c /etc/storage/tinyproxy_script.sh &
restart_dhcpd
sleep 3
[ ! -z "`pidof tinyproxy`" ] && logger -t "【tinyproxy】" "启动成功"
[ -z "`pidof tinyproxy`" ] && logger -t "【tinyproxy】" "启动失败, 注意检查端口是否有冲突,10秒后自动尝试重新启动" && sleep 10 && nvram set tinyproxy_status=00 && /tmp/sh_tinyproxy.sh &
fi
EEF
chmod 777 "/tmp/sh_tinyproxy.sh"
cat > "/tmp/sh_mproxy.sh" <<-\EEF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

mproxy_enable=`nvram get mproxy_enable`
mproxy_port=`nvram get mproxy_port`
A_restart=`nvram get mproxy_status`
B_restart="$mproxy_enable$mproxy_port$(cat /etc/storage/mproxy_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set mproxy_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$mproxy_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof mproxy`" ] && logger -t "【mproxy】" "停止 mproxy"
killall -9 mproxy mproxy_script.sh
fi
if [ "$mproxy_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
killall -9 mproxy mproxy_script.sh
SVC_PATH="/usr/sbin/mproxy"
if [ ! -f "$SVC_PATH" ] ; then
    SVC_PATH="/opt/bin/mproxy"
fi
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【mproxy】" "自动安装 mproxy 程序"
    # 找不到 mproxy，安装 opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【mproxy】" "找不到 $SVC_PATH 下载程序"
        wget --continue --no-check-certificate  -O  /opt/bin/mproxy "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/mproxy"
        chmod 755 "/opt/bin/mproxy"
    else
        logger -t "【mproxy】" "找到 $SVC_PATH"
    fi
fi

hash mproxy 2>/dev/null || {  logger -t "【mproxy】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; }

logger -t "【mproxy】" "运行 mproxy_script"
killall -9 mproxy mproxy_script.sh
/etc/storage/mproxy_script.sh &
restart_dhcpd
sleep 5
[ ! -z "`pidof mproxy`" ] && logger -t "【mproxy】" "启动成功"
[ -z "`pidof mproxy`" ] && logger -t "【mproxy】" "启动失败, 注意检查端口是否有冲突, 10秒后自动尝试重新启动" && sleep 10 && nvram set mproxy_status=00 && /tmp/sh_mproxy.sh &
fi
EEF
chmod 777 "/tmp/sh_mproxy.sh"
cat > "/tmp/sh_vpnproxy.sh" <<-\EEF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

vpnproxy_enable=`nvram get vpnproxy_enable`
vpnproxy_wan_port=`nvram get vpnproxy_wan_port`
[ -z $vpnproxy_wan_port ] && vpnproxy_wan_port="8888" && nvram set vpnproxy_wan_port=$vpnproxy_wan_port
vpnproxy_vpn_port=`nvram get vpnproxy_vpn_port`
[ -z $vpnproxy_vpn_port ] && vpnproxy_vpn_port="1194" && nvram set vpnproxy_vpn_port=$vpnproxy_vpn_port
A_restart=`nvram get vpnproxy_status`
B_restart="$vpnproxy_enable$vpnproxy_wan_port$vpnproxy_vpn_port"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set vpnproxy_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$vpnproxy_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof nvpproxy`" ] && logger -t "【vpnproxy】" "停止 vpnproxy"
killall -9 nvpproxy
fi
if [ "$vpnproxy_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
killall -9 nvpproxy
SVC_PATH="/opt/bin/nvpproxy"
hash nvpproxy 2>/dev/null || m -rf /opt/bin/nvpproxy
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【vpnproxy】" "自动安装 vpnproxy 程序"
    # 找不到 vpnproxy，安装 opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【vpnproxy】" "找不到 $SVC_PATH 下载程序"
        rm -rf /opt/bin/nvpproxy.tar.gz
        wget --continue --no-check-certificate  -O  /opt/bin/nvpproxy.tar.gz "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/nvpproxy.tar.gz"
        tar -xzvf /opt/bin/nvpproxy.tar.gz -C /opt/bin/
        if [ ! -s "/opt/bin/nvpproxy" ] ; then
            logger -t "【vpnproxy】" "解压不正常:/opt/bin/nvpproxy"
            logger -t "【vpnproxy】" "启动失败, 10秒后自动尝试重新启动" && sleep 10
            nvram set vpnproxy_status=00 && /tmp/sh_vpnproxy.sh &
            exit 1
        fi
        chmod 755 "/opt/bin/nvpproxy"
        rm -rf /opt/bin/nvpproxy.tar.gz
    else
        logger -t "【vpnproxy】" "找到 $SVC_PATH"
    fi
fi

hash nvpproxy 2>/dev/null || {  logger -t "【vpnproxy】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; }

logger -t "【vpnproxy】" "运行 $SVC_PATH"
killall -9 nvpproxy
start-stop-daemon -S -q -b -m -p /var/run/nvpproxy.pid -x $SVC_PATH -- -port=$vpnproxy_wan_port -proxy=127.0.0.1:$vpnproxy_vpn_port
restart_dhcpd
sleep 5
[ ! -z "`pidof nvpproxy`" ] && logger -t "【vpnproxy】" "启动成功"
[ -z "`pidof nvpproxy`" ] && logger -t "【vpnproxy】" "启动失败, 注意检查端口是否有冲突, 10秒后自动尝试重新启动" && sleep 5 && nvram set vpnproxy_status=00 && /tmp/sh_vpnproxy.sh &
fi
EEF
chmod 777 "/tmp/sh_vpnproxy.sh"

cat > "/tmp/sh_shellinabox.sh" <<-\EEF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

shellinabox_enable=`nvram get shellinabox_enable`
[ -z $shellinabox_enable ] && shellinabox_enable="0" && nvram set shellinabox_enable=$shellinabox_enable
shellinabox_port=`nvram get shellinabox_port`
[ -z $shellinabox_port ] && shellinabox_port="4200" && nvram set shellinabox_port=$shellinabox_port
shellinabox_css=`nvram get shellinabox_css`
[ -z $shellinabox_css ] && shellinabox_css="white-on-black" && nvram set shellinabox_css=$shellinabox_css
shellinabox_options=`nvram get shellinabox_options`
shellinabox_wan=`nvram get shellinabox_wan`

A_restart=`nvram get shellinabox_status`
B_restart="$shellinabox_enable$shellinabox_port$shellinabox_css$shellinabox_options$shellinabox_wan"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set shellinabox_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ -n "`pidof shellinaboxd`" ] && [ "$shellinabox_enable" = "1" ] && [ "$shellinabox_wan" = "1" ] ; then
    port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$shellinabox_port | cut -d " " -f 1 | sort -nr | wc -l)
    if [ "$port" = 0 ] ; then
        logger -t "【shellinabox】" "检测:找不到 ss-server 端口:$shellinabox_port 规则, 重新添加"
        iptables -t filter -I INPUT -p tcp --dport $shellinabox_port -j ACCEPT &
    fi
fi
if [ "$shellinabox_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof shellinaboxd`" ] && logger -t "【shellinabox】" "停止 shellinabox" && /opt/etc/init.d/S88shellinaboxd stop
killall -9 shellinaboxd
fi
if [ "$shellinabox_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
killall -9 shellinaboxd
SVC_PATH="/opt/sbin/shellinaboxd"
hash shellinaboxd 2>/dev/null || m -rf /opt/sbin/shellinaboxd
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【shellinabox】" "自动安装 shellinabox 程序"
    # 找不到 shellinabox，安装 opt
    rm -rf /opt/opti.txt
    if [ ! -f "/opt/opti.txt" ] ; then
        ssfile=`nvram get ssfile`
        ssfile2=`nvram get ssfile2`
        upanPath=""
        ss_opt_x=`nvram get ss_opt_x`
        [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
        [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
        [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
        if [ ! -z $upanPath ] ; then
            mkdir -p /media/$upanPath/opt
            mount -o bind /media/$upanPath/opt /opt
            ln -sf /media/$upanPath /tmp/AiDisk_00
            /tmp/sh_installs.sh $ssfile 1
        else
            mkdir -p /tmp/AiDisk_00/opt
            mount -o bind /tmp/AiDisk_00/opt /opt
            /tmp/sh_installs.sh $ssfile2 2
        fi
    fi
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【shellinabox】" "找不到 $SVC_PATH"
    else
        logger -t "【shellinabox】" "找到 $SVC_PATH"
    fi
fi

hash shellinaboxd 2>/dev/null || {  logger -t "【shellinabox】" "找不到 $SVC_PATH ，需要安装 opt 环境 opkg install shellinabox"; }

logger -t "【shellinabox】" "运行 $SVC_PATH"
killall -9 shellinaboxd
/opt/etc/init.d/S88shellinaboxd restart
sleep 5
[ ! -z "`pidof shellinaboxd`" ] && logger -t "【shellinabox】" "启动成功"
[ -z "`pidof shellinaboxd`" ] && logger -t "【shellinabox】" "启动失败, 注意检查端口是否有冲突, 10秒后自动尝试重新启动" && sleep 10 && nvram set shellinabox_status=00 && /tmp/sh_shellinabox.sh &
fi
EEF
chmod 777 "/tmp/sh_shellinabox.sh"

cat > "/tmp/sh_theme.sh" <<-\EEF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

theme_enable=`nvram get theme_enable`
[ -z $theme_enable ] && theme_enable=0 && nvram set theme_enable=$theme_enable
A_restart=`nvram get theme_status`
B_restart="$theme_enable"
#B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
B_restart=`echo -n "$B_restart"`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set theme_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$theme_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
logger -t "【主题界面】" "停止下载主题包"
fi
if [ "$theme_enable" != "0" ] && [ "$needed_restart" = "1" ] ; then
SVC_PATH="/opt/share/www/custom/common-theme/css/main.css"
#rm -f $SVC_PATH
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【主题界面】" "部署主题风格包"
    if [ ! -d "/opt/share/www/custom" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/share/www/custom
    fi
    rm -f $SVC_PATH
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【主题界面】" "主题风格包下载 $theme_enable"
        rm -f /opt/share/www/custom/theme.tgz
        [ "$theme_enable" = "1" ] && wget --continue --no-check-certificate  -O  /opt/share/www/custom/theme.tgz "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/theme-big.tgz"
        [ "$theme_enable" = "2" ] && wget --continue --no-check-certificate  -O  /opt/share/www/custom/theme.tgz "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/theme-lit.tgz"
        tar -xzvf /opt/share/www/custom/theme.tgz -C /opt/share/www/custom
        if [ ! -s "$SVC_PATH" ] ; then
            logger -t "【主题界面】" "解压不正常:/opt/share/www/custom"
            nvram set theme_status=00
            exit 1
        fi
        rm -f /opt/share/www/custom/theme.tgz
    fi
fi
fi
EEF
chmod 777 "/tmp/sh_theme.sh"

cat > "/tmp/sh_lnmp.sh" <<-\EEF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

lnmp_enable=`nvram get lnmp_enable`
[ -z $lnmp_enable ] && lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
default_enable=`nvram get default_enable`
[ -z $default_enable ] && default_enable=0 && nvram set default_enable=$default_enable
default_port=`nvram get default_port`
[ -z $default_port ] && default_port=81 && nvram set default_port=$default_port
kodexplorer_enable=`nvram get kodexplorer_enable`
[ -z $kodexplorer_enable ] && kodexplorer_enable=0 && nvram set kodexplorer_enable=$kodexplorer_enable
kodexplorer_port=`nvram get kodexplorer_port`
[ -z $kodexplorer_port ] && kodexplorer_port=82 && nvram set kodexplorer_port=$kodexplorer_port
phpmyadmin_enable=`nvram get phpmyadmin_enable`
[ -z $phpmyadmin_enable ] && phpmyadmin_enable=0 && nvram set phpmyadmin_enable=$phpmyadmin_enable
phpmyadmin_port=`nvram get phpmyadmin_port`
[ -z $phpmyadmin_port ] && phpmyadmin_port=85 && nvram set phpmyadmin_port=$phpmyadmin_port
wifidog_server_enable=`nvram get wifidog_server_enable`
[ -z $wifidog_server_enable ] && wifidog_server_enable=0 && nvram set wifidog_server_enable=$wifidog_server_enable
wifidog_server_port=`nvram get wifidog_server_port`
[ -z $wifidog_server_port ] && wifidog_server_port=84 && nvram set wifidog_server_port=$wifidog_server_port
owncloud_enable=`nvram get owncloud_enable`
[ -z $owncloud_enable ] && owncloud_enable=0 && nvram set owncloud_enable=$owncloud_enable
owncloud_port=`nvram get owncloud_port`
[ -z $owncloud_port ] && owncloud_port=83 && nvram set owncloud_port=$owncloud_port
mysql_enable=`nvram get mysql_enable`
http_username=`nvram get http_username`

A_restart=`nvram get lnmp_status`
B_restart="$http_username$lnmp_enable$mysql_enable$default_enable$kodexplorer_enable$owncloud_enable$phpmyadmin_enable$wifidog_server_enable$default_port$kodexplorer_port$owncloud_port$phpmyadmin_port$wifidog_server_port"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set lnmp_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$lnmp_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof nginx`" ] && logger -t "【LNMP】" "停止 nginx+php+mysql 环境"
/opt/etc/init.d/S70mysqld stop
/opt/etc/init.d/S79php-fpm stop
/opt/etc/init.d/S80nginx stop
killall spawn-fcgi nginx php-cgi mysqld
fi
if [ "$lnmp_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
/opt/etc/init.d/S70mysqld stop
/opt/etc/init.d/S79php-fpm stop
/opt/etc/init.d/S80nginx stop
killall spawn-fcgi nginx php-cgi mysqld
logger -t "【LNMP】" "/opt 已用数据空间`df -m|grep "% /opt" | awk ' {print $5F}'`/100%"
logger -t "【LNMP】" "/opt 已用节点空间`df -i|grep "% /opt" | awk ' {print $5F}'`/100%"
logger -t "【LNMP】" "以上两个数据如出现占用100%时，则opt空间或Inodes爆满，会影响LNMP运行，请重新正确格式化U盘。"

SVC_PATH="/opt/lnmp.txt"
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【LNMP】" "自动安装 nginx+php+mysql 环境"
    # 找不到【LNMP】，安装 opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    optava=`df -m|grep "% /opt" | awk ' {print $4F}'`
    if [ $optava -le 300 ] || [ -z "$optava" ] ; then
        logger -t "【LNMP】" "/opt剩余空间: $optava M，不足300M, 停止启用 LNMP, 请尝试重启"
        lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
        nvram set lnmp_status=$optava
        nvram commit
        exit 1
    fi
    touch /opt/testchmod
    chmod 644 /opt/testchmod
    optava=`ls /opt -al | grep testchmod| grep 'rw-r--r--'`
    if [ -z "$optava" ] ; then
        logger -t "【LNMP】" "/opt 修改文件权限失败, 停止启用 LNMP"
        logger -t "【LNMP】" "注意: U 盘格式不支持 FAT32, 请格式化 U 盘, 要用 EXT4 或 NTFS 格式。"
        lnmp_enable=0 && nvram set lnmp_enable=$lnmp_enable
        nvram commit
        exit 1
    fi
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【LNMP】" "找不到 $SVC_PATH 下载 /opt/opt-lnmp.tgz，需时3分钟"
        lnmpfile=`nvram get lnmpfile`
        logger -t "【LNMP】" "下载地址:$lnmpfile"
        rm -rf /opt/opt-lnmp.tgz
        wget --continue --no-check-certificate  -O  /opt/opt-lnmp.tgz "$lnmpfile"
        logger -t "【LNMP】" "下载 /opt/opt-lnmp.tgz 完成. 解压文档, 需时5分钟。。。"
        tar -xzvf /opt/opt-lnmp.tgz -C /opt/
        if [ ! -s "$SVC_PATH" ] ; then
            logger -t "【LNMP】" "解压不正常:$SVC_PATH"
            logger -t "【LNMP】" "启动失败, 10秒后自动尝试重新启动" && sleep 10
            rm -f /opt/lnmp.txt
            killall spawn-fcgi nginx php-cgi mysqld
            nvram set lnmp_status=00
            nvram commit
            /tmp/sh_lnmp.sh &
            exit 1
        else
        logger -t "【LNMP】" "解压完成."

        fi
    else
        logger -t "【LNMP】" "找到 $SVC_PATH"
    fi
fi

chmod -R 777 /opt/bin/
chmod -R 777 /opt/lib/

if [ -f "/opt/etc/init.d/S69pdcnlnmpinit" ] ; then
sed -e 's/.*nvram get lnmp_enable.*/lnmp_enable=`nvram get lnmp_enable` \&\& default_port=`nvram get default_port` /g' -i /opt/etc/init.d/S69pdcnlnmpinit
fi
logger -t "【LNMP】" "运行 nginx+php+mysql 环境"
if [ "$mysql_enable" = "4" ] || [ ! -d "/opt/mysql/test" ] ; then
    logger -t "【LNMP】" "重置 /opt/mysql 数据"
    killall mysqld
    rm -rf /opt/mysql/*
    sed -e "s/.*user.*/user = "$http_username"/g" -i /opt/etc/my.cnf
    chmod 644 /opt/etc/my.cnf
    mkdir -p /opt/mysql/
    /opt/bin/mysql_install_db
    /opt/bin/mysqld &
    sleep 2
    logger -t "【LNMP】" "重置 mysql 默认账号:root, 默认密码:admin, 请手动修改密码"
    /opt/bin/mysqladmin -u root password admin
    killall mysqld
    mysql_enable=0 && nvram set mysql_enable=$mysql_enable
    nvram commit
fi
if [ "$default_enable" = "4" ] ; then
    logger -t "【LNMP】" "重置 默认主页 数据."
    rm -rf /opt/www/default
    logger -t "【LNMP】" "重置 默认主页 数据完成。"
    default_enable=0 && nvram set default_enable=$default_enable
    nvram commit
fi
if [ "$kodexplorer_enable" = "4" ] ; then
    logger -t "【LNMP】" "重置 KodExplorer 芒果云 数据."
    rm -rf /opt/www/kodexplorer
    logger -t "【LNMP】" "重置 KodExplorer 芒果云 数据完成."
    kodexplorer_enable=0 && nvram set kodexplorer_enable=$kodexplorer_enable
    nvram commit
fi
if [ "$owncloud_enable" = "4" ] ; then
    logger -t "【LNMP】" "重置 OwnCloud 私有云 数据."
    rm -rf /opt/www/owncloud
    logger -t "【LNMP】" "重置 OwnCloud 私有云 数据完成."
    owncloud_enable=0 && nvram set owncloud_enable=$owncloud_enable
    nvram commit
fi
if [ "$phpmyadmin_enable" = "4" ] ; then
    logger -t "【LNMP】" "重置 phpMyAdmin 数据."
    rm -rf /opt/www/phpmyadmin
    logger -t "【LNMP】" "重置 phpMyAdmin 数据完成."
    phpmyadmin_enable=0 && nvram set phpmyadmin_enable=$phpmyadmin_enable
    nvram commit
fi
if [ "$wifidog_server_enable" = "4" ] ; then
    logger -t "【LNMP】" "重置 wifidog_server 数据."
    rm -rf /opt/www/wifidog_server
    logger -t "【LNMP】" "重置 wifidog_server 数据完成."
    wifidog_server_enable=0 && nvram set wifidog_server_enable=$wifidog_server_enable
    nvram commit
fi
B_restart="$http_username$lnmp_enable$mysql_enable$default_enable$kodexplorer_enable$owncloud_enable$phpmyadmin_enable$wifidog_server_enable$default_port$kodexplorer_port$owncloud_port$phpmyadmin_port$wifidog_server_port"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
nvram set lnmp_status=$B_restart
if [ "$lnmp_enable" = "1" ] ; then
    if [ "$default_enable" = "1" ] || [ "$default_enable" = "2" ] ; then
        if [ ! -d "/opt/www/default" ] ; then
            mkdir -p /opt/www/default
            cp -rf /opt/etc/nginx/xhost/default.conf /opt/etc/nginx/vhost/default.conf
            if [ ! -f "/opt/www/default/tz.php" ] ; then
                logger -t "【LNMP】" "找不到 tz.php, 下载程序文档, 需时1秒"
                logger -t "【LNMP】" "下载地址:https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/tz.php"
                wget --continue --no-check-certificate  -O  /opt/www/default/tz.php "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/tz.php"
            fi
        fi
        if [ ! -d "/opt/www/default" ] ; then
            logger -t "【LNMP】" "默认主页 停用, 因未找到 /opt/www/default"
        fi
    fi
    if [ "$kodexplorer_enable" = "1" ] || [ "$kodexplorer_enable" = "2" ] ; then
        if [ ! -d "/opt/www/kodexplorer/data" ] ; then
            if [ ! -f "/opt/www/kodexplorer.tgz" ] ; then
                logger -t "【LNMP】" "找不到 kodexplorer.tgz, 下载程序文档, 需时2分钟"
                lnmpfile3=`nvram get lnmpfile3`
                logger -t "【LNMP】" "下载地址:$lnmpfile3"
                wget --continue --no-check-certificate  -O  /opt/www/kodexplorer.tgz "$lnmpfile3"
            fi
            logger -t "【LNMP】" "解压 kodexplorer 文档, 需时1分钟"
            tar -xzvf /opt/www/kodexplorer.tgz -C /opt/www
        fi
        if [ ! -d "/opt/www/kodexplorer/data" ] ; then
            logger -t "【LNMP】" "芒果云 停用, 因未找到 /opt/www/kodexplorer/data"
        else
            sed -e "s/.*upload_chunk_size.*/        \'upload_chunk_size\'     => 1024*1024*1,        \/\/上传分片大小；默认1M/g" -i /opt/www/kodexplorer/config/setting.php
            chmod -R 777 /opt/www/kodexplorer/
        fi
    fi
    if [ "$phpmyadmin_enable" = "1" ] || [ "$phpmyadmin_enable" = "2" ] ; then
        if [ ! -d "/opt/www/phpmyadmin/libraries" ] ; then
            if [ ! -f "/opt/www/phpmyadmin.tgz" ] ; then
                logger -t "【LNMP】" "找不到 phpmyadmin.tgz, 下载程序文档, 需时2分钟"
                lnmpfile4=`nvram get lnmpfile4`
                logger -t "【LNMP】" "下载地址:$lnmpfile4"
                wget --continue --no-check-certificate  -O  /opt/www/phpmyadmin.tgz "$lnmpfile4"
            fi
            logger -t "【LNMP】" "解压 phpmyadmin 文档, 需时1分钟"
            tar -xzvf /opt/www/phpmyadmin.tgz -C /opt/www
        fi
        if [ ! -d "/opt/www/phpmyadmin/libraries" ] ; then
            logger -t "【LNMP】" "phpmyadmin 停用, 因未找到 /opt/www/phpmyadmin/libraries"
        else
            chmod 644 /opt/www/phpmyadmin/config.inc.php
        fi
    fi
    rm -rf /opt/etc/nginx/vhost/wifidog_server.conf
    if [ "$wifidog_server_enable" = "1" ] || [ "$wifidog_server_enable" = "2" ] ; then
        if [ ! -d "/opt/www/wifidog_server/auth" ] ; then
            if [ ! -f "/opt/www/wifidog_server.tgz" ] ; then
                logger -t "【LNMP】" "找不到 wifidog_server.tgz, 下载程序文档"
                lnmpfile6=`nvram get lnmpfile6`
                logger -t "【LNMP】" "下载地址:$lnmpfile6"
                wget --continue --no-check-certificate  -O  /opt/www/wifidog_server.tgz "$lnmpfile6"
            fi
            logger -t "【LNMP】" "解压 wifidog_server 文档"
            tar -xzvf /opt/www/wifidog_server.tgz -C /opt/www
        fi
        if [ ! -d "/opt/www/wifidog_server/auth" ] ; then
            logger -t "【LNMP】" "wifidog_server 停用, 因未找到 /opt/www/wifidog_server/auth"
        else
            chmod -R 777 /opt/www/wifidog_server/
            [ ! -f "/opt/etc/nginx/xhost/wifidog_server.conf" ] && wget --continue --no-check-certificate  -O  /opt/etc/nginx/xhost/wifidog_server.conf "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/wifidog_server.conf"
            cp -rf /opt/etc/nginx/xhost/wifidog_server.conf /opt/etc/nginx/vhost/wifidog_server.conf
            logger -t "【LNMP】" "wifidog_server 路径:/opt/www/wifidog_server 端口:$wifidog_server_port"
            sed -e "s/.*访问端口4.*/        listen       "$wifidog_server_port"; "' # 访问端口4/g' -i /opt/etc/nginx/vhost/wifidog_server.conf
            sed -e "s/.*output_buffering.*/output_buffering = On/g" -i /opt/etc/php.ini
            sed -e "s/.*session\.auto_start.*/session\.auto_start = 1/g" -i /opt/etc/php.ini
            logger -t "【LNMP】" "wifidog_server:`nvram get lan_ipaddr`:"$wifidog_server_port
        fi
    fi
    if [ "$owncloud_enable" = "1" ] || [ "$owncloud_enable" = "2" ] ; then
        if [ ! -d "/opt/www/owncloud/config" ] ; then
            if [ ! -f "/opt/www/owncloud-8.0.14.tar.bz2" ] ; then
                logger -t "【LNMP】" "找不到 owncloud-8.0.14.tar.bz2, 下载程序文档, 需时3分钟"
                lnmpfile5=`nvram get lnmpfile5`
                logger -t "【LNMP】" "下载地址:$lnmpfile5"
                wget --continue --no-check-certificate  -O  /opt/www/owncloud-8.0.14.tar.bz2 "$lnmpfile5"
            fi
            logger -t "【LNMP】" "解压 owncloud 文档, 需时5分钟"
            tar -jxvf /opt/www/owncloud-8.0.14.tar.bz2 -C /opt/www
        fi
        if [ ! -d "/opt/www/owncloud/config" ] ; then
            logger -t "【LNMP】" "owncloud 停用, 因未找到 /opt/www/owncloud/config"
        else
            chmod 770 /opt/www/owncloud/data
        fi
    fi
fi
/opt/etc/init.d/S69pdcnlnmpinit start
/opt/etc/init.d/S70mysqld restart
/opt/etc/init.d/S79php-fpm restart
/opt/etc/init.d/S80nginx restart
logger -t "【LNMP】" "/opt 已用数据空间`df -m|grep "% /opt" | awk ' {print $5F}'`/100%"
logger -t "【LNMP】" "/opt 已用节点空间`df -i|grep "% /opt" | awk ' {print $5F}'`/100%"
logger -t "【LNMP】" "以上两个数据如出现占用100%时，则 opt 空间或 Inodes 爆满，会影响 LNMP 运行，请重新正确格式化 U盘。"

[ -f /opt/lnmpi.txt ] && nvram set lnmpt=`cat /tmp/lnmpi.txt`
[ -f /opt/lnmp.txt ] && nvram set lnmpo=`cat /opt/lnmp.txt`
fi
EEF
chmod 777 "/tmp/sh_lnmp.sh"

cat > "/tmp/sh_ngrok.sh" <<-\EEF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
ngrok_enable=`nvram get ngrok_enable`
ngrok_server=`nvram get ngrok_server`
ngrok_port=`nvram get ngrok_port`
ngrok_token=`nvram get ngrok_token`
#系统分配域名
ngrok_domain=`nvram get ngrok_domain`
ngrok_domain_type=`nvram get ngrok_domain_type`
ngrok_domain_lhost=`nvram get ngrok_domain_lhost`
ngrok_domain_lport=`nvram get ngrok_domain_lport`
ngrok_domain_sdname=`nvram get ngrok_domain_sdname`
#TCP端口转发
ngrok_tcp=`nvram get ngrok_tcp`
ngrok_tcp_type=`nvram get ngrok_tcp_type`
ngrok_tcp_lhost=`nvram get ngrok_tcp_lhost`
ngrok_tcp_lport=`nvram get ngrok_tcp_lport`
ngrok_tcp_rport=`nvram get ngrok_tcp_rport`
#自定义域名
ngrok_custom=`nvram get ngrok_custom`
ngrok_custom_type=`nvram get ngrok_custom_type`
ngrok_custom_lhost=`nvram get ngrok_custom_lhost`
ngrok_custom_lport=`nvram get ngrok_custom_lport`
ngrok_custom_hostname=`nvram get ngrok_custom_hostname`
A_restart=`nvram get ngrok_status`
B_restart="$ngrok_enable$ngrok_server$ngrok_port$ngrok_token$ngrok_domain$ngrok_domain_type$ngrok_domain_lhost$ngrok_domain_lport$ngrok_domain_sdname$ngrok_tcp$ngrok_tcp_type$ngrok_tcp_lhost$ngrok_tcp_lport$ngrok_tcp_rport$ngrok_custom$ngrok_custom_type$ngrok_custom_lhost$ngrok_custom_lport$ngrok_custom_hostname$(cat /etc/storage/ngrok_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set ngrok_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$ngrok_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof ngrokc`" ] && logger -t "【ngrokc】" "停止 ngrokc"
killall -9 ngrokc ngrok_script.sh
fi
if [ "$ngrok_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
killall -9 ngrokc ngrok_script.sh
SVC_PATH="/usr/bin/ngrokc"
if [ ! -f "$SVC_PATH" ] ; then
    SVC_PATH="/opt/bin/ngrokc"
fi
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【ngrokc】" "自动安装 ngrokc 程序"
    # 找不到ngrokc，安装opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【ngrokc】" "找不到 $SVC_PATH 下载程序"
        wget --continue --no-check-certificate  -O  /opt/bin/ngrokc "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/ngrokc"
        chmod 755 "/opt/bin/ngrokc"
    else
        logger -t "【ngrokc】" "找到 $SVC_PATH"
    fi
fi

hash ngrokc 2>/dev/null || {  logger -t "【ngrokc】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; }

logger -t "【ngrokc】" "运行 ngrok_script"
killall -9 ngrokc ngrok_script.sh
#/etc/storage/ngrok_script.sh
sed -Ei '/UI设置自动生成/d' /etc/storage/ngrok_script.sh
sed -Ei '/^$/d' /etc/storage/ngrok_script.sh
# 系统分配域名
if [ "$ngrok_domain" = "1" ] ; then
cat >> "/etc/storage/ngrok_script.sh" <<-EUI
ngrokc -SER[Shost:$ngrok_server,Sport:$ngrok_port,Atoken:$ngrok_token] -AddTun[Type:$ngrok_domain_type,Lhost:$ngrok_domain_lhost,Lport:$ngrok_domain_lport,Sdname:$ngrok_domain_sdname] & #UI设置自动生成
EUI
fi
# TCP端口转发
if [ "$ngrok_tcp" = "1" ] ; then
cat >> "/etc/storage/ngrok_script.sh" <<-EUI
ngrokc -SER[Shost:$ngrok_server,Sport:$ngrok_port,Atoken:$ngrok_token] -AddTun[Type:$ngrok_tcp_type,Lhost:$ngrok_tcp_lhost,Lport:$ngrok_tcp_lport,Rport:$ngrok_tcp_rport] & #UI设置自动生成
EUI
fi
# 自定义域名
if [ "$ngrok_custom" = "1" ] ; then
cat >> "/etc/storage/ngrok_script.sh" <<-EUI
ngrokc -SER[Shost:$ngrok_server,Sport:$ngrok_port,Atoken:$ngrok_token] -AddTun[Type:$ngrok_custom_type,Lhost:$ngrok_custom_lhost,Lport:$ngrok_custom_lport,Hostname:$ngrok_custom_hostname] & #UI设置自动生成
EUI
fi
B_restart="$ngrok_enable$ngrok_server$ngrok_port$ngrok_token$ngrok_domain$ngrok_domain_type$ngrok_domain_lhost$ngrok_domain_lport$ngrok_domain_sdname$ngrok_tcp$ngrok_tcp_type$ngrok_tcp_lhost$ngrok_tcp_lport$ngrok_tcp_rport$ngrok_custom$ngrok_custom_type$ngrok_custom_lhost$ngrok_custom_lport$ngrok_custom_hostname$(cat /etc/storage/ngrok_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
nvram set ngrok_status=$B_restart
/etc/storage/ngrok_script.sh &
restart_dhcpd
fi
EEF
chmod 777 "/tmp/sh_ngrok.sh"

cat > "/tmp/sh_frp.sh" <<-\EEF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
frp_enable=`nvram get frp_enable`
frp_enable=${frp_enable:-"0"}
frpc_enable=`nvram get frpc_enable`
frpc_enable=${frpc_enable:-"0"}
frps_enable=`nvram get frps_enable`
frps_enable=${frps_enable:-"0"}

update=$1
if [ "$update" = "updatefrp" ] ; then
[ "$frp_enable" = "1" ] && nvram set frp_status="updatefrp"  && logger -t "【frp】" "重启"
if [ "$frp_enable" = "0" ] ; then
[ -f /opt/bin/frpc ] && rm -rf /opt/bin/frpc && logger -t "【frpc】" "更新"
[ -f /opt/bin/frps ] && rm -rf /opt/bin/frps && logger -t "【frps】" "更新"
nvram set frpc_v=""
nvram set frps_v=""
fi
fi

A_restart=`nvram get frp_status`
B_restart="$frp_enable$frpc_enable$frps_enable$(cat /etc/storage/frp_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set frp_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$frp_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof frpc`" ] && logger -t "【frp】" "停止 frpc"
[ ! -z "`pidof frps`" ] && logger -t "【frp】" "停止 frps"
killall -9 frpc frps frp_script.sh
fi
if [ "$frp_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then

if [ "$frpc_enable" = "1" ] ; then
    SVC_PATH="/opt/bin/frpc"
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【frp】" "自动安装 frpc 程序"
        # 找不到 frpc，安装 opt
        if [ ! -d "/opt/bin" ] ; then
        upanPath=""
        ss_opt_x=`nvram get ss_opt_x`
        [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
        [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
        [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
        if [ ! -z $upanPath ] ; then
            mkdir -p /media/$upanPath/opt
            mount -o bind /media/$upanPath/opt /opt
            ln -sf /media/$upanPath /tmp/AiDisk_00
        else
            mkdir -p /tmp/AiDisk_00/opt
            mount -o bind /tmp/AiDisk_00/opt /opt
        fi
        mkdir -p /opt/bin
        fi
        if [ ! -f "$SVC_PATH" ] ; then
            logger -t "【frp】" "找不到 $SVC_PATH 下载程序"
            wget --continue --no-check-certificate  -O  /opt/bin/frpc "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/frpc"
            chmod 755 "/opt/bin/frpc"
        else
            logger -t "【frp】" "找到 $SVC_PATH"
        fi
    fi
    hash frpc 2>/dev/null || {  logger -t "【frp】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; }
frpc_v=`/opt/bin/frpc -v`
nvram set frpc_v=$frpc_v
logger -t "【frp】" "frpc-version: $frpc_v"
fi
if [ "$frps_enable" = "1" ] ; then
    SVC_PATH="/opt/bin/frps"
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【frp】" "自动安装 frps 程序"
        # 找不到 frps，安装 opt
        if [ ! -d "/opt/bin" ] ; then
        upanPath=""
        ss_opt_x=`nvram get ss_opt_x`
        [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
        [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
        [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
        if [ ! -z $upanPath ] ; then
            mkdir -p /media/$upanPath/opt
            mount -o bind /media/$upanPath/opt /opt
            ln -sf /media/$upanPath /tmp/AiDisk_00
        else
            mkdir -p /tmp/AiDisk_00/opt
            mount -o bind /tmp/AiDisk_00/opt /opt
        fi
        mkdir -p /opt/bin
        fi
        if [ ! -f "$SVC_PATH" ] ; then
            logger -t "【frp】" "找不到 $SVC_PATH 下载程序"
            wget --continue --no-check-certificate  -O  /opt/bin/frps "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/frps"
            chmod 755 "/opt/bin/frps"
        else
            logger -t "【frp】" "找到 $SVC_PATH"
        fi
    fi
    hash frps 2>/dev/null || {  logger -t "【frp】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; }
frps_v=`/opt/bin/frps -v`
nvram set frps_v=$frps_v
logger -t "【frp】" "frps-version: $frps_v"
fi
logger -t "【frp】" "运行 frp_script"
killall -9 frp_script.sh
/etc/storage/frp_script.sh &
fi
EEF
chmod 777 "/tmp/sh_frp.sh"


cat > "/tmp/sh_server_chan.sh" <<-\EEF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
serverchan_enable=`nvram get serverchan_enable`
serverchan_enable=${serverchan_enable:-"0"}
serverchan_sckey=`nvram get serverchan_sckey`
serverchan_notify_1=`nvram get serverchan_notify_1`
serverchan_notify_2=`nvram get serverchan_notify_2`
serverchan_notify_3=`nvram get serverchan_notify_3`
serverchan_notify_4=`nvram get serverchan_notify_4`

send=$1
if [ "$send" = "send" ] ; then
curltest=`which curl`
    if [ -z "$curltest" ] ; then
    opkg install curl
    [ -f /opt/lib/libcurl.so.4.4.0 ] && rm -f /opt/lib/libcurl.so.4 ; cp -a -f /opt/lib/libcurl.so.4.4.0 /opt/lib/libcurl.so.4
    fi
curltest=`which curl`
    if [ -z "$curltest" ] ; then
        logger -t "【微信推送】" "未找到 curl 程序，停止 微信推送。请安装 opt 后输入[opkg install curl]安装"
        exit
    fi
serverchan_text=$2
serverchan_desp=$3
curl -s "http://sc.ftqq.com/$serverchan_sckey.send?text=$serverchan_text" -d "&desp=$serverchan_desp" &
logger -t "【微信推送】" "消息标题:$serverchan_text"
logger -t "【微信推送】" "消息内容:$serverchan_desp"
fi

A_restart=`nvram get serverchan_status`
B_restart="$serverchan_enable$serverchan_sckey$serverchan_notify_1$serverchan_notify_2$serverchan_notify_3$serverchan_notify_4$(cat /etc/storage/serverchan_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set serverchan_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$serverchan_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
killall serverchan_script.sh
killall sh_server_chan.sh
fi
if [ "$serverchan_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
killall serverchan_script.sh
curltest=`which curl`
    if [ -z "$curltest" ] ; then
    opkg install curl
    [ -f /opt/lib/libcurl.so.4.4.0 ] && rm -f /opt/lib/libcurl.so.4 ; cp -a -f /opt/lib/libcurl.so.4.4.0 /opt/lib/libcurl.so.4
    fi
curltest=`which curl`
    if [ -z "$curltest" ] ; then
        logger -t "【微信推送】" "未找到 curl 程序，停止 微信推送。请安装 opt 后输入[opkg install curl]安装"
        exit
    fi
logger -t "【微信推送】" "运行 /etc/storage/serverchan_script.sh"
/etc/storage/serverchan_script.sh &

fi
EEF
chmod 777 "/tmp/sh_server_chan.sh"


cat > "/tmp/sh_kcp_tun.sh" <<-\EEF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
kcptun_enable=`nvram get kcptun_enable`
kcptun_enable=${kcptun_enable:-"0"}
kcptun_server=`nvram get kcptun_server`
kcptun_s_server=""
kcptun_sport=`nvram get kcptun_sport`
kcptun_sport=${kcptun_sport:-"29900"}
kcptun_key=`nvram get kcptun_key`
kcptun_crypt=`nvram get kcptun_crypt`
kcptun_crypt=${kcptun_crypt:-"none"}
kcptun_lport=`nvram get kcptun_lport`
kcptun_lport=${kcptun_lport:-"8388"}
kcptun_sndwnd=`nvram get kcptun_sndwnd`
kcptun_sndwnd=${kcptun_sndwnd:-"1024"}
kcptun_rcvwnd=`nvram get kcptun_rcvwnd`
kcptun_rcvwnd=${kcptun_rcvwnd:-"1024"}
kcptun_mode=`nvram get kcptun_mode`
kcptun_mode=${kcptun_mode:-"fast"}
kcptun_mtu=`nvram get kcptun_mtu`
kcptun_mtu=${kcptun_mtu:-"1350"}
kcptun_dscp=`nvram get kcptun_dscp`
kcptun_dscp=${kcptun_dscp:-"0"}
kcptun_datashard=`nvram get kcptun_datashard`
kcptun_datashard=${kcptun_datashard:-"10"}
kcptun_parityshard=`nvram get kcptun_parityshard`
kcptun_parityshard=${kcptun_parityshard:-"3"}
kcptun_autoexpire=`nvram get kcptun_autoexpire`
kcptun_autoexpire=${kcptun_autoexpire:-"0"}
kcptun_path=`nvram get kcptun_path`
kcptun_path=${kcptun_path:-"/opt/bin/client_linux_mips"}
nvram set kcptun_path=$kcptun_path
kcptun_user=`nvram get kcptun_user`

update=$1
if [ "$update" = "updatekcptun" ] ; then
[ "$kcptun_enable" = "1" ] && nvram set kcptun_status="updatekcptun" && logger -t "【kcptun】" "重启"
[ "$kcptun_enable" = "0" ] && [ -f "$kcptun_path" ] && nvram set kcptun_v="" && logger -t "【kcptun】" "更新" && rm -rf $kcptun_path
fi

A_restart=`nvram get kcptun_status`
B_restart="$kcptun_enable$kcptun_user$kcptun_path$kcptun_parityshard$kcptun_datashard$kcptun_server$kcptun_sport$kcptun_key$kcptun_crypt$kcptun_lport$kcptun_sndwnd$kcptun_rcvwnd$kcptun_mode$kcptun_mtu$kcptun_dscp$(cat /etc/storage/kcptun_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set kcptun_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$kcptun_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof client_linux_mips`" ] && logger -t "【kcptun】" "停止 client_linux_mips"
eval $(ps  | grep "$kcptun_path" | grep -v grep | awk '{print "kill "$1}')
killall client_linux_mips kcptun_script.sh sh_kcpkeep.sh
fi
if [ "$kcptun_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
killall sh_kcpkeep.sh client_linux_mips $kcptun_path
eval $(ps  | grep "$kcptun_path" | grep -v grep | awk '{print "kill "$1}')
SVC_PATH=$kcptun_path
if [ ! -f "$SVC_PATH" ] ; then
    SVC_PATH="/opt/bin/client_linux_mips"
fi
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【kcptun】" "自动安装 client_linux_mips 程序"
    # 找不到 client_linux_mips，安装 opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【kcptun】" "找不到 $SVC_PATH 下载程序"
        wget --continue --no-check-certificate  -O  /opt/bin/client_linux_mips "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/client_linux_mips"
        chmod 755 "/opt/bin/client_linux_mips"
    else
        logger -t "【kcptun】" "找到 $SVC_PATH"
    fi
    if [ -f "$SVC_PATH" ] ; then
       nvram set kcptun_path=$SVC_PATH
    fi
fi
hash client_linux_mips 2>/dev/null || {  logger -t "【kcptun】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; }
kcptun_v=`$SVC_PATH -v | awk '{print $3}'`
nvram set kcptun_v=$kcptun_v
logger -t "【kcptun】" "kcptun-version: $kcptun_v"
logger -t "【kcptun】" "运行 kcptun_script"
killall client_linux_mips kcptun_script.sh sh_kcpkeep.sh
#/etc/storage/kcptun_script.sh

resolveip=`/usr/bin/resolveip -4 -t 10 $kcptun_server | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`nslookup $kcptun_server | awk 'NR==5{print $3}'` 
kcptun_s_server=$resolveip
[ -z "$kcptun_s_server" ] && { logger -t "【kcptun】" "[错误!!] 实在找不到你的 kcptun 服务器IP，麻烦看看哪里错了？"; nvram set kcptun_status=0; exit 0; } 

sed -Ei '/UI设置自动生成/d' /etc/storage/kcptun_script.sh
sed -Ei '/^$/d' /etc/storage/kcptun_script.sh


# 自动生成客户端启动命令

cat >> "/etc/storage/kcptun_script.sh" <<-EUI
# UI设置自动生成  客户端启动参数
$SVC_PATH $kcptun_user -r "$kcptun_s_server:$kcptun_sport" -l ":$kcptun_lport" -key $kcptun_key -mtu $kcptun_mtu -sndwnd $kcptun_sndwnd -rcvwnd $kcptun_rcvwnd -crypt $kcptun_crypt -mode $kcptun_mode -dscp $kcptun_dscp -datashard $kcptun_datashard -parityshard $kcptun_parityshard -autoexpire $kcptun_autoexpire -nocomp & #UI设置自动生成
EUI

# 自动生成服务端启动命令

cat >> "/etc/storage/kcptun_script.sh" <<-EUI
# UI设置自动生成 64位系统 服务端启动参数：此参数复制到服务器启动。（服务端请自行下载部署）
#./server_linux_amd64 -t "$kcptun_s_server:$kcptun_lport" -l ":$kcptun_sport" -key $kcptun_key -mtu $kcptun_mtu -sndwnd 2048 -rcvwnd 2048 -crypt $kcptun_crypt -mode $kcptun_mode -dscp $kcptun_dscp -datashard $kcptun_datashard -parityshard $kcptun_parityshard -nocomp & #UI设置自动生成
# UI设置自动生成 32位系统 服务端启动参数：此参数复制到服务器启动。（服务端请自行下载部署）
#./server_linux_386 -t "$kcptun_s_server:$kcptun_lport" -l ":$kcptun_sport" -key $kcptun_key -mtu $kcptun_mtu -sndwnd 2048 -rcvwnd 2048 -crypt $kcptun_crypt -mode $kcptun_mode -dscp $kcptun_dscp -datashard $kcptun_datashard -parityshard $kcptun_parityshard -nocomp & #UI设置自动生成
EUI


B_restart="$kcptun_enable$kcptun_user$kcptun_path$kcptun_parityshard$kcptun_datashard$kcptun_server$kcptun_sport$kcptun_key$kcptun_crypt$kcptun_lport$kcptun_sndwnd$kcptun_rcvwnd$kcptun_mode$kcptun_mtu$kcptun_dscp$(cat /etc/storage/kcptun_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
nvram set kcptun_status=$B_restart
/etc/storage/kcptun_script.sh &
restart_dhcpd
#守护脚本
killall sh_kcpkeep.sh
KCPNUM=$(echo `cat /etc/storage/kcptun_script.sh | grep -v "^#" | grep "KCPNUM=" | sed 's/KCPNUM=//'`)
cat > "/tmp/sh_kcpkeep.sh" <<-KKP
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
PRO_NAME=$SVC_PATH
KCPNUM=$KCPNUM
WLAN=ra0
 
while true ; do
#   用ps获取 \$PRO_NAME 进程数量
    NUM=\`ps | grep \${PRO_NAME} | grep -v grep |wc -l\`
#    echo \$NUM
if [ "\${NUM}" -lt "\$KCPNUM" ] ; then
#   少于 $KCPNUM ，重启进程
    echo "\${PRO_NAME} was killed"
    eval $(ps  | grep "\${PRO_NAME}" | grep -v grep | awk '{print "kill "$1}')
    killall -9 client_linux_mips
    
    $SVC_PATH $kcptun_user -r "$kcptun_s_server:$kcptun_sport" -l ":$kcptun_lport" -key $kcptun_key -mtu $kcptun_mtu -sndwnd $kcptun_sndwnd -rcvwnd $kcptun_rcvwnd -crypt $kcptun_crypt -mode $kcptun_mode -dscp $kcptun_dscp -datashard $kcptun_datashard -parityshard $kcptun_parityshard -autoexpire $kcptun_autoexpire -nocomp & #UI设置自动生成
elif [ "\${NUM}" -gt "\$KCPNUM" ] ; then
#   大于 $KCPNUM ，杀掉所有进程，重启
    echo "more than \$KCPNUM \${PRO_NAME},killall \${PRO_NAME}"
    eval $(ps  | grep "\${PRO_NAME}" | grep -v grep | awk '{print "kill "$1}')
    killall -9 client_linux_mips
    $SVC_PATH $kcptun_user -r "$kcptun_s_server:$kcptun_sport" -l ":$kcptun_lport" -key $kcptun_key -mtu $kcptun_mtu -sndwnd $kcptun_sndwnd -rcvwnd $kcptun_rcvwnd -crypt $kcptun_crypt -mode $kcptun_mode -dscp $kcptun_dscp -datashard $kcptun_datashard -parityshard $kcptun_parityshard -autoexpire $kcptun_autoexpire -nocomp & #UI设置自动生成
fi
sleep 11
done
exit 0
KKP
chmod 755 "/tmp/sh_kcpkeep.sh"
/tmp/sh_kcpkeep.sh &
fi



EEF
chmod 777 "/tmp/sh_kcp_tun.sh"
cat > "/tmp/sh_vlmcsd.sh" <<-\EEF
#!/bin/sh
kms_enable=`nvram get kms_enable`
if [ "$kms_enable" = "0" ] ; then
[ ! -z "`pidof vlmcsd`" ] && { sed -Ei '/_vlmcs._tcp/d' /etc/storage/dnsmasq/dnsmasq.conf; killall -9 vlmcsd; restart_dhcpd; }
fi
if [ -z "`pidof vlmcsd`" ] && [ "$kms_enable" = "1" ] ; then
/usr/bin/vlmcsd -i /etc/storage/vlmcsdini_script.sh -l /tmp/vlmcsd.log &
computer_name=`nvram get computer_name`
sed -Ei '/_vlmcs._tcp/d' /etc/storage/dnsmasq/dnsmasq.conf
nvram set lan_domain="lan"
echo "srv-host=_vlmcs._tcp.lan,$computer_name.lan,1688,0,100" >> /etc/storage/dnsmasq/dnsmasq.conf
/etc/storage/vlmcsdini_script.sh &
restart_dhcpd
fi
EEF
chmod 777 "/tmp/sh_vlmcsd.sh"
cat > "/tmp/sh_upopt.sh" <<-\EOF
#!/bin/sh
upopt=`nvram get upopt_enable`
rm -f /tmp/opti.txt
rm -f /tmp/lnmpi.txt
ssfile3=`nvram get ssfile3`
[ -z "$ssfile3" ] && ssfile3="https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/optg7.txt"
lnmpfile2=`nvram get lnmpfile2`
[ -z "$lnmpfile2" ] && lnmpfile2="https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/optg7.txt"
wget --continue --no-check-certificate -O "/tmp/opti.txt" $ssfile3
wget --continue --no-check-certificate -O "/tmp/lnmpi.txt" $lnmpfile2
nvram set opto=`cat /opt/opti.txt`
nvram set optt=`cat /tmp/opti.txt`
nvram set lnmpo=`cat /opt/lnmp.txt`
nvram set lnmpt=`cat /tmp/lnmpi.txt`
if [ $(cat /tmp/opti.txt) != $(cat /opt/opti.txt) ] && [ -f /tmp/opti.txt ] ; then
    if [ "$upopt" = "1" ] ; then
        logger -t "【opt】" "opt 需要更新, 自动启动更新"
        rm -rf /opt/opti.txt
        rm -rf /opt/lnmp.txt
        optinstall=1
    else
        logger -t "【opt】" "opt 需要更新, 自动更新未启用, 请设置自动更新或手动更新"
    fi
else
    logger -t "【opt】" "opt 不需更新"
fi
[ "$upopt" = "1" ] && [ ! -f /opt/opti.txt ] && optinstall=1
if [ $(cat /tmp/lnmpi.txt) != $(cat /opt/lnmp.txt) ] && [ -f /tmp/lnmpi.txt ] ; then
    if [ "$upopt" = "1" ] ; then
        logger -t "【opt】" "opt-lnmp 需要更新, 自动启动更新"
        rm -rf /opt/opti.txt
        rm -rf /opt/lnmp.txt
        optinstall=1
    else
        logger -t "【opt】" "opt-lnmp 需要更新, 自动更新未启用, 请设置自动更新或手动更新"
    fi
else
    logger -t "【opt】" "opt-lnmp 不需更新"
fi
[ "$upopt" = "1" ] && [ ! -f /opt/lnmp.txt ] && optinstall=1
EOF
chmod 777 "/tmp/sh_upopt.sh"
cat > "/tmp/sh_download.sh" <<-\EOF
#!/bin/sh
output=$1
url1=$2
url2=$3
[ -z "$url2" ] && url2=$url1
rm -f $output
wget --continue --no-check-certificate  -O $output $url1
if [ ! -s "$output" ] ; then
    logger -t "【下载】" "下载失败:【$output】 URL:【$url1】"
    logger -t "【下载】" "重新下载:【$output】 URL:【$url2】"
    rm -f $output
    sleep 16
    wget --continue --no-check-certificate  -O $output $url2
fi
if [ ! -s "$output" ] ; then
    logger -t "【下载】" "下载失败:【$output】 URL:【$url2】"
    exit 1
else
    chmod 777 $output
fi
EOF
chmod 777 "/tmp/sh_download.sh"
cat > "/tmp/sh_untar.sh" <<-\EOF
#!/bin/sh
flie=$1
output=$2
outputflie=$3
mkdir -p $output
tar -xzvf $flie -C $output
if [ ! -s "$outputflie" ] ; then
    logger -t "【解压】" "解压不正常:$1"
    exit 1
fi
EOF
chmod 777 "/tmp/sh_untar.sh"
cat > "/tmp/sh_ddns.sh" <<-\EOF
#!/bin/sh
flie=$1
url=$2
logger -t "【DDNS】" "更新 IP 地址-$flie"
while [ "1" ];
do
[ -f "$flie" ] && sleep 66
[ -f "$flie" ] && rm -f $flie
wget --continue --no-check-certificate -O $flie $url
sleep 666
continue
done
EOF
chmod 777 "/tmp/sh_ddns.sh"
cat > "/tmp/sh_func_load_adm.sh" <<-\EOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/tmp/7620adm/lib:/lib:/opt/lib

keep_adm(){
logger -t "【ADM】" "ADM 守护脚本启动."
killall admkeep.sh
cat > "/tmp/admkeep.sh" <<-\ADM
#!/bin/sh
cd /tmp/7620adm
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/tmp/7620adm/lib:/lib:/opt/lib
PRO_NAME="/tmp/7620adm/adm"
ADMNUM=1
runx="1"

while true ; do
#   用ps获取 $PRO_NAME 进程数量
    NUM=`ps | grep $PRO_NAME | grep -v grep |wc -l`
#    echo $NUM
#    logger -t "【ADM】" " $NUM 进程"
if [ "$NUM" -lt "$ADMNUM" ] ; then
#   少于 $ADMNUM ，重启进程
    logger -t "【ADM】" "少于 $ADMNUM, 重启进程"
    echo "$PRO_NAME was killed"
    /tmp/sh_adm18309.sh D
    eval $(ps  | grep "/tmp/7620adm/adm" | grep -v grep | awk '{print "kill "$1}')
    /tmp/7620adm/adm >> /dev/null 2>&1 &
    sleep 10
    /tmp/sh_adm18309.sh A
elif [ "$NUM" -gt "$ADMNUM" ] ; then
#   大于 $ADMNUM ，杀掉所有进程，重启
    logger -t "【ADM】" "大于 $ADMNUM, 杀掉所有进程, 重启"
    echo "more than $ADMNUM $PRO_NAME,killall $PRO_NAME"
    /tmp/sh_adm18309.sh D
    eval $(ps | grep "/tmp/7620adm/adm" | grep -v grep | awk '{print "kill "$1}')
    /tmp/7620adm/adm >> /dev/null 2>&1 &
    sleep 10
    /tmp/sh_adm18309.sh A
fi
sleep 62
if [ ! -f /tmp/cron_adb.lock ] && [ -s "/tmp/7620adm/adm" ] ; then
    PIDS=$(ps | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
    if [ "$PIDS" != 0 ] ; then
        port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
        if [ "$port" = 0 ] ; then
            logger -t "【ADM】" "守护检查:找不到18309转发规则, 重新添加"
            killall -15 adm
            killall -9 adm
            rm -f /tmp/cron_adb.lock
            nvram set adm_status="restart_firewall"
            restart_firewall &
            sleep 62
        fi
    fi
fi
runx=`expr $runx + 1`
if [ "$runx" -gt 720 ] ; then
runx="1"
checka="/tmp/var/admrule_everyday.txt"
rm -f /tmp/var/admrule_everyday.txt
urla="http://update2.admflt.com/ruler/admrule_everyday.txt"
checkb="/tmp/7620adm/subscribe/admrule_everyday.txt"
wget --continue --no-check-certificate  -O $checka $urla
    if [ "`md5sum $checka|cut -d" " -f1`" != "`md5sum $checkb|cut -d" " -f1`" ] ; then
        logger -t "【ADM】" "守护检查:有更新 $urla , 重启进程"
        /tmp/sh_adm18309.sh D
        killall -15 adm
        killall -9 adm
        rm -f /tmp/cron_adb.lock
        nvram set adm_status="restart_firewall"
        restart_firewall &
        sleep 62
    else
        logger -t "【ADM】" "守护检查:不需更新 $urla "
    fi
fi
done
exit 0
ADM
chmod 755 "/tmp/admkeep.sh"
/tmp/admkeep.sh &
}

adm_enable=`nvram get adm_enable`
adbmfile=`nvram get adbmfile`
adm_https=`nvram get adm_https`
adm_hookport=`nvram get adm_hookport`
lan_ipaddr=`nvram get lan_ipaddr`
ipsets=`nvram get adbyby_mode_x`
A_restart=`nvram get adm_status`
B_restart="$adm_enable$adbmfile$lan_ipaddr$adm_https$ipsets$adm_hookport$(cat /etc/storage/ad_config_script.sh | grep -v "^$" | grep -v "^#")$(cat /etc/storage/adm_rules_script.sh | grep -v "^$" | grep -v "^!")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set adm_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi

if [ "$needed_restart" = "0" ] ; then
if [ ! -f /tmp/cron_adb.lock ] && [ -s "/tmp/7620adm/adm" ] && [ "$adm_enable" = "1" ] ; then
    PIDS=$(ps | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
    if [ "$PIDS" != 0 ] ; then
        port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
        if [ "$port" = 0 ] ; then
            logger -t "【Adbyby】" "定时检查:找不到18309转发规则, 重新添加"
            /tmp/sh_adm18309.sh A
        fi
    fi
fi
fi
if [ "$needed_restart" = "1" ] ; then
    killall -9 adm ; killall -15 adm ; killall admkeep.sh ;
    [ "`iptables -t nat -L | grep 'ports 18309' | wc -l`" != "0" ] && /tmp/sh_adm18309.sh D &
    sleep 1
    [ "`iptables -t nat -L | grep 'ports 18309' | wc -l`" != "0" ] && /tmp/sh_adm18309.sh D &
    /etc/storage/ez_buttons_script.sh 3 &
    sleep 1
    [ "$adm_enable" = "0" ] && { rm -f /tmp/cron_adb.lock; killall sh_func_load_adm.sh; }
fi
[ "$needed_restart" = "1" ] && { killall -9 adm ; killall -15 adm ; killall admkeep.sh ; }
if [ -z "`pidof adm`" ] && [ "$adm_enable" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
    sleep 1
    touch /tmp/cron_adb.lock
    nvram set button_script_1_s="ADM"
    /tmp/sh_adm18309.sh D
    killall -15 adm
    killall -9 adm
    killall admkeep.sh
    if [ ! -s "/tmp/7620adm/adm" ] ; then
        logger -t "【ADM】" "开始下载 7620adm.tgz"
        /tmp/sh_download.sh /tmp/7620adm.tgz $adbmfile
        /tmp/sh_untar.sh /tmp/7620adm.tgz /tmp /tmp/7620adm/adm
    fi
    if [ -s "/tmp/7620adm/adm" ] ; then
        if [ "$adm_https" = "0" ] ; then
            sed -e "s|^\(support_ssl.*\)=[^=]*$|\1=0|" -i /tmp/7620adm/ADMConfig.ini
        fi
        if [ "$adm_https" = "1" ] ; then
            mkdir -p /etc/storage/adm
            sed -e "s|^\(support_ssl.*\)=[^=]*$|\1=1|" -i /tmp/7620adm/ADMConfig.ini
            [ -f /etc/storage/adm/adm_ca.crt ] && cp -f /etc/storage/adm/adm_ca.crt /tmp/7620adm/adm_ca.crt
            [ -f /etc/storage/adm/adm_ca_key.pem ] && cp -f /etc/storage/adm/adm_ca_key.pem /tmp/7620adm/adm_ca_key.pem
        fi
        cat /etc/storage/adm_rules_script.sh | grep -v '^!' | grep -v "^$" > /tmp/7620adm/user.txt
        chmod 777 /tmp/7620adm/adm
        logger -t "【ADM】" "启动 adm 程序"
        cd /tmp/7620adm
        export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
        export LD_LIBRARY_PATH=/tmp/7620adm/lib:/lib:/opt/lib
        sleep 1
        /tmp/7620adm/adm >/dev/null 2>&1 &
        sleep 10
        if [ "$adm_https" = "1" ] ; then
            [ ! -f /etc/storage/adm/adm_ca.crt ] && [ -f /tmp/7620adm/adm_ca.crt ] && cp /tmp/7620adm/adm_ca.crt /etc/storage/adm/adm_ca.crt
            [ ! -f /etc/storage/adm/adm_ca_key.pem ] && [ -f /tmp/7620adm/adm_ca_key.pem ] && cp /tmp/7620adm/adm_ca_key.pem /etc/storage/adm/adm_ca_key.pem && mtd_storage.sh save &
        fi
    fi
    PIDS=$(ps | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
    if [ "$PIDS" != 0 ] ; then 
        logger -t "【ADM】" "启动完成"
        rm -f /tmp/7620adm.tgz
        rm -f /tmp/cron_adb.lock
        /tmp/sh_adm18309.sh A
        sleep 5
        keep_adm
        /etc/storage/ez_buttons_script.sh 3 &
    fi
    rm -f /tmp/cron_adb.lock
    PIDS=$(ps | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
    [ "$PIDS" = 0 ] && logger -t "【ADM】" "启动失败, 10秒后自动尝试重新启动" && sleep 10 && nvram set adm_status=00 && /tmp/sh_func_load_adm.sh &
fi


EOF
chmod 777 "/tmp/sh_func_load_adm.sh"
cat > "/tmp/sh_adm18309.sh" <<-\EOFAD
#!/bin/sh
#初始化开始
TAG="AD_BYBY"          # iptables tag
FWI="/tmp/firewall.adbyby.pdcn" # firewall include file
AD_LAN_AC_IP=`nvram get AD_LAN_AC_IP`
AD_LAN_AC_IP=${AD_LAN_AC_IP:-"0"}
adm_https=`nvram get adm_https`
adm_hookport=`nvram get adm_hookport`

adb=$1
confdir=$2
gfwlist="/r.gfwlist.conf"
gfw_black_list="gfwlist"
ipsets=`nvram get adbyby_mode_x`
ss_mode_x=`nvram get ss_mode_x`
confdir=`grep conf-dir /etc/storage/dnsmasq/dnsmasq.conf | sed 's/.*\=//g'`
if [ -z "$confdir" ] ; then 
    confdir="/tmp/ss/dnsmasq.d"
fi
[ ! -z "$confdir" ] && mkdir -p $confdir

# AD规则

gen_special_purpose_ip() {
#处理肯定不走通道的目标网段
lan_ipaddr=`nvram get lan_ipaddr`
kcptun_enable=`nvram get kcptun_enable`
kcptun_enable=${kcptun_enable:-"0"}
kcptun_server=`nvram get kcptun_server`
if [ "$kcptun_enable" != "0" ] ; then
resolveip=`/usr/bin/resolveip -4 -t 10 $kcptun_server | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`nslookup $kcptun_server | awk 'NR==5{print $3}'` 
kcptun_server=$resolveip
fi
[ "$kcptun_enable" = "0" ] && kcptun_server=""
ss_enable=`nvram get ss_enable`
ss_enable=${ss_enable:-"0"}
[ "$ss_enable" = "0" ] && ss_s1_ip="" && ss_s2_ip=""
nvram set ss_server1=`nvram get ss_server`
ss_server1=`nvram get ss_server1`
ss_server2=`nvram get ss_server2`
if [ "$ss_enable" != "0" ] ; then
resolveip=`/usr/bin/resolveip -4 -t 10 $ss_server1 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`nslookup $ss_server1 | awk 'NR==5{print $3}'` 
ss_s1_ip=$resolveip
resolveip=`/usr/bin/resolveip -4 -t 10 $ss_server2 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`nslookup $ss_server2 | awk 'NR==5{print $3}'` 
ss_s2_ip=$resolveip
fi
    cat <<-EOF | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}"
0.0.0.0/8
10.0.0.0/8
100.64.0.0/10
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.0.0.0/24
192.0.2.0/24
192.25.61.0/24
192.31.196.0/24
192.52.193.0/24
192.88.99.0/24
192.168.0.0/16
192.175.48.0/24
198.18.0.0/15
198.51.100.0/24
203.0.113.0/24
224.0.0.0/4
240.0.0.0/4
255.255.255.255
$lan_ipaddr
$ss_s1_ip
$ss_s2_ip
$kcptun_server
EOF
}

include_ac_rules() {
    iptables-restore -n <<-EOF
*$1
:AD_BYBY - [0:0]
:AD_BYBY_LAN_AC - [0:0]
:AD_BYBY_WAN_AC - [0:0]
:AD_BYBY_to - [0:0]
-A AD_BYBY -m set --match-set ad_spec_dst_sp dst -j RETURN
-A AD_BYBY -j AD_BYBY_LAN_AC
-A AD_BYBY_LAN_AC -m set --match-set ad_spec_src_bp src -j RETURN
-A AD_BYBY_LAN_AC -m set --match-set ad_spec_src_fw src -j AD_BYBY_to
-A AD_BYBY_LAN_AC -m set --match-set ad_spec_src_ac src -j AD_BYBY_WAN_AC
-A AD_BYBY_LAN_AC -j ${LAN_TARGET:=AD_BYBY_WAN_AC}
-A AD_BYBY_WAN_AC -m set --match-set adbybylist dst -j ${ADBYBYLIST_TARGET:=AD_BYBY_to}
-A AD_BYBY_WAN_AC -m set --match-set cflist dst -j ${ADBYBYLIST_TARGET:=AD_BYBY_to}
-A AD_BYBY_WAN_AC -j ${WAN_TARGET:=AD_BYBY_to}
COMMIT
EOF
}

gen_include() {
[ -n "$FWI" ] || return 0
cat <<-CAT >>$FWI
iptables-restore -n <<-EOF
$(iptables-save | grep -E "$TAG|^\*|^COMMIT" |sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOF
CAT
return $?
}

flush_r() {
    iptables-save -c | grep -v "$TAG" | iptables-restore -c
    for setname in $(ipset -n list | grep -i "ad_spec"); do
        ipset destroy $setname 2>/dev/null
    done
    [ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
    ipset -F adbybylist &> /dev/null
    ipset destroy adbybylist &> /dev/null
    ipset -F cflist &> /dev/null
    iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 18309 &> /dev/null
    [ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
    return 0
}

#检查 dnsmasq 目录参数
if [ -z "$confdir" ] ; then 
    confdir="/tmp/ss/dnsmasq.d"
fi
[ ! -z "$confdir" ] && mkdir -p $confdir
[ -z "$gfwlist" ] && gfwlist=/r.gfwlist.conf
[ -z "$gfw_black_list" ] && gfw_black_list=gfwlist

#killall -9 sh_adblock_hosts.sh
#/tmp/sh_adblock_hosts.sh $confdir &

if [ "$adb" = "D" ] ; then
    logger -t "【iptables】" "删除18309转发规则"
    flush_r
    rm -f /tmp/adbyby_host.conf
    sed -Ei '/adbyby_host.conf/d' /etc/storage/dnsmasq/dnsmasq.conf
    restart_dhcpd
    logger -t "【iptables】" "完成删除18309规则"
fi
if [ "$adb" = "A" ] ; then
    logger -t "【iptables】" "添加18309转发规则"
    # rules规则
    flush_r
    ipset -! restore <<-EOF || return 1
create ad_spec_src_ac hash:ip hashsize 64
create ad_spec_src_bp hash:ip hashsize 64
create ad_spec_src_fw hash:ip hashsize 64
create ad_spec_dst_sp hash:net hashsize 64
$(gen_special_purpose_ip | sed -e "s/^/add ad_spec_dst_sp /")
EOF
ipset -! -N cflist iphash
ipset -! -N adbybylist iphash
lan_ipaddr=`nvram get lan_ipaddr`
ipset add ad_spec_src_bp $lan_ipaddr
ipset add ad_spec_src_bp 127.0.0.1
/etc/storage/ad_config_script.sh
# 内网(LAN)访问控制
logger -t "【Adbyby】" "设置内网(LAN)访问控制"
if [ -n "$AD_LAN_AC_IP" ] ; then
    case "${AD_LAN_AC_IP:0:1}" in
        0)
            LAN_TARGET="AD_BYBY_WAN_AC"
            ;;
        1)
            LAN_TARGET="AD_BYBY_to"
            ;;
        2)
            LAN_TARGET="RETURN"
            ;;
    esac
fi
grep -v '^#' /tmp/ad_spec_lan_DOMAIN.txt | sort -u | grep -v "^$" | sed s/！/!/g > /tmp/ad_spec_lan.txt
while read line
do
for host in $line; do
    case "${host:0:1}" in
        n|N)
            ipset add ad_spec_src_ac ${host:2}
            ;;
        b|B)
            ipset add ad_spec_src_bp ${host:2}
            ;;
        g|G)
            ipset add ad_spec_src_fw ${host:2}
            ;;
    esac
done
done < /tmp/ad_spec_lan.txt
    [ "$ipsets" == 0 ] && WAN_TARGET="AD_BYBY_to"
    [ "$ipsets" == 0 ] && ADBYBYLIST_TARGET="AD_BYBY_to"
    [ "$ipsets" == 1 ] && WAN_TARGET="RETURN"
    [ "$ipsets" == 1 ] && ADBYBYLIST_TARGET="AD_BYBY_to"
    include_ac_rules nat
    wifidognx=""
        #wifidogn=`iptables -t nat -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## SS_SPEC
        #if [ -z "$wifidogn" ] ; then
            wifidogn=`iptables -t nat -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
            if [ -z "$wifidogn" ] ; then
                wifidogn=`iptables -t nat -L PREROUTING --line-number | grep vserver | awk '{print $1}' | awk 'END{print $1}'`  ## vserver
                if [ -z "$wifidogn" ] ; then
                    wifidognx=1
                else
                    wifidognx=`expr $wifidogn + 1`
                fi
            else
                wifidognx=`expr $wifidogn + 1`
            fi
        #else
        #    wifidognx=`expr $wifidogn + 1`
        #fi
    wifidogn=$wifidognx
    echo "AD_BYBY-number:$wifidogn"

    if [ -f /tmp/7620adm/adm_hookport.txt ] && [ "$adm_hookport" == 1 ] ; then
        i=1 && hookport1="" && hookport2="" && hookport3="" && hookport4="" && hookport5=""
        for hookport in $(cat /tmp/7620adm/adm_hookport.txt | sed s/\|/\ /g)
        do
            [ "$i" -eq 1 ] && hookport1=$hookport
            [ "$i" -eq 15 ] && hookport2=$hookport
            [ "$i" -eq 30 ] && hookport3=$hookport
            [ "$i" -eq 45 ] && hookport4=$hookport
            [ "$i" -eq 60 ] && hookport5=$hookport
            [ "$i" -gt 1 ] && [ "$i" -lt 15 ] && hookport1=$hookport1","$hookport
            [ "$i" -gt 15 ] && [ "$i" -lt 30 ] && hookport2=$hookport2","$hookport
            [ "$i" -gt 30 ] && [ "$i" -lt 45 ] && hookport3=$hookport3","$hookport
            [ "$i" -gt 45 ] && [ "$i" -lt 60 ] && hookport4=$hookport4","$hookport
            [ "$i" -gt 60 ] && [ "$i" -lt 75 ] && hookport5=$hookport5","$hookport
            i=`expr $i + 1`
        done
        [ ! -z "$hookport1" ] && iptables -t nat -I PREROUTING $wifidogn -p tcp -m multiport --dports $hookport1 -j AD_BYBY
        [ ! -z "$hookport2" ] && iptables -t nat -I PREROUTING $wifidogn -p tcp -m multiport --dports $hookport2 -j AD_BYBY
        [ ! -z "$hookport3" ] && iptables -t nat -I PREROUTING $wifidogn -p tcp -m multiport --dports $hookport3 -j AD_BYBY
        [ ! -z "$hookport4" ] && iptables -t nat -I PREROUTING $wifidogn -p tcp -m multiport --dports $hookport4 -j AD_BYBY
        [ ! -z "$hookport5" ] && iptables -t nat -I PREROUTING $wifidogn -p tcp -m multiport --dports $hookport5 -j AD_BYBY
    else
        [ "$adm_https" = "1" ] && iptables -t nat -I PREROUTING $wifidogn -p tcp -m multiport --dports 80,443 -j AD_BYBY
        [ "$adm_https" != "1" ] && iptables -t nat -I PREROUTING $wifidogn -p tcp -m multiport --dports 80 -j AD_BYBY
    fi
    iptables -t nat -A AD_BYBY_to -p tcp -j REDIRECT --to-port 18309
    sleep 1
    gen_include &
    logger -t "【iptables】" "完成添加18309规则"
    [ "$ipsets" == 1 ] && [ -f /tmp/7620adm/adm_ipset.txt ] && ln -sf /tmp/7620adm/adm_ipset.txt /tmp/adbyby_host.conf
    [ "$ipsets" == 1 ] && /tmp/sh_adm18309.sh C &
fi
#去除gfw donmain中与 adbyby host 包含的域名，这部分域名交由adbyby处理。
# 参考的awk指令写法
#  awk  'NR==FNR{a[$0]}NR>FNR{ if($1 in a) print $0}' file1 file2 #找出两文件中相同的值
#  awk  'NR==FNR{a[$0]}NR>FNR{ if(!($1 in a)) print $0}' file1 file2 #去除 file2 中file1的内容
#  awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' file1 file2 #找出两个文件之间的相同部分
#  awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' file1 file2 #去除 file2 中file1的内容
if [ "$ipsets" == 1 ] && [ -s /tmp/adbyby_host.conf ] && [ "$adb" = "C" ] ; then
logger -t "【iptables】" "添加 ipset 转发规则"
sed -Ei '/adbyby_host.conf|cflist.conf/d' /etc/storage/dnsmasq/dnsmasq.conf
    sed  "s/\/adm_list/\/adbybylist/" -i  /tmp/adbyby_host.conf
    [ -f "$confdir$gfwlist" ] && gfw_black=$(grep "/$gfw_black_list" "$confdir$gfwlist" | sed 's/.*\=//g')
    if [ -s "$confdir$gfwlist" ] && [ -s /tmp/adbyby_host.conf ]  && [ ! -z "$gfw_black" ] ; then
        logger -t "【iptables】" "admlist 规则处理开始"
        mkdir -p /tmp/b/
        sed -e '/^\#/d' -e "s/ipset=\/www\./ipset=\/\./" -e "s/ipset=\/bbs\./ipset=\/\./" -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\//ipset=\/\./" -i /tmp/adbyby_host.conf
        sed -e '/^\#/d' -e "s/ipset=\/www\./ipset=\/\./" -e "s/ipset=\/bbs\./ipset=\/\./" -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\//ipset=\/\./" -i "$confdir$gfwlist"
        sed -e '/^\#/d' -e "s/ipset=\///" -e "s/adbybylist//" /tmp/adbyby_host.conf > /tmp/b/adbyby_host去干扰.conf
        sed -e '/^\#/d' -e "s/ipset=\///" -e "s/$gfw_black_list//" -e "/server=\//d" "$confdir$gfwlist" > /tmp/b/gfwlist去干扰.conf
        awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /tmp/b/adbyby_host去干扰.conf /tmp/b/gfwlist去干扰.conf > /tmp/b/host相同行.conf
        if [ -s /tmp/b/host相同行.conf ] ; then
            logger -t "【iptables】" "gfwlist 规则处理开始"
            sed -e "s/^/ipset=\//" -e "s/$/adbybylist/" /tmp/b/host相同行.conf > /tmp/b/host相同行2.conf
            awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/b/host相同行2.conf /tmp/adbyby_host.conf > /tmp/b/adbyby_host不重复.conf
            sed -e "s/^/ipset=\//" -e "s/$/$gfw_black_list/" /tmp/b/host相同行.conf > /tmp/b/host相同行2.conf
            awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/b/host相同行2.conf "$confdir$gfwlist" > /tmp/b/gfwlist不重复.conf
            sed -e "s/^/ipset=\//" -e "s/$/cflist/" /tmp/b/host相同行.conf > /tmp/b/list重复.conf
            cp -a -v /tmp/b/adbyby_host不重复.conf /tmp/adbyby_host.conf
            cp -a -v /tmp/b/gfwlist不重复.conf "$confdir$gfwlist"
            #rm -f "$confdir/cflist.conf"
            #cp -a -v /tmp/b/list重复.conf "$confdir/cflist.conf"
            cat /tmp/b/list重复.conf >> "$confdir/cflist.conf"
            logger -t "【iptables】" "gfwlist 规则处理完毕"
        fi
        grep -v '^#' $confdir/cflist.conf | sort -u | grep -v "^$" > /tmp/ss/cflist.conf
        grep -v '^#' /tmp/ss/cflist.conf | sort -u | grep -v "^$" > $confdir/cflist.conf
        echo "conf-file=$confdir/cflist.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
    fi
echo "conf-file=/tmp/adbyby_host.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
ipset flush cflist
ipset flush adbybylist
if [ -f /tmp/7620adm/adm_blockip.txt ] ; then
        ipset flush ss_spec_dst_sh
        grep -v '^#' /tmp/7620adm/adm_blockip.txt | sort -u | grep -v "^$" | sed -e "s/^/-A adbybylist &/g" | ipset -R -!
fi
restart_dhcpd
logger -t "【iptables】" "admlist 规则处理完毕"
rm -f /tmp/b/*
fi
sleep 1
/etc/storage/ez_buttons_script.sh 3 &
#restart_dhcpd
EOFAD
chmod 777 "/tmp/sh_adm18309.sh"

cat > "/tmp/sh_adb8118.sh" <<-\EOFAD
#!/bin/sh
#初始化开始
TAG="AD_BYBY"          # iptables tag
FWI="/tmp/firewall.adbyby.pdcn" # firewall include file
AD_LAN_AC_IP=`nvram get AD_LAN_AC_IP`
AD_LAN_AC_IP=${AD_LAN_AC_IP:-"0"}

adb=$1
confdir=$2
gfwlist=$3
gfw_black_list=$4
ipsets=`nvram get adbyby_mode_x`
ss_mode_x=`nvram get ss_mode_x`
# AD规则

gen_special_purpose_ip() {
#处理肯定不走通道的目标网段
lan_ipaddr=`nvram get lan_ipaddr`
kcptun_enable=`nvram get kcptun_enable`
kcptun_enable=${kcptun_enable:-"0"}
kcptun_server=`nvram get kcptun_server`
if [ "$kcptun_enable" != "0" ] ; then
resolveip=`/usr/bin/resolveip -4 -t 10 $kcptun_server | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`nslookup $kcptun_server | awk 'NR==5{print $3}'` 
kcptun_server=$resolveip
fi

[ "$kcptun_enable" = "0" ] && kcptun_server=""
ss_enable=`nvram get ss_enable`
ss_enable=${ss_enable:-"0"}
[ "$ss_enable" = "0" ] && ss_s1_ip="" && ss_s2_ip=""
nvram set ss_server1=`nvram get ss_server`
ss_server1=`nvram get ss_server1`
ss_server2=`nvram get ss_server2`
if [ "$ss_enable" != "0" ] ; then
resolveip=`/usr/bin/resolveip -4 -t 10 $ss_server1 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`nslookup $ss_server1 | awk 'NR==5{print $3}'` 
ss_s1_ip=$resolveip
resolveip=`/usr/bin/resolveip -4 -t 10 $ss_server2 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`nslookup $ss_server2 | awk 'NR==5{print $3}'` 
ss_s2_ip=$resolveip
fi
    cat <<-EOF | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}"
0.0.0.0/8
10.0.0.0/8
100.64.0.0/10
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.0.0.0/24
192.0.2.0/24
192.25.61.0/24
192.31.196.0/24
192.52.193.0/24
192.88.99.0/24
192.168.0.0/16
192.175.48.0/24
198.18.0.0/15
198.51.100.0/24
203.0.113.0/24
224.0.0.0/4
240.0.0.0/4
255.255.255.255
$lan_ipaddr
$ss_s1_ip
$ss_s2_ip
$kcptun_server
EOF
}

include_ac_rules() {
    iptables-restore -n <<-EOF
*$1
:AD_BYBY - [0:0]
:AD_BYBY_LAN_AC - [0:0]
:AD_BYBY_WAN_AC - [0:0]
:AD_BYBY_to - [0:0]
-A AD_BYBY -m set --match-set ad_spec_dst_sp dst -j RETURN
-A AD_BYBY -j AD_BYBY_LAN_AC
-A AD_BYBY_LAN_AC -m set --match-set ad_spec_src_bp src -j RETURN
-A AD_BYBY_LAN_AC -m set --match-set ad_spec_src_fw src -j AD_BYBY_to
-A AD_BYBY_LAN_AC -m set --match-set ad_spec_src_ac src -j AD_BYBY_WAN_AC
-A AD_BYBY_LAN_AC -j ${LAN_TARGET:=AD_BYBY_WAN_AC}
-A AD_BYBY_WAN_AC -m set --match-set adbybylist dst -j ${ADBYBYLIST_TARGET:=AD_BYBY_to}
-A AD_BYBY_WAN_AC -m set --match-set cflist dst -j ${ADBYBYLIST_TARGET:=AD_BYBY_to}
-A AD_BYBY_WAN_AC -j ${WAN_TARGET:=AD_BYBY_to}
COMMIT
EOF
}

gen_include() {
[ -n "$FWI" ] || return 0
cat <<-CAT >>$FWI
iptables-restore -n <<-EOF
$(iptables-save | grep -E "$TAG|^\*|^COMMIT" |sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOF
CAT
return $?
}

flush_r() {
    iptables-save -c | grep -v "$TAG" | iptables-restore -c
    for setname in $(ipset -n list | grep -i "ad_spec"); do
        ipset destroy $setname 2>/dev/null
    done
    [ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
    ipset -F adbybylist &> /dev/null
    ipset destroy adbybylist &> /dev/null
    ipset -F cflist &> /dev/null
    iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8118 &> /dev/null
    [ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
    return 0
}

#检查 dnsmasq 目录参数
if [ -z "$confdir" ] ; then 
    confdir="/tmp/ss/dnsmasq.d"
fi
[ ! -z "$confdir" ] && mkdir -p $confdir
[ -z "$gfwlist" ] && gfwlist=/r.gfwlist.conf
[ -z "$gfw_black_list" ] && gfw_black_list=gfwlist

#killall -9 sh_adblock_hosts.sh
#/tmp/sh_adblock_hosts.sh $confdir &

if [ "$adb" = "D" ] ; then
    logger -t "【iptables】" "删除8118转发规则"
    flush_r
    rm -f /tmp/adbyby_host.conf
    sed -Ei '/adbyby_host.conf/d' /etc/storage/dnsmasq/dnsmasq.conf
    restart_dhcpd
    logger -t "【iptables】" "完成删除8118规则"
fi
if [ "$adb" = "A" ] ; then
    logger -t "【iptables】" "添加8118转发规则"
    # rules规则
    flush_r
    ipset -! restore <<-EOF || return 1
create ad_spec_src_ac hash:ip hashsize 64
create ad_spec_src_bp hash:ip hashsize 64
create ad_spec_src_fw hash:ip hashsize 64
create ad_spec_dst_sp hash:net hashsize 64
$(gen_special_purpose_ip | sed -e "s/^/add ad_spec_dst_sp /")
EOF
ipset -! -N cflist iphash
ipset -! -N adbybylist iphash
lan_ipaddr=`nvram get lan_ipaddr`
ipset add ad_spec_src_bp $lan_ipaddr
ipset add ad_spec_src_bp 127.0.0.1
/etc/storage/ad_config_script.sh
# 内网(LAN)访问控制
logger -t "【Adbyby】" "设置内网(LAN)访问控制"
if [ -n "$AD_LAN_AC_IP" ] ; then
    case "${AD_LAN_AC_IP:0:1}" in
        0)
            LAN_TARGET="AD_BYBY_WAN_AC"
            ;;
        1)
            LAN_TARGET="AD_BYBY_to"
            ;;
        2)
            LAN_TARGET="RETURN"
            ;;
    esac
fi
grep -v '^#' /tmp/ad_spec_lan_DOMAIN.txt | sort -u | grep -v "^$" | sed s/！/!/g > /tmp/ad_spec_lan.txt
while read line
do
for host in $line; do
    case "${host:0:1}" in
        n|N)
            ipset add ad_spec_src_ac ${host:2}
            ;;
        b|B)
            ipset add ad_spec_src_bp ${host:2}
            ;;
        g|G)
            ipset add ad_spec_src_fw ${host:2}
            ;;
    esac
done
done < /tmp/ad_spec_lan.txt
    [ "$ipsets" == 0 ] && WAN_TARGET="AD_BYBY_to"
    [ "$ipsets" == 0 ] && ADBYBYLIST_TARGET="AD_BYBY_to"
    [ "$ipsets" == 1 ] && WAN_TARGET="RETURN"
    [ "$ipsets" == 1 ] && ADBYBYLIST_TARGET="AD_BYBY_to"
    include_ac_rules nat
    wifidognx=""
        #wifidogn=`iptables -t nat -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## SS_SPEC
        #if [ -z "$wifidogn" ] ; then
            wifidogn=`iptables -t nat -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
            if [ -z "$wifidogn" ] ; then
                wifidogn=`iptables -t nat -L PREROUTING --line-number | grep vserver | awk '{print $1}' | awk 'END{print $1}'`  ## vserver
                if [ -z "$wifidogn" ] ; then
                    wifidognx=1
                else
                    wifidognx=`expr $wifidogn + 1`
                fi
            else
                wifidognx=`expr $wifidogn + 1`
            fi
        #else
        #    wifidognx=`expr $wifidogn + 1`
        #fi
    wifidognx=$wifidognx
    echo "AD_BYBY-number:$wifidogn"
    iptables -t nat -I PREROUTING $wifidognx -p tcp --dport 80 -j AD_BYBY
    iptables -t nat -A AD_BYBY_to -p tcp -j REDIRECT --to-port 8118
    sleep 1
    gen_include &
    logger -t "【iptables】" "完成添加8118规则"
fi
#去除gfw donmain中与 adbyby host 包含的域名，这部分域名交由adbyby处理。
# 参考的awk指令写法
#  awk  'NR==FNR{a[$0]}NR>FNR{ if($1 in a) print $0}' file1 file2 #找出两文件中相同的值
#  awk  'NR==FNR{a[$0]}NR>FNR{ if(!($1 in a)) print $0}' file1 file2 #去除 file2 中file1的内容
#  awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' file1 file2 #找出两个文件之间的相同部分
#  awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' file1 file2 #去除 file2 中file1的内容
if [ "$ipsets" == 1 ] && [ -s /tmp/adbyby_host.conf ] && [ "$adb" = "C" ] ; then
logger -t "【iptables】" "添加 ipset 转发规则"
sed -Ei '/adbyby_host.conf|cflist.conf/d' /etc/storage/dnsmasq/dnsmasq.conf
    sed  "s/\/adbyby_list/\/adbybylist/" -i  /tmp/adbyby_host.conf
    whitehost=`sed -n 's/.*whitehost=\(.*\)/\1/p' /tmp/bin/adhook.ini`
    [ ! -z $whitehost ] && sed -Ei "/$(echo $whitehost | tr , \|)/d" /tmp/adbyby_host.conf
    [ -f "$confdir$gfwlist" ] && gfw_black=$(grep "/$gfw_black_list" "$confdir$gfwlist" | sed 's/.*\=//g')
    if [ -s "$confdir$gfwlist" ] && [ -s /tmp/adbyby_host.conf ]  && [ ! -z "$gfw_black" ] ; then
        logger -t "【iptables】" "adbybylist 规则处理开始"
        mkdir -p /tmp/b/
        sed -e '/^\#/d' -e "s/ipset=\/www\./ipset=\/\./" -e "s/ipset=\/bbs\./ipset=\/\./" -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\//ipset=\/\./" -i /tmp/adbyby_host.conf
        sed -e '/^\#/d' -e "s/ipset=\/www\./ipset=\/\./" -e "s/ipset=\/bbs\./ipset=\/\./" -e "s/ipset=\/\./ipset=\//" -e "s/ipset=\//ipset=\/\./" -i "$confdir$gfwlist"
        sed -e '/^\#/d' -e "s/ipset=\///" -e "s/adbybylist//" /tmp/adbyby_host.conf > /tmp/b/adbyby_host去干扰.conf
        sed -e '/^\#/d' -e "s/ipset=\///" -e "s/$gfw_black_list//" -e "/server=\//d" "$confdir$gfwlist" > /tmp/b/gfwlist去干扰.conf
        awk 'NR==FNR{a[$0]++} NR>FNR&&a[$0]' /tmp/b/adbyby_host去干扰.conf /tmp/b/gfwlist去干扰.conf > /tmp/b/host相同行.conf
        if [ -s /tmp/b/host相同行.conf ] ; then
            logger -t "【iptables】" "gfwlist 规则处理开始"
            sed -e "s/^/ipset=\//" -e "s/$/adbybylist/" /tmp/b/host相同行.conf > /tmp/b/host相同行2.conf
            awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/b/host相同行2.conf /tmp/adbyby_host.conf > /tmp/b/adbyby_host不重复.conf
            sed -e "s/^/ipset=\//" -e "s/$/$gfw_black_list/" /tmp/b/host相同行.conf > /tmp/b/host相同行2.conf
            awk 'NR==FNR{a[$0]++} NR>FNR&&!a[$0]' /tmp/b/host相同行2.conf "$confdir$gfwlist" > /tmp/b/gfwlist不重复.conf
            sed -e "s/^/ipset=\//" -e "s/$/cflist/" /tmp/b/host相同行.conf > /tmp/b/list重复.conf
            cp -a -v /tmp/b/adbyby_host不重复.conf /tmp/adbyby_host.conf
            cp -a -v /tmp/b/gfwlist不重复.conf "$confdir$gfwlist"
            #rm -f "$confdir/cflist.conf"
            #cp -a -v /tmp/b/list重复.conf "$confdir/cflist.conf"
            cat /tmp/b/list重复.conf >> "$confdir/cflist.conf"
            logger -t "【iptables】" "gfwlist 规则处理完毕"
        fi
        grep -v '^#' $confdir/cflist.conf | sort -u | grep -v "^$" > /tmp/ss/cflist.conf
        grep -v '^#' /tmp/ss/cflist.conf | sort -u | grep -v "^$" > $confdir/cflist.conf
        echo "conf-file=$confdir/cflist.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
    fi
echo "conf-file=/tmp/adbyby_host.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
ipset flush cflist
restart_dhcpd
logger -t "【iptables】" "adbybylist 规则处理完毕"
rm -f /tmp/b/*
fi
sleep 1
/etc/storage/ez_buttons_script.sh 3 &
#restart_dhcpd

EOFAD
chmod 777 "/tmp/sh_adb8118.sh"
cat > "/tmp/sh_mon.sh" <<-\EOF
#!/bin/sh
logger -t "【Adbyby】" "adbyby 进程守护启动"
rm -f /tmp/cron_adb.lock
reb=1
runx="1"
while [ "1" ];
do
if [ -s "/tmp/bin/adbyby" ] ; then
    sleep 61
    if [ ! -f /tmp/cron_adb.lock ] ; then
        if [ "$reb" -gt 5 ] && [ $(cat /tmp/reb.lock) == "1" ] ; then
            LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
            echo '['$LOGTIME'] 网络连接中断['$reb']，reboot.' >> /opt/log.txt 2>&1
            sleep 5
            reboot
        fi
        #wget --continue --no-check-certificate --spider --quiet --timeout=6 www.baidu.com
        #if [ "$?" == "0" ] ; then
        baidu='http://passport.baidu.com/passApi/img/small_blank.gif'
        /tmp/sh_download.sh /tmp/small_blank.gif $baidu
        if [ ! -s /tmp/small_blank.gif ] && [ ! -f /tmp/cron_adb.lock ] ; then
            restart_dhcpd
            sleep 30
            /tmp/sh_download.sh /tmp/small_blank.gif $baidu
        fi
        if [ -s /tmp/small_blank.gif ] && [ ! -f /tmp/cron_adb.lock ] ; then
        reb=1
            PIDS=$(ps | grep "/tmp/bin/adbyby" | grep -v "grep" | grep -v "adbybyupdate.sh" | grep -v "adbybyfirst.sh" | wc -l)
            if [ "$PIDS" = 0 ] ; then 
                logger -t "【Adbyby】" "网络连接正常"
                logger -t "【Adbyby】" "找不到进程, 重启 adbyby"
                /tmp/sh_adb8118.sh D
                killall -15 adbyby
                killall -9 adbyby
                sleep 3
                /tmp/bin/adbyby >/dev/null 2>&1 &
                sleep 20
                reb=`expr $reb + 1`
            fi
            if [ "$PIDS" -gt 2 ] ; then 
                logger -t "【Adbyby】" "进程重复, 重启 adbyby"
                /tmp/sh_adb8118.sh D
                killall -15 adbyby
                killall -9 adbyby
                sleep 3
                /tmp/bin/adbyby >/dev/null 2>&1 &
                sleep 20
            fi
            port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
                if [ "$port" -gt 1 ] && [ ! -f /tmp/cron_adb.lock ] ; then
                    logger -t "【Adbyby】" "有多个8118转发规则, 删除多余"
                    /tmp/sh_adb8118.sh D
                fi
            port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
                if [ "$port" = 0 ] && [ ! -f /tmp/cron_adb.lock ] ; then
                    logger -t "【Adbyby】" "找不到8118转发规则, 重新添加"
                    /tmp/sh_adb8118.sh A
                fi
            runx=`expr $runx + 1`
            if [ "$runx" -gt 720 ] ; then
            runx="1"
            checka="/tmp/var/video.txt"
            rm -f /tmp/var/video.txt
            urla="http://update.adbyby.com/rule3/video.txt"
            checkb="/tmp/bin/data/video.txt"
            wget --continue --no-check-certificate  -O $checka $urla
                if [ "`md5sum $checka|cut -d" " -f1`" != "`md5sum $checkb|cut -d" " -f1`" ] ; then
                    logger -t "【Adbyby】" "守护检查:有更新 $urla , 重启进程"
                    /tmp/sh_adb8118.sh D
                    killall -15 adbyby
                    killall -9 adbyby
                    rm -f /tmp/cron_adb.lock
                    nvram set adbyby_status="restart_firewall"
                    restart_firewall &
                    sleep 62
                else
                    logger -t "【Adbyby】" "守护检查:不需更新 $urla "
                fi
            fi
        else
            # logger -t "【Adbyby】" "网络连接中断 $reb, 关闭 adbyby"
            port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
            while [[ "$port" != 0 ]] 
            do
                logger -t "【Adbyby】" "网络连接中断 $reb, 关闭 adbyby"
                /tmp/sh_adb8118.sh D
                port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
                sleep 5
            done
            PIDS=$(ps | grep "adbyby" | grep -v "grep" | wc -l)
            if [ "$PIDS" != 0 ] ; then 
                killall -15 adbyby
                killall -9 adbyby
            fi
            reb=`expr $reb + 1`
        fi
    fi
    /etc/storage/ez_buttons_script.sh 3 &
fi
if [ ! -f /tmp/cron_adb.lock ] && [ -s "/tmp/bin/adbyby" ] ; then
    PIDS=$(ps | grep "/tmp/bin/adbyby" | grep -v "grep" | grep -v "adbybyupdate.sh" | grep -v "adbybyfirst.sh" | wc -l)
    if [ "$PIDS" != 0 ] ; then
        port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
        if [ "$port" = 0 ] ; then
            logger -t "【Adbyby】" "守护检查:找不到8118转发规则, 重新添加"
            killall -15 adbyby
            killall -9 adbyby
            rm -f /tmp/cron_adb.lock
            nvram set adbyby_status="restart_firewall"
            restart_firewall &
            sleep 62
        fi
    fi
fi
continue
done
EOF
chmod 777 "/tmp/sh_mon.sh"
cat > "/tmp/sh_CPUAverage.sh" <<-\EOF
#!/bin/sh
logger -t "【Adbyby】" "路由器负载监控启动"
while [ "1" ];
do
if [ ! -f /tmp/cron_adb.lock ] ; then
    CPULoad=`uptime |sed -e 's/\ *//g' -e 's/.*://g' -e 's/,.*//g' -e 's/\..*//g'`
    if [ $((CPULoad)) -ge "2" ] ; then
        logger -t "【Adbyby】" "CPU 负载拥堵, 关闭 adbyby"
        /tmp/sh_adb8118.sh D
        killall -15 adbyby
        killall -9 adbyby
        touch /tmp/cron_adb.lock
        while [[ "$CPULoad" -ge "2" ]] 
        do
            sleep 64
            CPULoad=`uptime |sed -e 's/\ *//g' -e 's/.*://g' -e 's/,.*//g' -e 's/\..*//g'`
        done
        logger -t "【Adbyby】" "CPU 负载正常"
        rm -f /tmp/cron_adb.lock
    fi
fi
sleep 63
done
EOF
chmod 777 "/tmp/sh_CPUAverage.sh"
cat > "/tmp/sh_installs.sh" <<-\EOF
#!/bin/sh
ssfile=$1
installs=$2
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
/tmp/sh_upopt.sh
if [ ! -f "/opt/opti.txt" ] ; then
    logger -t "【opt】" "自动安装（覆盖 opt 文件夹）"
    #rm -f /opt/* -R
    logger -t "【opt】" "opt 第一次下载"
    wget --continue --no-check-certificate  -O /opt/opt.tgz $ssfile
    logger -t "【opt】" "opt 下载完成，开始解压"
    tar -xzvf /opt/opt.tgz -C /opt
    if [ ! -s "/opt/opti.txt" ] ; then
        logger -t "【opt】" "/opt/opt.tgz 下载失败"
        rm -f /opt/opt.tgz
        logger -t "【opt】" "opt 第二次下载"
        wget --continue --no-check-certificate  -O /opt/opt.tgz $ssfile
        logger -t "【opt】" "opt 下载完成，开始解压"
        tar -xzvf /opt/opt.tgz -C /opt
    fi
    if [ -s "/opt/opti.txt" ] ; then
        logger -t "【opt】" "opt 解压完成"
        chmod 777 /opt -R
    fi
    
fi
if [ "$installs" = "2" ] ; then
    rm -f /opt/opt.tgz
else

chmod -R 777 /opt/bin/
chmod -R 777 /opt/lib/

fi
EOF
chmod 777 "/tmp/sh_installs.sh"
cat > "/tmp/sh_display.sh" <<-\EOF
#!/bin/sh
### script for hiboy
display_enable=`nvram get display_enable`
[ "$display_enable" != "0" ] && nvram set display_enable=0
exit
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
cp -a -v /etc/storage/display_lcd4linux_script.sh /tmp/lcd4linux.conf
display_enable=`nvram get display_enable`
display_weather=`nvram get display_weather`
display_aqidata=`nvram get display_aqidata`
if [ -z "$display_weather" ] ; then 
display_weather="2151330"
nvram set display_weather="2151330"

fi
if [ -z "$display_aqidata" ] ; then 
display_aqidata="beijing"
nvram set display_aqidata="beijing"
fi


A_restart=`nvram get display_status`
display_lcd4linux_script=`cat /tmp/lcd4linux.conf`
B_restart="$display_enable$display_weather$display_aqidata$display_lcd4linux_script"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set display_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$needed_restart" = "0" ] ; then
    exit 1
fi
[ ${display_enable:=0} ] && [ "$display_enable" -eq "0" ] && [ "$needed_restart" = "1" ] && { logger -t "【相框显示】" "停止程序"; killall lcd4linux getaqidata getweather sh_display.sh; exit 0; }

if [ "$display_enable" = "1" ] ; then
    logger -t "【相框显示】" "启动程序"
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    if [ ! -s "/etc/storage/display_lcd4linux_script.sh" ] || [ ! -s "/opt/bin/lcd4linux" ] ; then
    logger -t "【相框显示】" "下载 https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/lcd.tgz"
    lcd1="https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/lcd.tgz"
    /tmp/sh_download.sh "/opt/lcd.tgz" $lcd1
    /tmp/sh_untar.sh "/opt/lcd.tgz" "/opt/" "/opt/bin/lcd4linux"
    cp -a -v /opt/lcd4linux/lcd4linux.conf /etc/storage/display_lcd4linux_script.sh
    fi
    if [ ! -s "/etc/storage/display_lcd4linux_script.sh" ] ; then
        logger -t "【相框显示】" "缺少 /etc/storage/display_lcd4linux_script.sh 文件, 启动失败"
        logger -t "【相框显示】" "停止程序"
        killall lcd4linux getaqidata getweather sh_display.sh
        exit 0
    else
    hash lcd4linux 2>/dev/null || {  logger -t "【相框显示】" "找不到 lcd4linux, 需要手动安装 lcd4linux"; exit 0; }
    killall lcd4linux
    chmod 777 /opt/lcd4linux/scripts/getweather
    chmod 777 /opt/lcd4linux/scripts/getaqidata
    # 在.conf中定时执行程序
    #/opt/lcd4linux/scripts/getweather
    #/opt/lcd4linux/scripts/getaqidata
    chmod 777 /etc/storage/display_lcd4linux_script.sh
    # 修改显示空间
    upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | sed -n '1p'`
    if [ -z "$upanPath" ] ; then 
        upanPath2="SpaceDir  \'\/tmp\' #显示空间"
    else
        upanPath2="SpaceDir  \'\/media\/$upanPath\' #显示空间"
    fi
    sed -e "s/SpaceDir\ \ .*/$upanPath2/" -i /etc/storage/display_lcd4linux_script.sh
    cp -a -v /etc/storage/display_lcd4linux_script.sh /tmp/lcd4linux.conf
    chmod 600 /tmp/lcd4linux.conf
    chmod 777 /opt/bin/lcd4linux
    lcd4linux -f /tmp/lcd4linux.conf
    logger -t "【相框显示】" "开始显示数据"
    display_lcd4linux_script=`cat /tmp/lcd4linux.conf`
    B_restart="$display_enable$display_weather$display_aqidata$display_lcd4linux_script"
    B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
    nvram set display_status=$B_restart
    fi
fi


EOF
chmod 777 "/tmp/sh_display.sh"
cat > "/tmp/sh_xun_lei.sh" <<-\EOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
xunleis=`nvram get xunleis`
xunleis_dir=`nvram get xunleis_dir`
[ -z $xunleis_dir ] || [ ! -d "$xunleis_dir" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | sed -n '1p'` && [ ! -z $upanPath ] && nvram set xunleis_dir=/media/$upanPath
xunleis_dir=`nvram get xunleis_dir`
xunleiPath=$xunleis_dir/xunlei
if [ "$xunleis" = "0" ] ; then
nvram set xunleis_sn=""
[ ! -z "`pidof ETMDaemon`" ] && { killall -9 ETMDaemon ; killall -9 EmbedThunderManager ; killall -9 vod_httpserver ; killall -9 sh_Thunder.sh ; killall portal ; } 
fi
if [ -z "`pidof ETMDaemon`" ] && [ "$xunleis" = "1" ] ; then
    { killall -9 ETMDaemon ; killall -9 EmbedThunderManager ; killall -9 vod_httpserver ; killall -9 sh_Thunder.sh ; killall portal ; } 
    if [ ! -d "$xunleis_dir" ] ; then 
        logger -t "【迅雷下载】" "未挂载储存设备, 请重新检查配置、目录:$xunleis_dir "
        exit
    fi
    killall -9 sh_Thunder.sh
    [ ! -d $xunleiPath ] && mkdir -p -m 777 $xunleiPath
    logger -t "【迅雷下载】" "启动程序"
    [ -f "$xunleiPath/portal" ] && portal_md5=`md5sum "$xunleiPath/portal" | awk -F ' ' '{print $1}'`
    xunleimd5="86f8c2c931687c4876bdd8ca5febe038"
    if [ ! -s $xunleiPath"/lib/libgcc_s.so.1" ] || [ $portal_md5 != $xunleimd5 ] ; then
    logger -t "【迅雷下载】" "Xware1.0.31_mipsel_32_uclibc"
    Xware1="https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/Xware1.0.31_mipsel_32_uclibc.tgz"
    /tmp/sh_download.sh "$xunleiPath/Xware1.tgz" $Xware1
    /tmp/sh_untar.sh $xunleiPath"/Xware1.tgz" $xunleiPath "$xunleiPath/portal"
    fi
    [ -f "$xunleiPath/portal" ] && portal_md5=`md5sum "$xunleiPath/portal" | awk -F ' ' '{print $1}'`
    xunleimd5="86f8c2c931687c4876bdd8ca5febe038"
    if [ $portal_md5 != $xunleimd5 ] ; then
        rm -rf "$xunleiPath/Xware1.tgz" "$xunleiPath/portal"
        logger -t "【迅雷下载】" "xunlei 缺少 portal 文件"
        { killall -9 ETMDaemon ; killall -9 EmbedThunderManager ; killall -9 vod_httpserver ; killall portal ; }
        logger -t "【迅雷下载】" "启动失败, 注意检查"$xunleiPath/portal", 10秒后自动尝试重新启动" && sleep 10 && /tmp/sh_xun_lei.sh &
    else
        chmod 777 "$xunleiPath/portal"
        #[ -f /opt/lib/libgcc_s.so.1 ] && cp -a -f /lib/libgcc_s.so.1 /opt/lib/libgcc_s.so.1
        #chmod 777 "/opt/lib/libgcc_s.so.1"
        chmod 777 $xunleiPath -R
        rm -f /tmp/xunlei.info
        export LD_LIBRARY_PATH="$xunleiPath/lib"
        cd $xunleiPath
        "$xunleiPath/portal"&
        sleep 44
        /tmp/sh_download.sh "/tmp/xunlei.info" "http://127.0.0.1:9000/getsysinfo" "http://127.0.0.1:9001/getsysinfo"
        [ ! -f /tmp/xunlei.info ] && /tmp/sh_download.sh "/tmp/xunlei.info" "http://`nvram get lan_ipaddr`:9002/getsysinfo" "http://`nvram get lan_ipaddr`:9003/getsysinfo"
        logger -t "【迅雷下载】" "启动 xunlei, 绑定设备页面【http://yuancheng.xunlei.com】"
        logger -t "【迅雷下载】" "在浏览器中输入【http://`nvram get lan_ipaddr`:9000/getsysinfo】"
        logger -t "【迅雷下载】" "显示错误则输入【http://`nvram get lan_ipaddr`:9001/getsysinfo】"
        logger -t "【迅雷下载】" "会看到类似如下信息："
        logger -t "【迅雷下载】" "`cat /tmp/xunlei.info | sed s/[[:space:]]//g `"
        nvram set xunleis_sn=`cat /tmp/xunlei.info | sed s/[[:space:]]//g | sed s/"\["//g | sed s/"\]"//g`
        logger -t "【迅雷下载】" "其中有用的几项为："
        logger -t "【迅雷下载】" "①: 0表示返回结果成功"
        logger -t "【迅雷下载】" "②: 1表示检测网络正常, 0表示检测网络异常"
        logger -t "【迅雷下载】" "④: 1表示已绑定成功, 0表示未绑定"
        logger -t "【迅雷下载】" "⑤: 未绑定的情况下, 为绑定的需要的激活码"
        logger -t "【迅雷下载】" "⑥: 1表示磁盘挂载检测成功, 0表示磁盘挂载检测失败"
        logger -t "【迅雷下载】" "如果出现错误可以手动启动, 输入以下命令测试"
        logger -t "【迅雷下载】" "export LD_LIBRARY_PATH=$xunleiPath/lib ; $xunleiPath/portal"
        /tmp/sh_Thunder.sh &
    fi
fi

EOF
chmod 777 "/tmp/sh_xun_lei.sh"
cat > "/tmp/sh_ssmon.sh" <<-\EOF
#!/bin/sh
cat > "/tmp/sh_ssmon_k.sh" <<-\SSMK
#!/bin/sh
ss_enable=`nvram get ss_enable`
if [ ! -f /tmp/cron_ss.lock ] && [ "$ss_enable" = "1" ] ; then
eval $(ps  | grep "/tmp/sh_ssmon.sh" | grep -v grep | awk '{print "kill "$1}')
/tmp/sh_ssmon.sh &
fi
SSMK
chmod 777 "/tmp/sh_ssmon_k.sh"
eval $(ps  | grep "sleep 919" | grep -v grep | awk '{print "kill "$1}')
{ sleep 919; /tmp/sh_ssmon_k.sh ; } &
rebss=1
ss_rdd_server=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=`nvram get kcptun2_enable2`
kcptun2_enable2=${kcptun2_enable2:-"0"}
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_mode_x=`nvram get ss_mode_x`
ss_mode_x=${ss_mode_x:-"0"}
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
rm -f /tmp/cron_ss.lock
ss_enable=`nvram get ss_enable`
while [ "$ss_enable" = "1" ];
do
ss_internet=`nvram get ss_internet`
sleep 9
#随机延时
if [ "$ss_internet" = "1" ] ; then
    SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
    RND_NUM=`echo $SEED 60 200|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
    sleep $RND_NUM
fi
/etc/storage/ez_buttons_script.sh 3 &
ss_enable=`nvram get ss_enable`
if [ ! -f /tmp/cron_ss.lock ] && [ "$ss_enable" = "1" ] ; then
    if [ "$rebss" -gt 6 ] && [ $(cat /tmp/reb.lock) == "1" ] ; then
        LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")
        logger -t "【SS】" "['$LOGTIME'] 网络连接 shadowsocks 中断['$rebss'], 重启路由."
        sleep 5
        reboot
    fi
    if [ "$rebss" -gt 6 ] ; then
    if [ "$kcptun2_enable" = "1" ] || [ -z $ss_rdd_server ] ; then
        logger -t "【SS】" "[$LOGTIME] 网络连接 shadowsocks 中断 ['$rebss'], 重启SS."
        /etc/storage/ez_buttons_script.sh cleanss &
        sleep 5
        exit 0
    fi
    fi
    if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
    NUM=`ps | grep ss-local_ | grep -v grep |wc -l`
    SSRNUM=1
    [ ! -z $ss_rdd_server ] && SSRNUM=2
    if [ "$NUM" -lt "$SSRNUM" ] ; then
        logger -t "【SS】" "找不到 $SSRNUM ss-local 进程 $rebss, 重启SS."
        /etc/storage/ez_buttons_script.sh cleanss &
        sleep 5
        exit 0
    fi
    fi
    if [ "$ss_mode_x" != "3" ] ; then
    NUM=`ps | grep ss-redir_ | grep -v grep |wc -l`
    SSRNUM=1
    [ ! -z $ss_rdd_server ] && SSRNUM=2
    if [ "$NUM" -lt "$SSRNUM" ] ; then
        logger -t "【SS】" "找不到 $SSRNUM shadowsocks 进程 $rebss, 重启SS."
        /etc/storage/ez_buttons_script.sh cleanss &
        sleep 5
        exit 0
    fi
    if [ -z "`pidof pdnsd`" ] ; then
        logger -t "【SS】" "找不到 pdnsd 进程 $rebss，重启 pdnsd"
        /tmp/ss.sh repdnsd &
    fi
    #SS进程监控和双线切换
    #思路：
    #先将所有ss通道全部拉起来，默认服务器为1090端口，新服务器为1091端口，默认走通道0，DNS的ss-tunnel 走8053 和 8054
    #检查SS通道是否可以连接google，如果不能，则看看百度是否正常，如果百度正常，而google无法打开，则说明当前SS通道有问题
    #通道有问题时，先logger记录，然后切换SS通道端口和修改 
    # sh_ssmon 建议不要重启网络，会导致断线。正常来说,ss服务基本上稳定不需要重启，我公司路由的ss客户端跑20多台机器将近3个多月没动过了。



    LOGTIME=$(date "+%Y-%m-%d %H:%M:%S")

    #检查是否存在当前SS服务器，没有则设为0，准备切换服务器设为1
    CURRENT=`nvram get ss_working_port`
    ss_udp_enable=`nvram get ss_udp_enable` #udp转发  0、停用；1、启动
    ss_upd_rules=`nvram get ss_upd_rules`
    ss_pdnsd_wo_redir=`nvram get ss_pdnsd_wo_redir` #pdnsd  1、直连；0、走代理

    [ ${CURRENT:=1090} ] && [ $CURRENT == 1091 ] && Server=1090 || Server=1091

    #检查是否存在SS备份服务器, 这里通过判断 ss_rdd_server 是否填写来检查是否存在备用服务器


    wget --continue --no-check-certificate -s -q -T 10 www.baidu.com
    if [ "$?" == "0" ] ; then
        echo "[$LOGTIME] Internet have no problem."
    else
        sleep 5
        wget --continue --no-check-certificate -s -q -T 10 www.baidu.com
        if [ "$?" == "0" ] ; then
            echo "[$LOGTIME] Internet have no problem."
        else
            logger -t "【SS】" "[$LOGTIME] Internet 问题, 请检查您的服务供应商."
            rebss=`expr $rebss + 1`
            restart_dhcpd ; sleep 1
        fi
    fi
    wget --continue --no-check-certificate -s -q -T 10 www.google.com.hk
    if [ "$?" == "0" ] ; then
        echo "[$LOGTIME] SS $CURRENT have no problem."
        rebss="1"
        nvram set ss_internet="1"
    else
        sleep 5
    if [ -n "`pidof ss-redir`" ] && [ "$ss_enable" = "1" ] && [ "$ss_mode_x" != "3" ] ; then
        port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
        if [ "$port" = 0 ] ; then
            sleep 35
        fi
        port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
        if [ "$port" = 0 ] ; then
            logger -t "【SS】" "检测:找不到 SS_SPEC 转发规则, 重新添加"
            /tmp/ss.sh rules
            restart_dhcpd
            sleep 5
        fi
    fi
        wget --continue --no-check-certificate -s -q -T 10 www.google.com.hk
        if [ "$?" == "0" ] ; then
            echo "[$LOGTIME] SS $CURRENT have no problem."
            rebss="1"
            nvram set ss_internet="1"
        else
        if [ "$kcptun2_enable" = "1" ] ; then
            nvram set ss_internet="2"
            rebss=`expr $rebss + 2`
            logger -t "【SS】" "[$LOGTIME] SS 服务器 $CURRENT 检测到问题, $rebss"
            #跳出当前循环
            continue
        fi
        if [ ! -z $ss_rdd_server ] ; then
            logger -t "【SS】" "[$LOGTIME] SS $CURRENT 检测到问题, 尝试切换到 SS $Server"
            nvram set ss_internet="2"
            #端口切换
            iptables -t nat -D SS_SPEC_WAN_FW -p tcp -j REDIRECT --to-port $CURRENT
            iptables -t nat -A SS_SPEC_WAN_FW -p tcp -j REDIRECT --to-port $Server
            if [ "$ss_udp_enable" == 1 ] ; then
                iptables -t mangle -D SS_SPEC_WAN_FW -p udp -j TPROXY --on-port $CURRENT --tproxy-mark 0x01/0x01
                iptables -t mangle -A SS_SPEC_WAN_FW -p udp -j TPROXY --on-port $Server --tproxy-mark 0x01/0x01
            fi
            if [ "$ss_pdnsd_wo_redir" == 0 ] ; then
            # pdnsd 是否直连  1、直连；0、走代理
                iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port $CURRENT
                iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port $CURRENT
                iptables -t nat -I OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port $Server
                iptables -t nat -I OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port $Server
            fi
            #加上切换标记
            nvram set ss_working_port=$Server
            #检查切换后的状态
            TAG="SS_SPEC"          # iptables tag
            FWI="/tmp/firewall.shadowsocks.pdcn" # firewall include file

cat <<-CATIP >>$FWI
iptables-restore -n <<-EOFIP
$(iptables-save | grep -E "$TAG|^\*|^COMMIT" |sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOFIP
CATIP

        fi
        restart_dhcpd
        sleep 5
        wget --continue --no-check-certificate -s -q -T 10 www.google.com.hk
        if [ "$?" == "0" ] ; then
            logger -t "【SS】" "[$LOGTIME] SS 服务器 `nvram get ss_working_port` 连接."
            #exit 0
        else
            nvram set ss_internet="0"
            [ ! -z $ss_rdd_server ] && logger -t "【SS】" "[$LOGTIME] 两个 SS 服务器检测到问题, $rebss"
            [ -z $ss_rdd_server ] && logger -t "【SS】" "[$LOGTIME]  SS 服务器 $CURRENT 检测到问题, $rebss"
            rebss=`expr $rebss + 1`
            restart_dhcpd
            #/etc/storage/crontabs_script.sh &
        fi
        fi
    fi
    fi

fi

done


EOF
chmod 777 "/tmp/sh_ssmon.sh"
cat > "/tmp/sh_syncyquota.sh" <<-\EOF
#!/bin/sh
logger -t "【SyncY】" "等待 SyncY 同步软件启动, SyncY 同步软件技术博客：http://www.syncy.cn/"
while [ ! -s "/tmp/syncy.quota" ] 
do
    sleep 11
    if [ -s "/tmp/syncy.user_code" ] ; then
        user_code_log=`cat /tmp/syncy.user_code`
        logger -t "【SyncY】" "$user_code_log"
        logger -t "【SyncY】" "打开百度授权页面 https://openapi.baidu.com/device"
        logger -t "【SyncY】" "输入用户码【$user_code_log】（请在100秒内输入用户码）"
        while [ ! -s "/tmp/syncy.user_token" ] 
        do
            sleep 12
            if [ -s "/tmp/syncy.user_token" ] ; then
                user_code_log=`cat /tmp/syncy.user_token`
                logger -t "【SyncY】" "$user_code_log"
                logger -t "【SyncY】" "显示【Get device token success.】表示授权完成。"
            fi
        done
    fi
done
[ -s "/tmp/syncy.quota" ] && /tmp/sh_syncyd.sh &
user_code_log=`cat /tmp/syncy.quota`
logger -t "【SyncY】" "$user_code_log"
logger -t "【SyncY】" "SyncY 同步启动成功"
logger -t "【SyncY】" "SyncY 同步软件技术博客:http://www.syncy.cn/"
EOF
chmod 777 "/tmp/sh_syncyquota.sh"
cat > "/tmp/sh_syncyd.sh" <<-\EOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
logger -t "syncy" "SyncY守护进程启动"
pid_file="/var/run/syncy.pid"
start_cmd="/opt/etc/syncy.py &"

while true; do
    localpath=`cat /opt/etc/syncy |grep "localpath" | sed "s/option localpath//g" | sed "s/'//g" | sed "s/#本地同步目录//g"`
    if [ ! -d `echo $localpath` ] ; then
                logger -t "【SyncY】" "错误！！路由器本地同步目录不存在！！"
                logger -t "【SyncY】" "$localpath 设置错误！！请检查U盘文件和设置"
    fi
    running=$(ps | grep "/opt/etc/syncy.py" | grep -v "grep" | wc -l)
    if [ $running -le 0 ] ; then
        cd /opt/etc
        export LD_LIBRARY_PATH=/lib:/opt/lib
        python /opt/etc/syncy.py &
        #eval $start_cmd
        echo "start syncy"
        logger -t "【SyncY】" "SyncY 重新启动"
    else
        echo "syncy is running"
    fi
    sleep 65
done

EOF
chmod 777 "/tmp/sh_syncyd.sh"
cat > "/tmp/sh_orayd.sh" <<-\EOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
logger -t "【花生壳内网版】" "守护进程启动"
online=""
orayslstatus=""
onlinetest()
{
    USER_DATA="/tmp/oraysl.status"
    orayslstatus=`head -n 3 $USER_DATA`
    SN=`head -n 2 $USER_DATA  | tail -n 1 | cut -d= -f2-`;
    STATUS=`head -n 3 $USER_DATA  | tail -n 1 | cut -d= -f2-`;
    szUID=`sed -n 's/.*szUID=*/\1/p' /etc/storage/PhMain.ini`
    nvram set phddns_sn=$SN
    nvram set phddns_st=$STATUS
    nvram set phddns_szUID=$szUID
    online=$(echo $orayslstatus | grep "ONLINE" | wc -l)
}
onlinetest
while [ $online -le 0 ]; do
    sleep 68
    onlinetest
    logger -t "【花生壳内网版】" "$online"
done
logger -t "【花生壳内网版】" "ONLINE"
while true; do
    sleep 68
    onlinetest
    running=$(ps | grep "oraynewph -s 0.0.0.0" | grep -v "grep" | wc -l)
    running2=$(ps | grep "oraysl -a 127.0.0.1" | grep -v "grep" | wc -l)
    if [ $running -gt 1 ] || [ $running2 -gt 1 ] ; then
        logger -t "【花生壳内网版】" "状态:【$orayslstatus 】, 进程重复, 重新启动"
        killall oraynewph oraysl
    fi
    onlinetest
    if [ ! -n "`pidof oraynewph`" ] || [ ! -n "`pidof oraysl`" ] || [ $online -le 0 ] ; then
        killall oraynewph oraysl
        logger -t "【花生壳内网版】" "状态:【$orayslstatus 】, 重新启动"
        /tmp/sh_phddns.sh &
        echo "oray is running2"
    else
        echo "oray is running"
    fi
done

EOF
chmod 777 "/tmp/sh_orayd.sh"
cat > "/tmp/sh_Thunder.sh" <<-\EOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
xunleis_dir=`nvram get xunleis_dir`
[ -z $xunleis_dir ] || [ ! -d "$xunleis_dir" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | sed -n '1p'` && [ ! -z $upanPath ] && nvram set xunleis_dir=/media/$upanPath
xunleis_dir=`nvram get xunleis_dir`
xunleiPath=$xunleis_dir/xunlei
logger -t "【迅雷下载】" "守护进程启动 $upanPath"
if [ -s $xunleiPath/portal ] ; then
    while true; do
        running=$(ps | grep "/xunlei/lib/" | grep -v "grep" | wc -l)
        if [ $running -le 2 ] || [ ! -s $xunleiPath/portal ] ; then
            [ "$xunleis" = "1" ] && { killall -9 ETMDaemon ; killall -9 EmbedThunderManager ; killall -9 vod_httpserver ; killall portal ; }
            /tmp/sh_xun_lei.sh &
            logger -t "【迅雷下载】" "重新启动"
        else
            echo "xunlei is running"
        fi
        sleep 71
    done
else
    logger -t "【迅雷下载】" "找不到文件 $xunleiPath/portal"
    { killall -9 ETMDaemon ; killall -9 EmbedThunderManager ; killall -9 vod_httpserver ; killall portal ; }
    logger -t "【迅雷下载】" "启动失败, 注意检查"$xunleiPath/portal", 10秒后自动尝试重新启动" && sleep 10 && /tmp/sh_xun_lei.sh &
fi
EOF
chmod 777 "/tmp/sh_Thunder.sh"
cat > "/tmp/sh_FastDick.sh" <<-\EOF
#!/bin/sh
#copyright by hiboy
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
uid=`nvram get FastDick_uid`
pwd=`nvram get FastDick_pwd`
FastDick_enable=`nvram get FastDick_enable`
FastDicks=`nvram get FastDicks`

A_restart=`nvram get FastDicks_status`
B_restart="$uid$pwd$FastDick_enable$FastDicks"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set FastDicks_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi

if [ "$needed_restart" = "1" ] ; then
killall FastDick_script.sh
[ "$FastDick_enable" = "0" ] && eval $(ps  | grep "/opt/FastDick/swjsq" | grep -v grep | awk '{print "kill "$1}')
fi
if [ "$FastDick_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
    killall FastDick_script.sh
    eval $(ps  | grep "/opt/FastDick/swjsq" | grep -v grep | awk '{print "kill "$1}')
    logger -t "【迅雷快鸟】" "迅雷快鸟(diǎo)路由器版:https://github.com/fffonion/Xunlei-FastDick"
    if [ "$FastDicks" = "2" ] ; then
        logger -t "【迅雷快鸟】" "稍等几分钟，ssh 到路由，控制台输入【ps】命令查看[/opt/FastDick/swjsq_wget.sh]进程是否存在，是否正常启动，提速是否成功。"
        logger -t "【迅雷快鸟】" "免 U盘 启动"
        chmod 777 "/etc/storage/FastDick_script.sh"
        /etc/storage/FastDick_script.sh &
    else
        hash python 2>/dev/null || {  logger -t "【迅雷快鸟】" "无法找到 python 程序，请检查系统"; exit 1; }
        rm -f "/opt/FastDick/" -R
        mkdir -p "/opt/FastDick"
        swjsqfile="https://raw.githubusercontent.com/fffonion/Xunlei-FastDick/master/swjsq.py"
        /tmp/sh_download.sh "/opt/FastDick/swjsq.py" $swjsqfile
        chmod 777 "/opt/FastDick/swjsq.py"
        logger -t "【迅雷快鸟】" "程序下载完成, 正在启动 python /opt/FastDick/swjsq.py"
        echo "$uid,$pwd" >/opt/FastDick/swjsq.account.txt
        chmod 777 /opt/FastDick -R
        cd /opt/FastDick
        export LD_LIBRARY_PATH=/lib:/opt/lib
        python /opt/FastDick/swjsq.py 2>&1 > /opt/FastDick/swjsq.log &
        chmod 777 "/opt/FastDick" -R
        sleep 30
        chmod 777 "/opt/FastDick" -R
        if [ -f /opt/FastDick/swjsq_wget.sh ] ; then
        logger -t "【迅雷快鸟】" "自动备份 swjsq 文件到路由, 【写入内部存储】后下次重启可以免U盘启动了"
            cat > "/etc/storage/FastDick_script.sh" <<-\EEF
#!/bin/sh
            # 迅雷快鸟【2免U盘启动】功能需到【自定义脚本0】配置【FastDicks=2】，并在此输入swjsq_wget.sh文件内容
            #【2免U盘启动】需要填写在下方的【迅雷快鸟脚本】，生成脚本两种方法：
            # ①插入U盘，配置自定义脚本【1插U盘启动】启动快鸟一次即可自动生成
            # ②打开https://github.com/fffonion/Xunlei-FastDick，按照网页的说明在PC上运行脚本，登陆成功后会生成swjsq_wget.sh，把swjsq_wget.sh的内容粘贴此处即可
            # 生成后需要到【系统管理】 - 【恢复/导出/上传设置】 - 【路由器内部存储 (/etc/storage)】【写入】保存脚本
EEF
            cat /opt/FastDick/swjsq_wget.sh >> /etc/storage/FastDick_script.sh
            chmod 777 "/etc/storage/FastDick_script.sh"
        fi
        logger -t "【迅雷快鸟】" "启动完成`cat /opt/FastDick/swjsq.log`"
    fi
fi
EOF
chmod 777 "/tmp/sh_FastDick.sh"
cat >/tmp/qos_scheduler.sh <<-\EOF
#!/bin/sh
qosc=$1
echo 0 >/tmp/qos_scheduler.lock
logger -t "【QOS】" "终端在线检查启动"
while [ "1" ];
do
    if [ "$(cat /tmp/qoss_state)" == "0" ] ; then
    logger -t "【QOS】" "终端在线检查暂停"
    rm -f /tmp/qos_scheduler.lock
    exit
    fi
    #qos_t=`cat /proc/net/arp|fgrep -c 0x2`
    qos_t=`cat /tmp/static_ip.num`
    qos_t=`expr $qos_t + 1`
    if [ $((qos_t)) -le $qosc ] ; then
        if [ $(ifconfig |grep -c imq0) -gt 0 ] ; then
        logger -t "【QOS】" "取消限速, 当在线 $qos_t台, 小于或等于 $qosc 台"
            ip link set imq0 down
            ip link set imq1 down
        fi
    else
        if [ $(ifconfig |grep -c imq0) -eq 0 ] ; then
            logger -t "【QOS】" "开始限速, 当在线 $qos_t台, 大于 $qosc 台"
            ip link set imq0 up
            ip link set imq1 up
            sleep 6
            port=$(iptables -t mangle -L | grep 'IMQ: todev 0' | wc -l)
            if [ "$port" = 0 ] ; then
                logger -t "【QOS】" "找不到 QOS 规则, 重新添加"
                /etc/storage/post_iptables_script.sh&
            fi
            
        fi
    fi
    sleep 69
continue
done
EOF
chmod 777 "/tmp/qos_scheduler.sh"
cat > "/tmp/sh_reFastDick.sh" <<-\EOF
#!/bin/sh
if [ "`nvram get FastDick_enable`" = "1" ] ; then
    logger -t "【迅雷快鸟】" "重新启动中……"
    killall FastDick_script.sh
    eval $(ps  | grep "/opt/FastDick/swjsq" | grep -v grep | awk '{print "kill "$1}')
    logger -t "【迅雷快鸟】" "已经关闭，1分钟后启动" && sleep 60
    logger -t "【迅雷快鸟】" "启动 /etc/storage/FastDick_script.sh"
    /etc/storage/FastDick_script.sh &
fi
EOF
chmod 777 "/tmp/sh_reFastDick.sh"
cat > "/tmp/sh_downloads_adblock.sh" <<-\EOF
#!/bin/sh
adblocks=`nvram get adbyby_adblocks`
rm -f /tmp/bin/data/user.bin
rm -f /tmp/bin/data/user.txt
if [ "$adblocks" = "1" ] ; then
    mkdir -p /tmp/data
    logger -t "【Adbyby】" "下载 adblock 规则"
    rm -f /tmp/bin/data/user3adblocks.txt
    while read line
    do
    c_line=`echo $line |grep -v "#"`
    if [ ! -z "$c_line" ] ; then
        logger -t "【Adbyby】" "下载规则:$line"
        /tmp/sh_download.sh /tmp/bin/data/user2.txt $line
        grep -v '^!' /tmp/bin/data/user2.txt | grep -E '^(@@\||\||[[:alnum:]])' | sort -u | grep -v "^$" >> /tmp/bin/data/user3adblocks.txt
        rm -f /tmp/bin/data/user2.txt
    fi
    done < /tmp/rule_DOMAIN.txt
fi
grep -v '^!' /etc/storage/adbyby_rules_script.sh | grep -v "^$" > /tmp/bin/data/user_rules.txt
EOF
chmod 777 "/tmp/sh_downloads_adblock.sh"

cat > "/tmp/sh_white_list.sh" <<-\EOF
#!/bin/sh
whitelist=`nvram get adbyby_whitehost_x`
whitehost=`nvram get adbyby_whitehost`
ipsets=`nvram get adbyby_mode_x`
if [ "$whitelist" = "1" ] ; then
    logger -t "【Adbyby】" "添加过滤白名单地址"
    logger -t "【Adbyby】" "加白地址:$whitehost"
    sed -Ei '/whitehost=/d' /tmp/bin/adhook.ini
    echo whitehost=$whitehost >> /tmp/bin/adhook.ini
    echo @@\|http://\$domain=$(echo $whitehost | tr , \|) >> /tmp/bin/data/user_rules.txt
fi
if [ "$ipsets" == 1 ] ; then
    logger -t "【Adbyby】" "添加 ipset 过滤设置"
    sed -Ei '/ipset=/d' /tmp/bin/adhook.ini
    echo ipset=1 >> /tmp/bin/adhook.ini
    sed -Ei '/sh_adb8118.sh|restart_dhcpd/d' /tmp/bin/adbybyfirst.sh /tmp/bin/adbybyupdate.sh
    echo "/tmp/sh_adb8118.sh C" >> /tmp/bin/adbybyfirst.sh
    echo "/tmp/sh_adb8118.sh C" >> /tmp/bin/adbybyupdate.sh
else
    sed -Ei '/ipset=/d' /tmp/bin/adhook.ini
    echo ipset=0 >> /tmp/bin/adhook.ini
    sed -Ei '/sh_adb8118.sh|restart_dhcpd/d' /tmp/bin/adbybyfirst.sh /tmp/bin/adbybyupdate.sh
fi
EOF
chmod 777 "/tmp/sh_white_list.sh"
cat > "/tmp/sh_func_load_adbyby.sh" <<-\EOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

adbybys=`nvram get adbyby_enable`
ipsets=`nvram get adbyby_mode_x`
adbybyfile=`nvram get adbybyfile`
adbybyfile2=`nvram get adbybyfile2`
adblocks=`nvram get adbyby_adblocks`
ss_sub4=`nvram get ss_sub4`
CPUAverages=`nvram get adbyby_CPUAverages`
whitelist=`nvram get adbyby_whitehost_x`
whitehost=`nvram get adbyby_whitehost`
lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get adbyby_status`
B_restart="$adbybys$ipsets$adbybyfile$adbybyfile2$adblocks$CPUAverages$ss_sub4$whitelist$whitehost$lan_ipaddr$(cat /etc/storage/ad_config_script.sh | grep -v "^$" | grep -v "^#")$(cat /etc/storage/adbyby_rules_script.sh | grep -v "^$" | grep -v "^!")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set adbyby_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$needed_restart" = "0" ] ; then
if [ ! -f /tmp/cron_adb.lock ] && [ -s "/tmp/bin/adbyby" ] && [ "$adbybys" = "1" ] ; then
    PIDS=$(ps | grep "/tmp/bin/adbyby" | grep -v "grep" | grep -v "adbybyupdate.sh" | grep -v "adbybyfirst.sh" | wc -l)
    if [ "$PIDS" != 0 ] ; then
        port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
        if [ "$port" = 0 ] ; then
            logger -t "【Adbyby】" "定时检查:找不到8118转发规则, 重新添加"
            /tmp/sh_adb8118.sh A
        fi
    fi
fi
fi
if [ "$needed_restart" = "1" ] ; then
    nvram set adbybylazy="【adbyby未启动】lazy更新："
    nvram set adbybyvideo="【adbyby未启动】video更新："
    nvram set adbybyuser3="第三方规则行数：行"
    nvram set adbybyuser="自定义规则行数：行"
    killall -9 adbyby ; killall -15 adbyby ; killall sh_mon.sh ; killall sh_CPUAverage.sh ;
    [ "$(iptables -t nat -L | grep 'ports 8118' | wc -l)" != "0" ] && /tmp/sh_adb8118.sh D &
    sleep 1
    [ "$(iptables -t nat -L | grep 'ports 8118' | wc -l)" != "0" ] && /tmp/sh_adb8118.sh D &
    /etc/storage/ez_buttons_script.sh 3 &
    sleep 1
    [ "$adbybys" = "0" ] && { rm -f /tmp/cron_adb.lock; killall sh_func_load_adbyby.sh; }
fi
[ "$needed_restart" = "1" ] && { killall -9 adbyby ; killall -15 adbyby ; killall sh_mon.sh ; killall sh_CPUAverage.sh ; }
if [ -z "`pidof adbyby`" ] && [ "$adbybys" = "1" ] && [ ! -f /tmp/cron_adb.lock ] ; then
    sleep 1
    touch /tmp/cron_adb.lock
    nvram set button_script_1_s="Adbyby"
    killall sh_mon.sh
    killall sh_CPUAverage.sh
    /tmp/sh_adb8118.sh D
    killall -15 adbyby
    killall -9 adbyby
    sed -e '/^$/d' -i /etc/storage/dnsmasq/hosts
    sed -e '/.*127.0.0.1.*update.adbyby.com.*/d' -i /etc/storage/dnsmasq/hosts
    sed -e '/.*119.147.134.192.*update.adbyby.com/d' -i /etc/storage/dnsmasq/hosts
    sed -e '/.*210.14.141.213.*update.adbyby.com/d' -i /etc/storage/dnsmasq/hosts
    sed -e '/^$/d' -i /etc/storage/dnsmasq/dnsmasq.servers
    sed -Ei '/.*update.adbyby.com\/180.76.76.76.*/d' /etc/storage/dnsmasq/dnsmasq.servers
        wget --continue --no-check-certificate -s -q -T 10 http://update.adbyby.com/rule3/video.txt
    if [ "$?" == "0" ] ; then
        echo "[$LOGTIME] update.adbyby.com have no problem."
        rm -rf /tmp/bin/data/video_B.txt /tmp/bin/data/lazy_B.txt
    else
        mkdir -p /tmp/bin/data
        logger -t "【Adbyby】" "下载规则失败, 强制 手动同步更新规则"
        xwhyc_rules="https://raw.githubusercontent.com/adbyby/xwhyc-rules/master/video.txt"
        logger -t "【Adbyby】" "下载规则:$xwhyc_rules"
        /tmp/sh_download.sh /tmp/bin/data/video.txt $xwhyc_rules
        mv -f /tmp/bin/data/video.txt /tmp/bin/data/video_B.txt
        xwhyc_rules="https://raw.githubusercontent.com/adbyby/xwhyc-rules/master/lazy.txt"
        logger -t "【Adbyby】" "下载规则:$xwhyc_rules"
        /tmp/sh_download.sh /tmp/bin/data/lazy.txt $xwhyc_rules
        mv -f /tmp/bin/data/lazy.txt /tmp/bin/data/lazy_B.txt
    fi
    if [ ! -s "/tmp/bin/adbyby" ] ; then
        logger -t "【Adbyby】" "开始下载 7620n.tar.gz"
        /tmp/sh_download.sh /tmp/7620n.tar.gz $adbybyfile $adbybyfile2
        /tmp/sh_untar.sh /tmp/7620n.tar.gz /tmp /tmp/bin/adbyby
    fi
    if [ ! -s "/tmp/bin/adbyby" ] ; then
        logger -t "【Adbyby】" "开始下载 7620n.tar.gz"
        /tmp/sh_download.sh /tmp/7620n.tar.gz $adbybyfile2 $adbybyfile
        /tmp/sh_untar.sh /tmp/7620n.tar.gz /tmp /tmp/bin/adbyby
    fi
    if [ -s "/tmp/bin/adbyby" ] ; then
        chmod 777 /tmp/bin/adbyby
        # 设置路由ip:8118
        lan_ipaddr="0.0.0.0" #`nvram get lan_ipaddr`
        sed -e "s|^\(listen-address.*\)=[^=]*$|\1=$lan_ipaddr:8118|" -i /tmp/bin/adhook.ini
        /tmp/sh_downloads_adblock.sh
        /tmp/sh_white_list.sh
        grep -v '^!' /tmp/bin/data/user_rules.txt | grep -v "^$" > /tmp/bin/data/user.txt
        grep -v '^!' /tmp/bin/data/user3adblocks.txt | grep -v "^$" >> /tmp/bin/data/user.txt
        grep -v '^!' /tmp/bin/data/video_B.txt | grep -v "^$" >> /tmp/bin/data/user.txt
        grep -v '^!' /tmp/bin/data/lazy_B.txt | grep -v "^$" >> /tmp/bin/data/user.txt
        sleep 1
        logger -t "【Adbyby】" "启动 adbyby 程序"
        /tmp/bin/adbyby >/dev/null 2>&1 &
        if [ "$adblocks" = "1" ] ; then
            logger -t "【Adbyby】" "加载 adblock 规则, 等候10秒"
            sleep 10
        else
            sleep 5
        fi
        if [ -f "/tmp/bin/data/lazy_B.txt" ] ; then
            logger -t "【Adbyby】" "加载手动同步更新规则, 等候10秒"
            mv -f /tmp/bin/data/lazy_B.txt /tmp/bin/data/lazy.txt
            mv -f /tmp/bin/data/video_B.txt /tmp/bin/data/video.txt
            sleep 10
        fi
    fi
    PIDS=$(ps | grep "/tmp/bin/adbyby" | grep -v "grep" | grep -v "adbybyupdate.sh" | grep -v "adbybyfirst.sh" | wc -l)
    if [ "$PIDS" != 0 ] ; then 
        logger -t "【Adbyby】" "启动完成"
        /tmp/sh_adb8118.sh A
        rm -f /tmp/7620n.tar.gz
        rm -f /tmp/cron_adb.lock
        if [ "$ipsets" = "1" ] ; then
            ipsetstxt="【ipset模式】"
        else
            ipsetstxt="【全局模式】"
        fi
        logger -t "【Adbyby】" "$ipsetstxt lazy更新: 更新时间: `sed -n '1p' /tmp/bin/data/lazy.txt | sed 's/^...................//' | sed -nr 's/......$//p' | sed 's/ \+/ /g'`"
        logger -t "【Adbyby】" "$ipsetstxt video更新: 更新时间: `sed -n '1p' /tmp/bin/data/video.txt | sed 's/^...................//' | sed -nr 's/................................................$//p' | sed 's/ \+/ /g'`"
        logger -t "【Adbyby】" "第三方规则行数:  `sed -n '$=' /tmp/bin/data/user3adblocks.txt` 行"
        logger -t "【Adbyby】" "自定义规则行数:  `sed -n '$=' /tmp/bin/data/user_rules.txt` 行"
        nvram set adbybylazy="$ipsetstxt lazy更新: 更新时间: `sed -n '1p' /tmp/bin/data/lazy.txt | sed 's/^...................//' | sed -nr 's/......$//p' | sed 's/ \+/ /g'`"
        nvram set adbybyvideo="$ipsetstxt video更新: 更新时间: `sed -n '1p' /tmp/bin/data/video.txt | sed 's/^...................//' | sed -nr 's/................................................$//p' | sed 's/ \+/ /g'`"
        nvram set adbybyuser3="第三方规则行数:  `sed -n '$=' /tmp/bin/data/user3adblocks.txt | sed s/[[:space:]]//g ` 行"
        nvram set adbybyuser="自定义规则行数:  `sed -n '$=' /tmp/bin/data/user_rules.txt | sed s/[[:space:]]//g ` 行"
        /tmp/sh_mon.sh&
        if [ "$CPUAverages" = "1" ] ; then
            /tmp/sh_CPUAverage.sh &
        fi
    sleep 2
    /etc/storage/ez_buttons_script.sh 3 &
    fi
    rm -f /tmp/cron_adb.lock
fi

EOF
chmod 777 "/tmp/sh_func_load_adbyby.sh"
cat > "/tmp/sh_phddns.sh" <<-\EOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
stop()
{
    killall oraynewph
    killall oraysl
    echo "Oraynewph already stopped !"
    logger -t "【花生壳内网版】" "Oraynewph already stopped !"
}
phddns=`nvram get phddns`
if [ "$phddns" = "0" ] ; then
    if [ ! -z "`pidof oraysl`" ] ; then
        nvram set phddns_sn=""
        nvram set phddns_st=""
        nvram set phddns_szUID=""
        logger -t "【花生壳内网版】" "停止运行 stopped !"
    fi
    nvram set phddns_sn="" && { killall -9 oraysl oraynewph ; killall sh_orayd.sh; }
fi
if [ -z "`pidof oraysl`" ] && [ "$phddns" = "1" ] ; then
    killall -9 oraysl oraynewph
    killall sh_orayd.sh;
    logger -t "【花生壳内网版】" "启动程序"
    ln -sf "/etc/storage/PhMain.ini" "/etc/PhMain.ini"
    ln -sf "/etc/storage/init.status" "/etc/init.status"
    SVC_PATH="/usr/bin/oraysl"
    SVC_PATH2="/usr/bin/oraynewph"
    wphddns2="https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/phddns2/bin"
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【花生壳内网版】" "自动安装花生壳内网版程序"
        # 找不到 花生壳内网版，安装 opt
        SVC_PATH="/opt/bin/oraysl"
        SVC_PATH2="/opt/bin/oraynewph"
        if [ ! -d "/opt/bin" ] ; then
            upanPath=""
            ss_opt_x=`nvram get ss_opt_x`
            [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
            [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
            [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
            if [ ! -z $upanPath ] ; then
                mkdir -p /media/$upanPath/opt
                mount -o bind /media/$upanPath/opt /opt
                ln -sf /media/$upanPath /tmp/AiDisk_00
            else
                mkdir -p /tmp/AiDisk_00/opt
                mount -o bind /tmp/AiDisk_00/opt /opt
            fi
            mkdir -p /opt/bin
        fi
        wphddns2="https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/phddns2/bin"
        if [ ! -f "$SVC_PATH" ] ; then
            logger -t "【花生壳内网版】" "找不到 $SVC_PATH 下载程序"
            [ ! -s "$SVC_PATH2" ] && /tmp/sh_download.sh $SVC_PATH2 "$wphddns2/oraynewph"
            [ ! -s "$SVC_PATH" ] && /tmp/sh_download.sh $SVC_PATH "$wphddns2/oraysl"
        else
            logger -t "【花生壳内网版】" "找到 $SVC_PATH"
        fi
    fi
    [ ! -s "$SVC_PATH" ] && {  logger -t "【花生壳内网版】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; stop; }
    [ ! -s "$SVC_PATH2" ] && {  logger -t "【花生壳内网版】" "找不到 $SVC_PATH2 ，需要手动安装 $SVC_PATH2"; stop; }
    [ ! -s "$SVC_PATH" ] && exit 0
    [ ! -s "$SVC_PATH2" ] &&  exit 0
    # export LD_LIBRARY_PATH=/opt/phddns2/lib:/lib:/opt/lib
    oraynewph -s 0.0.0.0 >/dev/null 2>/dev/null &
    oraysl -a 127.0.0.1 -p 16062 -s phsle01.oray.net:80 -d >/dev/null 2>/dev/null &
    echo "Oraynewph start success !"
    logger -t "【花生壳内网版】" "Oraynewph start success !"
    sleep 28
    USER_DATA="/tmp/oraysl.status"

    SN=`head -n 2 $USER_DATA  | tail -n 1 | cut -d= -f2-`;
    STATUS=`head -n 3 $USER_DATA  | tail -n 1 | cut -d= -f2-`;

    echo  "RUNSTATUS= $STATUS"
    echo  "SN= $SN"
    echo  "LoginAddress= http://b.oray.com/"
    logger -t "【花生壳内网版】" "RUNSTATUS= $STATUS"
    logger -t "【花生壳内网版】" "SN= $SN "
    nvram set phddns_sn=$SN
    nvram set phddns_st=$STATUS
    szUID=0
    if [ -f /etc/storage/PhMain.ini ] ; then
        szUID=`sed -n 's/.*szUID=*/\1/p' /etc/storage/PhMain.ini`
    fi
    if [ "$szUID" != "0" ] ; then
        logger -t "【花生壳内网版】" "已经绑定的花生壳账号:$szUID"
        nvram set phddns_szUID=$szUID
        logger -t "【花生壳内网版】" "使用SN账号在【 http://b.oray.com 】登录."
    else
        logger -t "【花生壳内网版】" "没绑定的花生壳账号，请尽快绑定"
        logger -t "【花生壳内网版】" "使用 SN 账号在【 http://b.oray.com 】默认密码是 admin 登录."
        logger -t "【花生壳内网版】" "默认密码:admin, 默认密码:admin, 然后进行修改默认密码、手机验证、邮箱验证和花生壳账号绑定"
        logger -t "【花生壳内网版】" "!!>>绑定后需【写入】内部存储, 不然重启会丢失绑定.<<!!"
        logger -t "【花生壳内网版】" " !>>绑定后需【写入】内部存储, 不然重启会丢失绑定.<<!"
        logger -t "【花生壳内网版】" "  !>绑定后需【写入】内部存储, 不然重启会丢失绑定.<!"
        logger -t "【花生壳内网版】" "系统管理 - 恢复/导出/上传设置 - 路由器内部存储 /etc/storage - 【提交】"
    fi
    /tmp/sh_orayd.sh &
fi
EOF
chmod 777 "/tmp/sh_phddns.sh"
cat > "/tmp/sh_syncys.sh" <<-\EOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
syncys=`nvram get syncys`
if [ "$syncys" = "0" ] ; then
[ ! -z "`ps |grep "/opt/etc/syncy.py"|grep -v grep| awk '{print $1}'`" ] && {  eval $(ps  | grep "/opt/etc/syncy" | grep -v grep | awk '{print "kill "$1}') ; killall sh_syncyquota.sh; killall sh_syncyd.sh; }
fi
if [ -z "`ps |grep "/opt/etc/syncy.py"|grep -v grep| awk '{print $1}'`" ] && [ "$syncys" = "1" ] ; then
    killall sh_syncyquota.sh; killall sh_syncyd.sh;
    if [ ! -f "/opt/opti.txt" ] ; then
        ssfile=`nvram get ssfile`
        ssfile2=`nvram get ssfile2`
        upanPath=""
        ss_opt_x=`nvram get ss_opt_x`
        [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
        [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
        [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
        if [ ! -z $upanPath ] ; then
            mkdir -p /media/$upanPath/opt
            mount -o bind /media/$upanPath/opt /opt
            ln -sf /media/$upanPath /tmp/AiDisk_00
            /tmp/sh_installs.sh $ssfile 1
        fi
    fi
    if [ ! -f "/opt/opti.txt" ] ; then
        nvram set syncys=0
        nvram commit
        logger -t "【SyncY】" "opt 缺少 opt 文件, 请更新 opt, 并检查 U盘 文件和设置"
    fi
    if [ ! -s "/opt/etc/syncy.py" ] ; then
        logger -t "【SyncY】" "opt 缺少 syncy.py 文件, 请更新 opt, 并检查 U盘 文件和 Entware 设置"
    else
        # 设置路由器本地同步目录
        upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | sed -n '1p'`
        syncyPath="/media/$upanPath/"
        if [ ! -d "/tmp/AiDisk_SyncY" ] ; then
            mkdir -p -m 777 /media/$upanPath/SyncY
            ln -sf /media/$upanPath/SyncY /tmp/AiDisk_SyncY
            logger -t "【SyncY】" "设置路由器本地同步目录 /media/$upanPath/SyncY"
            sed -e 's/'"\/media\/AiDisk_a1\/SyncY'#本地同步目录"/"\/tmp\/AiDisk_SyncY' #本地同步目录"'/g' -i /opt/etc/syncy
            #option localpath '/media/AiDisk_a1/SyncY'#本地同步目录
            localpath=`cat /opt/etc/syncy |grep "localpath" | sed "s/option localpath//g" | sed "s/'//g" | sed "s/#本地同步目录//g"`
            if [ ! -d `echo $localpath` ] ; then
                logger -t "【SyncY】" "错误！！路由器本地同步目录不存在！！"
                logger -t "【SyncY】" "$localpath 设置错误！！请检查 U盘 文件和设置"
            fi
        fi
        logger -t "【SyncY】" "启动 syncy 服务"
        dos2unix -u /opt/etc/syncy
#       sed -i "s/\\r//g" /opt/etc/syncy
        rm -f /tmp/syncy.quota
        rm -f /tmp/syncy.user_code
        rm -f /tmp/syncy.user_token
        cd /opt/etc
        export LD_LIBRARY_PATH=/lib:/opt/lib
        python /opt/etc/syncy.py &
        sleep 25
        /tmp/sh_syncyquota.sh &
    fi
fi
EOF
chmod 777 "/tmp/sh_syncys.sh"
cat > "/tmp/youku_install.sh" <<-\EOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/opt/youku/lib:/lib

#wget --continue --no-check-certificate -O /opt/youku_install.sh http://code.taobao.org/svn/test43/youku/youku_install.sh
#sh /opt/youku_install.sh &
#自定义缓存目录
hc_dir=`nvram get youku_hc_dir`
hc_dir=`echo $hc_dir`
[ -z $hc_dir ] && hc_dir=$(df|grep '/media/'|awk '{print$6}'|head -n 1) && nvram set youku_hc_dir=$hc_dir
#自定义16位sn：2115663623336666
sn_youku=`nvram get youku_sn`
[ -z $sn_youku ] && sn_youku="2115$(cat /sys/class/net/ra0/address |tr -d ':'|md5sum |tr -dc [0-9]|cut -c 0-12)" && nvram set youku_sn=$sn_youku
#缓存大小，单位MB。
hc=`nvram get youku_hc`
[ -z $hc ] && hc=6000 && nvram set youku_hc=$hc
#速度模式
#"0" "激进模式：赚取收益优先"
#"2" "平衡模式：赚钱上网兼顾"
#"3" "保守模式：上网体验优先"
spd=`nvram get youku_spd`
youku_enable=`nvram get youku_enable`

A_restart=`nvram get youku_status`
B_restart="$youku_enable$hc_dir$sn_youku$hc$spd"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set youku_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$needed_restart" = "0" ] ; then
    exit 1
fi
    [ ${youku_enable:=0} ] && [ "$youku_enable" -eq "0" ] && [ "$needed_restart" = "1" ] && { killall -9 ikuacc; nvram set youku_bdlink=""; killall -9 youku_install.sh youku_ssmon.sh; exit 0; }
if [ "$youku_enable" = "1" ] ; then
    localpath=`echo $hc_dir`
    if [ ! -d `echo $localpath` ] ; then
                logger -t "【路由宝】" "错误！！自定义缓存目录不存在！！"
                logger -t "【路由宝】" "$localpath 设置错误！！请检查 U盘 文件和设置"
    fi
    SVC_PATH=/opt/youku/bin/ikuacc
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【路由宝】" "自动安装 ikuacc 程序"
        # 找不到ikuacc，安装opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
        mkdir -p /opt/youku
        chmod -R 777 /opt/youku
        if [ ! -f "$SVC_PATH" ] ; then
            logger -t "【路由宝】" "找不到 $SVC_PATH 下载程序"
            /tmp/sh_download.sh "/opt/youku.tgz" "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/youku.tgz"
            /tmp/sh_untar.sh /opt/youku.tgz /opt/youku /opt/youku/bin/ikuacc
        else
            logger -t "【路由宝】" "找到 $SVC_PATH"
        fi
    fi

    [ ! -s "$SVC_PATH" ] && {  logger -t "【路由宝】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; exit 0; }

path=$hc_dir/youku
mkdir -p $path/meta
mkdir -p $path/data
mkdir -p /opt/youku
chmod -R 777 /opt/youku
chmod -R 777 $path/meta
chmod -R 777 $path/data



export LD_LIBRARY_PATH=/opt/youku/lib:/lib
#youku_Total=`cat /proc/meminfo | grep  MemTotal | sed -e s/"MemTotal:"//g | sed -e s/" "//g | sed -e s/"kB"//g`
#youku_Total=`expr $youku_Total - 26472`
killall -9 ikuacc
#ulimit -v $youku_Total
#nvram set youku_Total=$youku_Total
cd /opt/youku/bin/
/opt/youku/bin/ikuacc  --device-serial-number="0000$sn_youku"  --mobile-meta-path="$path/meta" --mobile-data-path="$path/data:$hc"  &
logger -t "【路由宝】" "开始运行"
sleep 5
#速度模式
wget --continue --no-check-certificate -O - http://127.0.0.1:8908/peer/limit/network/set?upload_model=$spd > /dev/null 2>&1 &
wget --continue --no-check-certificate -O - http://`nvram get lan_ipaddr`:8908/peer/limit/network/set?upload_model=$spd > /dev/null 2>&1 &

#获取绑定地址
rm /tmp/youku_sn.log
/opt/youku/bin/getykbdlink 0000$sn_youku >/tmp/youku_sn.log
sleep 3
bdlink=$(grep http -r /tmp/youku_sn.log)
nvram set youku_bdlink=$bdlink
logger -t "【路由宝】" "绑定地址："
logger -t "【路由宝】" "$bdlink"
echo "Youku $bdlink"
logger -t "【路由宝】" "SN:$sn_youku"
#logger -t "【路由宝】" "虚存最大值：$youku_Total"

#进程保护
/tmp/youku_ssmon.sh &

fi

EOF
chmod 777 "/tmp/youku_install.sh"

cat > "/tmp/youku_ssmon.sh" <<-\EOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/opt/youku/lib:/lib
logger -t "【路由宝】" "进程保护启动"
hc_dir=`nvram get youku_hc_dir`
hc_dir=`echo $hc_dir`
sn_youku=`nvram get youku_sn`
#youku_Total=`nvram get youku_Total`
#ulimit -v $youku_Total
spd=`nvram get youku_spd`
path=$hc_dir/youku
hc=`nvram get youku_hc`
[ -z $hc ] && hc=6000 && nvram set youku_hc=$hc
while true; do
    localpath=`echo $hc_dir`
    if [ ! -d `echo $localpath` ] ; then
                logger -t "【路由宝】" "错误！！自定义缓存目录不存在！！"
                logger -t "【路由宝】" "$localpath 设置错误！！请检查 U盘 文件和设置"
    fi
    pids=$(ps | grep "ikuacc" | grep -v "grep" | wc -l)
    if [ "$pids" -ne 1 ] ; then
        logger -t "【路由宝】" "找不到优酷进程 $pids"
        sleep 1
        if [ ! -n "`pidof ikuacc`" ] ; then
            logger -t "【路由宝】" "找不到优酷进程(复查)，重启优酷"
        else
            continue
        fi
        killall -9 ikuacc
        sleep 1
        export LD_LIBRARY_PATH=/opt/youku/lib:/lib
        /opt/youku/bin/ikuacc  --device-serial-number="0000$sn_youku"  --mobile-meta-path="$path/meta" --mobile-data-path="$path/data:$hc"  &
        sleep 5
        logger -t "【路由宝】" "开始运行. PID:【$(pidof ikuacc)】"
        #速度模式
        wget --continue --no-check-certificate -O - http://127.0.0.1:8908/peer/limit/network/set?upload_model=$spd > /dev/null 2>&1 &
        wget --continue --no-check-certificate -O - http://`nvram get lan_ipaddr`:8908/peer/limit/network/set?upload_model=$spd > /dev/null 2>&1 &
    fi

    pids=$(ps | grep "ikuacc" | grep -v "grep" | wc -l)
    if [ "$pids" -gt 4 ] ; then 
        echo "优酷进程重复，重启优酷"
        logger -t "【路由宝】" "优酷进程重复，重启优酷"
        killall -9 ikuacc
        sleep 3
        export LD_LIBRARY_PATH=/opt/youku/lib:/lib
        /opt/youku/bin/ikuacc  --device-serial-number="0000$sn_youku"  --mobile-meta-path="$path/meta" --mobile-data-path="$path/data:$hc"  &
        logger -t "【路由宝】" "开始运行"
        sleep 5
        #速度模式
        wget --continue --no-check-certificate -O - http://127.0.0.1:8908/peer/limit/network/set?upload_model=$spd > /dev/null 2>&1 &
        wget --continue --no-check-certificate -O - http://`nvram get lan_ipaddr`:8908/peer/limit/network/set?upload_model=$spd > /dev/null 2>&1 &
    fi
    sleep 23
done

EOF
chmod 777 "/tmp/youku_ssmon.sh"







cat > "/tmp/sh_mento_hust.sh" <<-\EOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

mentohust_enable=`nvram get mentohust_enable`
mentohust_path=`nvram get mentohust_path`
[ -z $mentohust_path ] && mentohust_path="/usr/bin/mentohust" && nvram set mentohust_path=$mentohust_path
mentohust_u=`nvram get mentohust_u`
mentohust_p=`nvram get mentohust_p`
mentohust_n=`nvram get mentohust_n`
[ -z $mentohust_n ] && mentohust_n=$(nvram get wan0_ifname_t) && nvram set mentohust_n=$mentohust_n
mentohust_i=`nvram get mentohust_i`
[ -z $mentohust_i ] && mentohust_i="0.0.0.0" && nvram set mentohust_i=$mentohust_i
mentohust_m=`nvram get mentohust_m`
[ -z $mentohust_m ] && mentohust_m=$(nvram get lan_netmask) && nvram set mentohust_m=$mentohust_m
mentohust_g=`nvram get mentohust_g`
[ -z $mentohust_g ] && mentohust_g="0.0.0.0" && nvram set mentohust_g=$mentohust_g
mentohust_s=`nvram get mentohust_s`
[ -z $mentohust_s ] && mentohust_s="0.0.0.0" && nvram set mentohust_s=$mentohust_s
mentohust_o=`nvram get mentohust_o`
[ -z $mentohust_o ] && mentohust_o="0.0.0.0" && nvram set mentohust_o=$mentohust_o
mentohust_t=`nvram get mentohust_t`
[ -z $mentohust_t ] && mentohust_t="8" && nvram set mentohust_t=$mentohust_t
mentohust_e=`nvram get mentohust_e`
[ -z $mentohust_e ] && mentohust_e="30" && nvram set mentohust_e=$mentohust_e
mentohust_r=`nvram get mentohust_r`
[ -z $mentohust_r ] && mentohust_r="15" && nvram set mentohust_r=$mentohust_r
mentohust_l=`nvram get mentohust_l`
[ -z $mentohust_l ] && mentohust_l="8" && nvram set mentohust_l=$mentohust_l
mentohust_a=`nvram get mentohust_a`
[ -z $mentohust_a ] && mentohust_a="0" && nvram set mentohust_a=$mentohust_a
mentohust_d=`nvram get mentohust_d`
[ -z $mentohust_d ] && mentohust_d="0" && nvram set mentohust_d=$mentohust_d
mentohust_b=`nvram get mentohust_b`
[ -z $mentohust_b ] && mentohust_b="0" && nvram set mentohust_b=$mentohust_b
mentohust_v=`nvram get mentohust_v`
[ -z $mentohust_v ] && mentohust_v="0.00" && nvram set mentohust_v=$mentohust_v
mentohust_f=`nvram get mentohust_f`
mentohust_c=`nvram get mentohust_c`
[ -z $mentohust_c ] && mentohust_c="dhclinet" && nvram set mentohust_c=$mentohust_c

func_start()
{
logger -t "【MentoHUST】" "启动"

#保存配置到文件
if [ ! -f "/etc/storage/mentohust.conf" ] ; then
    $mentohust_path -u$mentohust_u -p$mentohust_p -n$mentohust_n -i$mentohust_i -m$mentohust_m -g$mentohust_g -s$mentohust_s -o$mentohust_o -t$mentohust_t -e$mentohust_e -r$mentohust_r -l$mentohust_l -a$mentohust_a -d$mentohust_d -b$mentohust_b -v$mentohust_v -f$mentohust_f  -c$mentohust_c -w
    pids=$(pidof process) && killall -9 $pids
fi

mentohust_mode=`nvram get mentohust_mode`
    if [ "$mentohust_mode" = "0" ] ; then
    logger -t "【MentoHUST】" "标准模式"
        $mentohust_path  > /dev/null 2>&1 
    elif [ "$mentohust_mode" = "1" ] ; then
    logger -t "【MentoHUST】" "锐捷模式"
       $mentohust_path  -y  > /dev/null 2>&1 
    elif [ "$mentohust_mode" = "2" ] ; then
    logger -t "【MentoHUST】" "赛尔模式"
       $mentohust_path -s8.8.8.8 > /dev/null 2>&1 
    fi
}

func_stop()
{
    pid_num=`pidof mentohust`
    if [ -n pid_num ] ; then
        killall -q -9 mentohust
        logger -t "【MentoHUST】" "关闭"
    fi
}


check_setting()
{
A_restart=`nvram get mentohust_status`
B_restart="$mentohust_enable$mentohust_path$mentohust_u$mentohust_p$mentohust_n$mentohust_i$mentohust_m$mentohust_g$mentohust_s$mentohust_o$mentohust_t$mentohust_e$mentohust_r$mentohust_a$mentohust_d$mentohust_b$mentohust_v$mentohust_f$mentohust_c"

B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set mentohust_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$needed_restart" = "0" ] ; then
    exit 0
fi
    #配置有变，重新生成
    rm -f /etc/storage/mentohust.conf

    [ ${mentohust_enable:=0} ] && [ "$mentohust_enable" -eq "0" ] && [ "$needed_restart" = "1" ] && { func_stop; exit 0; }
    

    [ ! -s "$mentohust_path" ] && {  logger -t "【MentoHUST】" "找不到 $mentohust_path, 需要手动安装 mentohust 程序"; func_stop; exit 0; }

    [ $mentohust_u ] && [ $mentohust_p ] && [ $mentohust_path ] \
    && [ "$needed_restart" = "1" ] ||  { logger -t "【MentoHUST】" "mentohust 配置有错误, 需要手动检查 mentohust 配置"; func_stop; exit 1; }
    func_stop
    func_start
}


case "$1" in
start)
        func_start
        ;;
stop)
        func_stop
        ;;
*)
        echo "Usage: $0 {start|stop}"
        check_setting
        exit 1
        ;;
esac

exit 0


EOF
chmod 777 "/tmp/sh_mento_hust.sh"



cat > "/tmp/ssserver.sh" <<-\FOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

#初始化
ssserver_enable=`nvram get ssserver_enable`
ssserver_enable=${ssserver_enable:-"0"}
ssserver_method=`nvram get ssserver_method`
ssserver_method=$(echo "table,rc4,rc4-md5,aes-128-cfb,aes-192-cfb,aes-256-cfb,bf-cfb,camellia-128-cfb,camellia-192-cfb,camellia-256-cfb,cast5-cfb,des-cfb,idea-cfb,rc2-cfb,seed-cfb,salsa20,chacha20,chacha20-ietf" | cut -d "," -f$ssserver_method)
[ ! -z "$ssserver_method" ] && nvram set ssserver_method=$ssserver_method
[ -z "$ssserver_method" ] && ssserver_method=`nvram get ssserver_method`
ssserver_password=`nvram get ssserver_password`
ssserver_port=`nvram get ssserver_port`
ssserver_port2=`nvram get ssserver_port2`
ssserver_time=`nvram get ssserver_time`
ssserver_time=${ssserver_time:-"120"}
ssserver_udp=`nvram get ssserver_udp`
ssserver_ota=`nvram get ssserver_ota`
ssserver_usage=`nvram get ssserver_usage`

# var define
#num=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$ssserver_port | cut -d " " -f 1 | sort -nr)
#num2=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$ssserver_port2 | cut -d " " -f 1 | sort -nr)

# kill first
stop_ssserver(){
logger -t "【SS-server】" "关闭 ss-server 服务"
    killall sskeep.sh >/dev/null 2>&1
    killall ss-server >/dev/null 2>&1
#    iptables -t filter -D INPUT $num  >/dev/null 2>&1
#    iptables -t filter -D INPUT $num2  >/dev/null 2>&1
}

# start ssserver
start_ssserver(){
logger -t "【SS-server】" "启动 ss-server 服务"

    if [ "$ssserver_udp" == "1" ] ; then
        if [ "ssserver_ota" == 1 ] ; then
            ss-server -s 0.0.0.0 -p $ssserver_port -k $ssserver_password -m $ssserver_method -t $ssserver_time -u -A $ssserver_usage -f /tmp/ssserver.pid
        else
            ss-server -s 0.0.0.0 -p $ssserver_port -k $ssserver_password -m $ssserver_method -t $ssserver_time -u $ssserver_usage  -f /tmp/ssserver.pid
        fi
    else
        if [ "ssserver_ota" == 1 ] ; then
            ss-server -s 0.0.0.0 -p $ssserver_port -k $ssserver_password -m $ssserver_method -t $ssserver_time -A $ssserver_usage -f /tmp/ssserver.pid
        else
            ss-server -s 0.0.0.0 -p $ssserver_port -k $ssserver_password -m $ssserver_method -t $ssserver_time $ssserver_usage -f /tmp/ssserver.pid
        fi
    fi
    logger -t "【SS-server】" "`ps | grep ss-server | grep -v grep`"
    iptables -t filter -I INPUT -p tcp --dport $ssserver_port -j ACCEPT
    nvram set ssserver_port2=`nvram get ssserver_port`
    logger -t "【SS-server】" "ss-server 启动."
    sleep 10
    [ -z "`pidof ss-server`" ] && logger -t "【SS-server】" "启动失败, 注意检查端口是否有冲突,10秒后自动尝试重新启动" && sleep 10 && nvram set ssserver_status=00 && /tmp/ssserver.sh &
    sleep 10
    [ ! -z "`pidof ss-server`" ] && keep_ssserver
}

keep_ssserver(){
logger -t "【SS-server】" "ss-server 守护脚本启动."
killall sskeep.sh
cat > "/tmp/sskeep.sh" <<-\SSS
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
PRO_NAME="ss-server"
SSNUM=1

while true ; do
#   用ps获取 $PRO_NAME 进程数量
    NUM=`ps | grep $PRO_NAME | grep -v grep |wc -l`
#    echo $NUM
#    logger -t "【SS-server】" " $NUM 进程"
if [ "$NUM" -lt "$SSNUM" ] ; then
#   少于 $SSNUM ，重启进程
    logger -t "【SS-server】" "少于 $SSNUM, 重启进程"
    echo "$PRO_NAME was killed"
    nvram set ssserver_status=restart_firewall
    restart_firewall
    sleep 62
elif [ "$NUM" -gt "$SSNUM" ] ; then
#   大于 $SSNUM ，杀掉所有进程，重启
    logger -t "【SS-server】" "大于 $SSNUM, 杀掉所有进程, 重启"
    echo "more than $SSNUM $PRO_NAME,killall $PRO_NAME"
    nvram set ssserver_status=restart_firewall
    restart_firewall
    sleep 62
fi
sleep 37
if [ -n "`pidof ss-server`" ] ; then
    port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$ssserver_port | cut -d " " -f 1 | sort -nr | wc -l)
    if [ "$port" = 0 ] ; then
        logger -t "【SS-server】" "检测:找不到 ss-server 端口:$ssserver_port 规则, 重新添加"
        iptables -t filter -I INPUT -p tcp --dport $ssserver_port -j ACCEPT &
    fi
fi
done
exit 0
SSS
chmod 755 "/tmp/sskeep.sh"
/tmp/sskeep.sh &
}


check_setting()
{
A_restart=`nvram get ssserver_status`
B_restart="$ssserver_enable$ssserver_method$ssserver_password$ssserver_port$ssserver_time$ssserver_udp$ssserver_ota$ssserver_usage"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set ssserver_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$needed_restart" = "0" ] ; then
    if [ -n "`pidof ss-server`" ] && [ "$ssserver_enable" = "1" ] ; then
        port=$(iptables -t filter -L INPUT -v -n --line-numbers | grep dpt:$ssserver_port | cut -d " " -f 1 | sort -nr | wc -l)
        if [ "$port" = 0 ] ; then
            logger -t "【SS-server】" "检测:找不到 ss-server 端口:$ssserver_port 规则, 重新添加"
            iptables -t filter -I INPUT -p tcp --dport $ssserver_port -j ACCEPT &
        fi
    fi
    exit 0
fi
    [ ${ssserver_enable:=0} ] && [ "$ssserver_enable" -eq "0" ] && [ "$needed_restart" = "1" ] && { stop_ssserver; killall -9 ssserver.sh; exit 0; }
    # Check if have ss-server 

    hash ss-server 2>/dev/null || {  logger -t "【SS-server】" "找不到 ss-server, 需要安装 opt"; }

    ssserver="0"
    hash ss-server 2>/dev/null || ssserver="1"
if [ "$ssserver" = "1" ] ; then
    # 找不到ss-server，安装opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    ssserver="0"
    hash ss-server 2>/dev/null || ssserver="1"
    if [ "$ssserver" = "1" ] ; then
        logger -t "【SS-server】" "找不到 ss-server. opt下载程序"
        /tmp/sh_download.sh "/opt/bin/ss-server" "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/ss-server"
        chmod 777 "/opt/bin/ss-server"
    fi
    hash ss-server 2>/dev/null || { logger -t "【SS-server】" "找不到 ss-server，请检查系统"; nvram set ssserver_enable=0 && nvram set ssserver_status=0 && nvram commit; exit 1; }
fi
    # Check the ss config from nvram

    [ $ssserver_password ] && [ $ssserver_port ] && [ $ssserver_time ] \
    && [ "$needed_restart" = "1" ] ||  { logger -t "【SS-server】" "ss-server 配置有错误, 需要手动检查 ss-server 配置"; stop_ssserver; exit 1; }

    stop_ssserver
    start_ssserver

}


case $ACTION in
start)
    if [ "$ssserver_enable" == "1" ] ; then
    start_ssserver
    fi
    ;;
stop | kill )
    stop_ssserver
    ;;
restart)
    stop_ssserver
    start_ssserver
    ;;
*)
    check_setting
    echo "Usage: $0 (start|stop|restart)"
    exit 1
    ;;
esac

FOF
chmod 777 "/tmp/ssserver.sh"


cat > "/tmp/ssrserver.sh" <<-\FOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib

#初始化
ssrserver_enable=`nvram get ssrserver_enable`
ssrserver_enable=${ssrserver_enable:-"0"}
ssrserver_update=`nvram get ssrserver_update`
ssrserver_update=${ssrserver_update:-"0"}

# kill first
stop_ssrserver(){
logger -t "【SSR】" "关闭 ssr-server 服务"
killall ssrkeep.sh
    eval $(ps  | grep "/opt/shadowsocks-manyuser/shadowsocks/server" | grep -v grep | awk '{print "kill "$1}')
}

# start ssrserver
start_ssrserver(){
logger -t "【SSR】" "ssr-server 检测更新"
rm -rf /opt/shadowsocks-manyuser/shadowsocks/crypto/utilb
wget --continue --no-check-certificate -O /opt/shadowsocks-manyuser/shadowsocks/crypto/utilb https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/util.py
wget --continue --no-check-certificate -O /opt/shadowsocks-manyuser/shadowsocks/crypto/utilc https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/util_taobao.py
A_util=`cat /opt/shadowsocks-manyuser/shadowsocks/crypto/util.py`
B_util=`cat /opt/shadowsocks-manyuser/shadowsocks/crypto/utilb`
C_util=`cat /opt/shadowsocks-manyuser/shadowsocks/crypto/utilc`
A_util=`echo -n "$A_util" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
B_util=`echo -n "$B_util" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
C_util=`echo -n "$C_util" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_util" != "$B_util" ] && [ "$ssrserver_update" = "1" ] ; then
    logger -t "【SSR】" "ssr-server github.com需要更新"
    logger -t "【SSR】" "下载:https://github.com/breakwa11/shadowsocks/archive/manyuser.zip"
    rm -rf /opt/manyuser.zip
    wget --continue --no-check-certificate -O /opt/manyuser.zip https://github.com/breakwa11/shadowsocks/archive/manyuser.zip
    unzip -o /opt/manyuser.zip  -d /opt/
    rm -rf /opt/shadowsocks-manyuser/shadowsocks/crypto/util.py
    cp -a /opt/shadowsocks-manyuser/shadowsocks/crypto/utilb /opt/shadowsocks-manyuser/shadowsocks/crypto/util.py
    logger -t "【SSR】" "ssr-server github.com更新完成"
else
    logger -t "【SSR】" "ssr-server github.com暂时没更新"
fi
if [ "$A_util" != "$C_util" ] && [ "$ssrserver_update" = "2" ] ; then
    logger -t "【SSR】" "ssr-server taobao.org需要更新"
    logger -t "【SSR】" "下载:https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/manyuser.zip"
    rm -rf /opt/manyuser.zip
    wget --continue --no-check-certificate -O /opt/manyuser.zip https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/manyuser.zip
    unzip -o /opt/manyuser.zip  -d /opt/
    rm -rf /opt/shadowsocks-manyuser/shadowsocks/crypto/util.py
    cp -a /opt/shadowsocks-manyuser/shadowsocks/crypto/utilc /opt/shadowsocks-manyuser/shadowsocks/crypto/util.py
    logger -t "【SSR】" "ssr-server taobao.org更新完成"
else
    logger -t "【SSR】" "ssr-server taobao.org暂时没更新"
fi
logger -t "【SSR】" "启动 ssr-server 服务"
rm -rf /opt/shadowsocks-manyuser/user-config.json
cp -a /etc/storage/SSRconfig_script.sh /opt/shadowsocks-manyuser/user-config.json
if [ -s "/opt/shadowsocks-manyuser/user-config.json" ] ; then
    chmod 777 -R /opt/shadowsocks-manyuser
    python /opt/shadowsocks-manyuser/shadowsocks/server.py a >> /dev/null 2>&1 &
    logger -t "【SSR】" "ssr-server 启动."
    keep_ssrserver
else
    logger -t "【SSR】" "/opt/shadowsocks-manyuser/user-config.json配 置写入失败."
    logger -t "【SSR】" "ssr-server 未启动."
    
fi
}


check_setting()
{
A_restart=`nvram get ssrserver_status`
B_restart="$ssrserver_enable$ssrserver_update$(cat /etc/storage/SSRconfig_script.sh | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set ssrserver_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$needed_restart" = "0" ] ; then
    
    exit 0
fi
    [ ${ssrserver_enable:=0} ] && [ "$ssrserver_enable" -eq "0" ] && [ "$needed_restart" = "1" ] && { stop_ssrserver; killall -9 ssrserver.sh; exit 0; }
    # Check if have ss-server 

    hash python 2>/dev/null || {  logger -t "【SSR】" "找不到 ssr-server, 需要安装 opt"; nvram set optinstall=1; }

    ssrserver="0"
    hash python 2>/dev/null || ssrserver="1"
    [ ! -f "/opt/shadowsocks-manyuser/shadowsocks/server.py" ] && ssrserver="1"
if [ "$ssrserver" = "1" ] ; then
    # 找不到ssr-server，安装opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    ssrserver="0"
    hash python 2>/dev/null || ssrserver="1"
    [ ! -f "/opt/shadowsocks-manyuser/shadowsocks/server.py" ] && ssrserver="1"
    if [ "$ssrserver" = "1" ] ; then
        logger -t "【SSR】" "找不到 ssr-server, opt 下载程序"
        ssfile=`nvram get ssfile`
        rm -rf /opt/opti.txt
        rm -rf /opt/lnmp.txt
        /tmp/sh_installs.sh $ssfile 1
        chmod 777 -R /opt/shadowsocks-manyuser
    fi
    [ ! -f "/opt/shadowsocks-manyuser/shadowsocks/server.py" ] && { logger -t "【SSR】" "找不到 ssr-server, 请检查系统"; nvram set ssrserver_enable=0 && nvram set ssrserver_status=0 && nvram commit; exit 1; }
fi
    
    stop_ssrserver
    start_ssrserver

}

keep_ssrserver(){
logger -t "【SSR】" "SSR 守护脚本启动."
killall ssrkeep.sh
cat > "/tmp/ssrkeep.sh" <<-\SSR
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
PRO_NAME="/opt/shadowsocks-manyuser/shadowsocks/server"
SSRNUM=1
 
while true ; do
#   用ps获取 $PRO_NAME 进程数量
    NUM=`ps | grep $PRO_NAME | grep -v grep |wc -l`
#    echo $NUM
#    logger -t "【SSR】" " $NUM 进程"
if [ "$NUM" -lt "$SSRNUM" ] ; then
#   少于 $SSRNUM ，重启进程
    logger -t "【SSR】" "少于 $SSRNUM, 重启进程"
    echo "$PRO_NAME was killed"
    eval $(ps  | grep "/opt/shadowsocks-manyuser/shadowsocks/server" | grep -v grep | awk '{print "kill "$1}')
    python /opt/shadowsocks-manyuser/shadowsocks/server.py a >> /dev/null 2>&1 &
elif [ "$NUM" -gt "$SSRNUM" ] ; then
#   大于 $SSRNUM ，杀掉所有进程，重启
    logger -t "【SSR】" "大于 $SSRNUM, 杀掉所有进程, 重启"
    echo "more than $SSRNUM $PRO_NAME,killall $PRO_NAME"
    eval $(ps | grep "/opt/shadowsocks-manyuser/shadowsocks/server" | grep -v grep | awk '{print "kill "$1}')
    python /opt/shadowsocks-manyuser/shadowsocks/server.py a >> /dev/null 2>&1 &
fi
sleep 23
done
exit 0
SSR
chmod 755 "/tmp/ssrkeep.sh"
/tmp/ssrkeep.sh &
}


case $ACTION in
start)
    if [ "$ssrserver_enable" == "1" ] ; then
    start_ssrserver
    fi
    exit 1
    ;;
stop | kill )
    stop_ssrserver
    exit 1
    ;;
restart)
    stop_ssrserver
    start_ssrserver
    exit 1
    ;;
*)
    check_setting
    echo "Usage: $0 (start|stop|restart)"
    exit 1
    ;;
esac

FOF
chmod 777 "/tmp/ssrserver.sh"

    if [ ! -f "/etc/storage/cow_script.sh" ] || [ ! -s "/etc/storage/cow_script.sh" ] ; then
cat > "/etc/storage/cow_script.sh" <<-\FOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
sed -Ei '/UI设置自动生成/d' /etc/storage/cow_config_script.sh
sed -Ei '/^$/d' /etc/storage/cow_config_script.sh
ss_mode_x=`nvram get ss_mode_x`
ss_mode_x=${ss_mode_x:-"0"}
ss_rdd_server=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=`nvram get kcptun2_enable2`
kcptun2_enable2=${kcptun2_enable2:-"0"}
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s2_local_port=`nvram get ss_s2_local_port`
ss_s1_local_port=${ss_s1_local_port:-"1081"}
ss_s2_local_port=${ss_s2_local_port:-"1082"}
nvram set ss_s1_local_port=$ss_s1_local_port
nvram set ss_s2_local_port=$ss_s2_local_port
lan_ipaddr=`nvram get lan_ipaddr`
sed -Ei "/$lan_ipaddr:$ss_s1_local_port/d" /etc/storage/cow_config_script.sh
sed -Ei "/$lan_ipaddr:$ss_s2_local_port/d" /etc/storage/cow_config_script.sh
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
cat >> "/etc/storage/cow_config_script.sh" <<-EUI
# UI设置自动生成 
proxy = socks5://$lan_ipaddr:$ss_s1_local_port
EUI
if [ ! -z $ss_rdd_server ] ; then
cat >> "/etc/storage/cow_config_script.sh" <<-EUI
# UI设置自动生成 
proxy = socks5://$lan_ipaddr:$ss_s2_local_port
EUI
fi
fi
FOF
chmod 777 "/etc/storage/cow_script.sh"
    fi
    if [ ! -f "/etc/storage/cow_config_script.sh" ] || [ ! -s "/etc/storage/cow_config_script.sh" ] ; then
cat > "/etc/storage/cow_config_script.sh" <<-\COWCON
# 配置文件中 # 开头的行为注释
#
# 代理服务器监听地址，重复多次来指定多个监听地址，语法：
#
#   listen = protocol://[optional@]server_address:server_port
#
# 支持的 protocol 如下：
#
# HTTP (提供 http 代理):
#   listen = http://127.0.0.1:7777
#
#   上面的例子中，cow 生成的 PAC url 为 http://127.0.0.1:7777/pac
#   配置浏览器或系统 HTTP 和 HTTPS 代理时请填入该地址
#   若配置代理时有对所有协议使用该代理的选项，且你不清楚此选项的含义，请勾选
#
# cow (需两个 cow 服务器配合使用):
#   listen = cow://encrypt_method:password@1.2.3.4:5678
#
#   若 1.2.3.4:5678 在国外，位于国内的 cow 配置其为二级代理后，两个 cow 之间可以
#   通过加密连接传输 http 代理流量。目前的加密采用与 shadowsocks 相同的方式。
#
# 其他说明：
# - 若 server_address 为 0.0.0.0，监听本机所有 IP 地址
# - 可以用如下语法指定 PAC 中返回的代理服务器地址（当使用端口映射将 http 代理提供给外网时使用）
#   listen = http://127.0.0.1:7777 1.2.3.4:5678
#
listen = http://0.0.0.0:7777
#
# 日志文件路径，如不指定则输出到 stdout
logFile = /tmp/syslog.log
#
# COW 默认仅对被墙网站使用二级代理
# 下面选项设置为 true 后，所有网站都通过二级代理访问
#alwaysProxy = false
#
# 指定多个二级代理时使用的负载均衡策略，可选策略如下
#
#   backup:  默认策略，优先使用第一个指定的二级代理，其他仅作备份使用
#   hash:    根据请求的 host name，优先使用 hash 到的某一个二级代理
#   latency: 优先选择连接延迟最低的二级代理
#
# 一个二级代理连接失败后会依次尝试其他二级代理
# 失败的二级代理会以一定的概率再次尝试使用，因此恢复后会重新启用
loadBalance = backup
#
#############################
# 指定二级代理
#############################
#
# 二级代理统一使用下列语法指定：
#
#   proxy = protocol://[authinfo@]server:port
#
# 重复使用 proxy 多次指定多个二级代理，backup 策略将按照二级代理出现的顺序来使用
#
# 目前支持的二级代理及配置举例：
#
# SOCKS5:
#   proxy = socks5://127.0.0.1:1080
#
# HTTP:
#   proxy = http://127.0.0.1:8080
#   proxy = http://user:password@127.0.0.1:8080
#
#
# 自动生成ss-local_1.json配置
# 自动生成ss-local_2.json配置
#
#   用户认证信息为可选项
#
# shadowsocks:
#   proxy = ss://encrypt_method:password@1.2.3.4:8388
#   proxy = ss://encrypt_method-auth:password@1.2.3.4:8388
#
#   encrypt_method 添加 -auth 启用 One Time Auth
#   authinfo 中指定加密方法和密码，所有支持的加密方法如下：
#     aes-128-cfb, aes-192-cfb, aes-256-cfb,
#     bf-cfb, cast5-cfb, des-cfb, rc4-md5,
#     chacha20, salsa20, rc4, table
#   推荐使用 aes-128-cfb
#
# cow:
#   proxy = cow://method:passwd@1.2.3.4:4321
#
#   authinfo 与 shadowsocks 相同
#
#
#############################
# 执行 ssh 命令创建 SOCKS5 代理
#############################
#
# 下面的选项可以让 COW 执行 ssh 命令创建本地 SOCKS5 代理，并在 ssh 断开后重连
# COW 会自动使用通过 ssh 命令创建的代理，无需再通过 proxy 选项指定
# 可重复指定多个
#
# 注意这一功能需要系统上已有 ssh 命令，且必须使用 ssh public key authentication
#
# 若指定该选项，COW 将执行以下命令：
#     ssh -n -N -D <local_socks_port> -p <server_ssh_port> <user@server>
# server_ssh_port 端口不指定则默认为 22
# 如果要指定其他 ssh 选项，请修改 ~/.ssh/config
#sshServer = user@server:local_socks_port[:server_ssh_port]
#
#############################
# 认证
#############################
#
# 指定允许的 IP 或者网段。网段仅支持 IPv4，可以指定 IPv6 地址，用逗号分隔多个项
# 使用此选项时别忘了添加 127.0.0.1，否则本机访问也需要认证
#allowedClient = 127.0.0.1, 192.168.1.0/24, 10.0.0.0/8
#
# 要求客户端通过用户名密码认证
# COW 总是先验证 IP 是否在 allowedClient 中，若不在其中再通过用户名密码认证
#userPasswd = username:password
#
# 如需指定多个用户名密码，可在下面选项指定的文件中列出，文件中每行内容如下
#   username:password[:port]
# port 为可选项，若指定，则该用户只能从指定端口连接 COW
# 注意：如有重复用户，COW 会报错退出
#userPasswdFile = /path/to/file
#
# 认证失效时间
# 语法：2h3m4s 表示 2 小时 3 分钟 4 秒
#authTimeout = 2h
#
#############################
# 高级选项
#############################
#
# 将指定的 HTTP error code 认为是被干扰，使用二级代理重试，默认为空
#httpErrorCode =
#
# 最多允许使用多少个 CPU 核
#core = 2
#
# 检测超时时间使用的网站，最好使用能快速访问的站点
estimateTarget = www.baidu.com
#
# 允许建立隧道连接的端口，多个端口用逗号分隔，可重复多次
# 默认总是允许下列服务的端口: ssh, http, https, rsync, imap, pop, jabber, cvs, git, svn
# 如需允许其他端口，请用该选项添加
# 限制隧道连接的端口可以防止将运行 COW 的服务器上只监听本机 ip 的服务暴露给外部
#tunnelAllowedPort = 80, 443
#
# GFW 会使 DNS 解析超时，也可能返回错误的地址，能连接但是读不到任何内容
# 下面两个值改小一点可以加速检测网站是否被墙，但网络情况差时可能误判
#
# 创建连接超时（语法跟 authTimeout 相同）
#dialTimeout = 5s
# 从服务器读超时
#readTimeout = 5s
#
# 基于 client 是否很快关闭连接来检测 SSL 错误，只对 Chrome 有效
# （Chrome 遇到 SSL 错误会直接关闭连接，而不是让用户选择是否继续）
# 可能将可直连网站误判为被墙网站，当 GFW 进行 SSL 中间人攻击时可以考虑使用
#detectSSLErr = false
#
# 修改 stat/blocked/direct 文件路径，如不指定，默认在配置文件所在目录下
# 执行 cow 的用户需要有对 stat 文件所在目录的写权限才能更新 stat 文件
#statFile = <dir to rc file>/stat
blockedFile = /etc_ro/basedomain.txt
#directFile = <dir to rc file>/direct
#
#
COWCON
chmod 777 "/etc/storage/cow_config_script.sh"
    fi


cat > "/tmp/sh_cow.sh" <<-\FOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
cow_enable=`nvram get cow_enable`
cow_path=`nvram get cow_path`
[ -z $cow_path ] && cow_path=`which cow` && nvram set cow_path=$cow_path
ss_mode_x=`nvram get ss_mode_x`
ss_mode_x=${ss_mode_x:-"0"}
ss_rdd_server=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=`nvram get kcptun2_enable2`
kcptun2_enable2=${kcptun2_enable2:-"0"}
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s2_local_port=`nvram get ss_s2_local_port`
ss_s1_local_port=${ss_s1_local_port:-"1081"}
ss_s2_local_port=${ss_s2_local_port:-"1082"}
nvram set ss_s1_local_port=$ss_s1_local_port
nvram set ss_s2_local_port=$ss_s2_local_port
lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get cow_status`
B_restart="$cow_enable$cow_path$lan_ipaddr$ss_s1_local_port$ss_s2_local_port$ss_mode_x$ss_rdd_server$(cat /etc/storage/cow_script.sh /etc/storage/cow_config_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set cow_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$cow_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof cow`" ] && logger -t "【cow】" "停止 cow"
killall -9 cow cow_script.sh
fi
if [ "$cow_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
killall -9 cow cow_script.sh
SVC_PATH=$cow_path
if [ ! -f "$SVC_PATH" ] ; then
    SVC_PATH="/opt/bin/cow"
fi
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【cow】" "自动安装 cow 程序"
    # 找不到 cow，安装 opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【cow】" "找不到 $SVC_PATH 下载程序"
        wget --continue --no-check-certificate  -O  /opt/bin/cow "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/cow"
        chmod 755 "/opt/bin/cow"
    else
        logger -t "【cow】" "找到 $SVC_PATH"
    fi
    cow_path=`which cow` && nvram set cow_path=$cow_path
    SVC_PATH=$cow_path
fi

[ ! -s "$SVC_PATH" ] && {  logger -t "【cow】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; }

logger -t "【cow】" "运行 cow_script"
killall -9 cow cow_script.sh
/etc/storage/cow_script.sh
$cow_path -rc /etc/storage/cow_config_script.sh &
restart_dhcpd
sleep 3
[ ! -z "`pidof cow`" ] && logger -t "【cow】" "启动成功"
[ -z "`pidof cow`" ] && logger -t "【cow】" "启动失败, 注意检查端口是否有冲突,10秒后自动尝试重新启动" && sleep 10 && nvram set cow_status=00 && /tmp/sh_cow.sh &
fi

FOF
chmod 777 "/tmp/sh_cow.sh"


    if [ ! -f "/etc/storage/meow_script.sh" ] || [ ! -s "/etc/storage/meow_script.sh" ] ; then
cat > "/etc/storage/meow_script.sh" <<-\FOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
sed -Ei '/UI设置自动生成/d' /etc/storage/meow_config_script.sh
sed -Ei '/^$/d' /etc/storage/meow_config_script.sh
ss_mode_x=`nvram get ss_mode_x`
ss_mode_x=${ss_mode_x:-"0"}
ss_rdd_server=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=`nvram get kcptun2_enable2`
kcptun2_enable2=${kcptun2_enable2:-"0"}
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s2_local_port=`nvram get ss_s2_local_port`
ss_s1_local_port=${ss_s1_local_port:-"1081"}
ss_s2_local_port=${ss_s2_local_port:-"1082"}
nvram set ss_s1_local_port=$ss_s1_local_port
nvram set ss_s2_local_port=$ss_s2_local_port
lan_ipaddr=`nvram get lan_ipaddr`
sed -Ei "/$lan_ipaddr:$ss_s1_local_port/d" /etc/storage/meow_config_script.sh
sed -Ei "/$lan_ipaddr:$ss_s2_local_port/d" /etc/storage/meow_config_script.sh
if [ ! -f "/etc/storage/meow_direct_script.sh" ] || [ ! -s "/etc/storage/meow_direct_script.sh" ] ; then
logger -t "【meow】" "找不到 直连列表 下载 https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/direct.txt"
wget --continue --no-check-certificate  -O  /etc/storage/meow_direct_script.sh "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/direct.txt"
chmod 666 "/etc/storage/meow_direct_script.sh"
fi
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
cat >> "/etc/storage/meow_config_script.sh" <<-EUI
# UI设置自动生成 
proxy = socks5://$lan_ipaddr:$ss_s1_local_port
EUI
if [ ! -z $ss_rdd_server ] ; then
cat >> "/etc/storage/meow_config_script.sh" <<-EUI
# UI设置自动生成 
proxy = socks5://$lan_ipaddr:$ss_s2_local_port
EUI
fi
fi
FOF
chmod 777 "/etc/storage/meow_script.sh"
    fi
    if [ ! -f "/etc/storage/meow_config_script.sh" ] || [ ! -s "/etc/storage/meow_config_script.sh" ] ; then
cat > "/etc/storage/meow_config_script.sh" <<-\MECON
# 配置文件中 # 开头的行为注释
#
# 代理服务器监听地址，重复多次来指定多个监听地址，语法：
#
#   listen = protocol://[optional@]server_address:server_port
#
# 支持的 protocol 如下：
#
# HTTP (提供 http 代理):
#   listen = http://127.0.0.1:4411
#
#   上面的例子中，MEOW 生成的 PAC url 为 http://127.0.0.1:4411/pac
#
# HTTPS (提供 https 代理):
#   listen = https://example.com:443
#   cert = /path/to/cert.pem
#   key = /path/to/key.pem
#
#   上面的例子中，MEOW 生成的 PAC url 为 https://example.com:443/pac
#
# MEOW (需两个 MEOW 服务器配合使用):
#   listen = meow://encrypt_method:password@1.2.3.4:5678
#
#   若 1.2.3.4:5678 在国外，位于国内的 MEOW 配置其为二级代理后，两个 MEOW 之间可以
#   通过加密连接传输 http 代理流量。采用与 shadowsocks 相同的加密方式。
#
# 其他说明：
# - 若 server_address 为 0.0.0.0，监听本机所有 IP 地址
# - 可以用如下语法指定 PAC 中返回的代理服务器地址（当使用端口映射将 http 代理提供给外网时使用）
#   listen = http://127.0.0.1:4411 1.2.3.4:5678
#
listen = http://0.0.0.0:4411
#
#############################
# 通过IP判断是否直连，默认开启
#############################
#judgeByIP = true

# 日志文件路径，如不指定则输出到 stdout
logFile = /tmp/syslog.log
#
# 指定多个二级代理时使用的负载均衡策略，可选策略如下
#
#   backup:  默认策略，优先使用第一个指定的二级代理，其他仅作备份使用
#   hash:    根据请求的 host name，优先使用 hash 到的某一个二级代理
#   latency: 优先选择连接延迟最低的二级代理
#
# 一个二级代理连接失败后会依次尝试其他二级代理
# 失败的二级代理会以一定的概率再次尝试使用，因此恢复后会重新启用
loadBalance = backup
#
#############################
# 指定二级代理
#############################
#
# 二级代理统一使用下列语法指定：
#
#   proxy = protocol://[authinfo@]server:port
#
# 重复使用 proxy 多次指定多个二级代理，backup 策略将按照二级代理出现的顺序来使用
#
# 目前支持的二级代理及配置举例：
#
# SOCKS5:
#   proxy = socks5://127.0.0.1:1080
#
# HTTP:
#   proxy = http://127.0.0.1:8080
#   proxy = http://user:password@127.0.0.1:8080
#
#   用户认证信息为可选项
#
# HTTPS:
#   proxy = https://example.com:8080
#   proxy = https://user:password@example.com:8080
#
#   用户认证信息为可选项
#
# Shadowsocks:
#   proxy = ss://encrypt_method:password@1.2.3.4:8388
#
#   authinfo 中指定加密方法和密码，所有支持的加密方法如下：
#     aes-128-cfb, aes-192-cfb, aes-256-cfb,
#     bf-cfb, cast5-cfb, des-cfb, rc4-md5,
#     chacha20, salsa20, rc4, table
#
# MEOW:
#   proxy = meow://method:passwd@1.2.3.4:4321
#
#   authinfo 与 shadowsocks 相同
#
#
#############################
# 执行 ssh 命令创建 SOCKS5 代理
#############################
#
# 下面的选项可以让 MEOW 执行 ssh 命令创建本地 SOCKS5 代理，并在 ssh 断开后重连
# MEOW 会自动使用通过 ssh 命令创建的代理，无需再通过 proxy 选项指定
# 可重复指定多个
#
# 注意这一功能需要系统上已有 ssh 命令，且必须使用 ssh public key authentication
#
# 若指定该选项，MEOW 将执行以下命令：
#     ssh -n -N -D <local_socks_port> -p <server_ssh_port> <user@server>
# server_ssh_port 端口不指定则默认为 22
# 如果要指定其他 ssh 选项，请修改 ~/.ssh/config
#sshServer = user@server:local_socks_port[:server_ssh_port]
#
#############################
# 认证
#############################
#
# 指定允许的 IP 或者网段。网段仅支持 IPv4，可以指定 IPv6 地址，用逗号分隔多个项
# 使用此选项时别忘了添加 127.0.0.1，否则本机访问也需要认证
#allowedClient = 127.0.0.1, 192.168.1.0/24, 10.0.0.0/8
#
# 要求客户端通过用户名密码认证
# MEOW 总是先验证 IP 是否在 allowedClient 中，若不在其中再通过用户名密码认证
#userPasswd = username:password
#
# 如需指定多个用户名密码，可在下面选项指定的文件中列出，文件中每行内容如下
#   username:password[:port]
# port 为可选项，若指定，则该用户只能从指定端口连接 MEOW
# 注意：如有重复用户，MEOW 会报错退出
#userPasswdFile = /path/to/file
#
# 认证失效时间
# 语法：2h3m4s 表示 2 小时 3 分钟 4 秒
#authTimeout = 2h
#
#############################
# 高级选项
#############################
#
# 将指定的 HTTP error code 认为是被干扰，使用二级代理重试，默认为空
#httpErrorCode =
#
# 最多允许使用多少个 CPU 核
#core = 2
#
# 修改 direct/proxy 文件路径，如不指定，默认在配置文件所在目录下
directFile = /etc/storage/meow_direct_script.sh
proxyFile = /etc_ro/basedomain.txt
MECON
chmod 777 "/etc/storage/meow_config_script.sh"
    fi


cat > "/tmp/sh_meow.sh" <<-\FOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
meow_enable=`nvram get meow_enable`
meow_path=`nvram get meow_path`
[ -z $meow_path ] && meow_path=`which meow` && nvram set meow_path=$meow_path
ss_mode_x=`nvram get ss_mode_x`
ss_mode_x=${ss_mode_x:-"0"}
ss_rdd_server=`nvram get ss_server2`
kcptun2_enable=`nvram get kcptun2_enable`
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=`nvram get kcptun2_enable2`
kcptun2_enable2=${kcptun2_enable2:-"0"}
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_rdd_server=""
ss_run_ss_local=`nvram get ss_run_ss_local`
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s2_local_port=`nvram get ss_s2_local_port`
ss_s1_local_port=${ss_s1_local_port:-"1081"}
ss_s2_local_port=${ss_s2_local_port:-"1082"}
nvram set ss_s1_local_port=$ss_s1_local_port
nvram set ss_s2_local_port=$ss_s2_local_port
lan_ipaddr=`nvram get lan_ipaddr`
A_restart=`nvram get meow_status`
B_restart="$meow_enable$meow_path$lan_ipaddr$ss_s1_local_port$ss_s2_local_port$ss_mode_x$ss_rdd_server$(cat /etc/storage/meow_script.sh /etc/storage/meow_config_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set meow_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$meow_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof meow`" ] && logger -t "【meow】" "停止 meow"
killall -9 meow meow_script.sh
fi
if [ "$meow_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
killall -9 meow meow_script.sh
SVC_PATH=$meow_path
if [ ! -f "$SVC_PATH" ] ; then
    SVC_PATH="/opt/bin/meow"
fi
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【meow】" "自动安装 meow 程序"
    # 找不到 meow，安装 opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【meow】" "找不到 $SVC_PATH 下载程序"
        wget --continue --no-check-certificate  -O  /opt/bin/meow "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/meow"
        chmod 755 "/opt/bin/meow"
    else
        logger -t "【meow】" "找到 $SVC_PATH"
    fi
    meow_path=`which meow` && nvram set meow_path=$meow_path
    SVC_PATH=$meow_path
fi

[ ! -s "$SVC_PATH" ] && {  logger -t "【meow】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; }

logger -t "【meow】" "运行 meow_script"
killall -9 meow meow_script.sh
/etc/storage/meow_script.sh
$meow_path -rc /etc/storage/meow_config_script.sh &
restart_dhcpd
sleep 3
[ ! -z "`pidof meow`" ] && logger -t "【meow】" "启动成功"
[ -z "`pidof meow`" ] && logger -t "【meow】" "启动失败, 注意检查端口是否有冲突,10秒后自动尝试重新启动" && sleep 10 && nvram set meow_status=00 && /tmp/sh_meow.sh &
fi

FOF
chmod 777 "/tmp/sh_meow.sh"


    if [ ! -f "/etc/storage/softether_script.sh" ] || [ ! -s "/etc/storage/softether_script.sh" ] ; then
cat > "/etc/storage/softether_script.sh" <<-\FOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/softether:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
softether_path=`nvram get softether_path`
[ -z $softether_path ] && softether_path=`which vpnserver` && nvram set softether_path=$softether_path
SVC_PATH=$softether_path
[ -f /opt/softether/vpn_server.config ] && [ ! -f /etc/storage/vpn_server.config ] && cp -f /opt/softether/vpn_server.config /etc/storage/vpn_server.config
[ ! -f /etc/storage/vpn_server.config ] && touch /etc/storage/vpn_server.config
ln -sf /etc/storage/vpn_server.config /opt/softether/vpn_server.config
$SVC_PATH start
i=120
until [ ! -z "$tap" ]
do
    i=$(($i-1))
    tap=`ifconfig | grep tap_ | awk '{print $1}'`
    if [ "$i" -lt 1 ];then
        logger -t "【softether】" "错误：不能正确启动 vpnserver!"
        rm -rf /etc/storage/dnsmasq/dnsmasq.d/softether.conf
        restart_dhcpd
        logger -t "【softether】" "错误：不能正确启动 vpnserver!"
        [ -z "`pidof vpnserver`" ] && logger -t "【softether】" "启动失败, 注意检查hamcore.se2、vpncmd、vpnserver是否下载完整,10秒后自动尝试重新启动" && sleep 10 && nvram set softether_status=00 && /tmp/sh_softether.sh &
        exit
    fi
    sleep 1
done

logger -t "【softether】" "正确启动 vpnserver!"
brctl addif br0 $tap
echo interface=tap_vpn > /etc/storage/dnsmasq/dnsmasq.d/softether.conf
restart_dhcpd
mtd_storage.sh save &
FOF
chmod 777 "/etc/storage/softether_script.sh"
    fi



cat > "/tmp/sh_softether.sh" <<-\FOF
#!/bin/sh
export PATH='/opt/usr/sbin:/opt/softether:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
softether_enable=`nvram get softether_enable`
softether_path=`nvram get softether_path`
[ -z $softether_path ] && softether_path=`which vpnserver` && nvram set softether_path=$softether_path
SVC_PATH=$softether_path
A_restart=`nvram get softether_status`
B_restart="$softether_enable$softether_path$(cat /etc/storage/softether_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set softether_status=$B_restart
    needed_restart=1
else
    needed_restart=0
fi
if [ "$softether_enable" = "0" ] && [ "$needed_restart" = "1" ] ; then
[ ! -z "`pidof vpnserver`" ] && logger -t "【softether】" "停止 vpnserver"
$SVC_PATH stop
killall -9 vpnserver softether_script.sh
rm -rf /etc/storage/dnsmasq/dnsmasq.d/softether.conf
restart_dhcpd
fi
if [ "$softether_enable" = "1" ] && [ "$needed_restart" = "1" ] ; then
$SVC_PATH stop
killall -9 vpnserver softether_script.sh
if [ ! -f "$SVC_PATH" ] ; then
    SVC_PATH="/opt/softether/vpnserver"
fi
if [ ! -f "$SVC_PATH" ] ; then
    logger -t "【softether】" "自动安装 softether 程序"
    # 找不到 softether，安装 opt
    if [ ! -d "/opt/softether" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/softether
    fi
    if [ ! -f "$SVC_PATH" ] ; then
        logger -t "【softether】" "找不到 $SVC_PATH 下载程序"
        wget --continue --no-check-certificate  -O  /opt/softether/vpnserver "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/vpnserver"
        chmod 755 "/opt/softether/vpnserver"
        wget --continue --no-check-certificate  -O  /opt/softether/vpncmd "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/vpncmd"
        chmod 755 "/opt/softether/vpncmd"
        wget --continue --no-check-certificate  -O  /opt/softether/hamcore.se2 "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/hamcore.se2"
        chmod 755 "/opt/softether/hamcore.se2"
    else
        logger -t "【softether】" "找到 $SVC_PATH"
    fi
fi
    softether_path=$SVC_PATH && nvram set softether_path=$softether_path
    SVC_PATH=$softether_path
[ ! -s "$SVC_PATH" ] && {  logger -t "【softether】" "找不到 $SVC_PATH ，需要手动安装 $SVC_PATH"; }

logger -t "【softether】" "运行 softether_script"
$SVC_PATH stop
killall -9 vpnserver softether_script.sh
/etc/storage/softether_script.sh &
sleep 20
[ ! -z "`pidof vpnserver`" ] && logger -t "【softether】" "启动成功"
[ -z "`pidof vpnserver`" ] && logger -t "【softether】" "启动失败, 注意检查hamcore.se2、vpncmd、vpnserver是否下载完整,10秒后自动尝试重新启动" && sleep 10 && nvram set softether_status=00 && /tmp/sh_softether.sh &
fi

FOF
chmod 777 "/tmp/sh_softether.sh"



cat > "/tmp/ss.sh" <<-\FOF
#!/bin/sh
#================华丽的分割线====================================
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
set -x
#初始化开始
TAG="SS_SPEC"          # iptables tag
FWI="/tmp/firewall.shadowsocks.pdcn" # firewall include file

ss_enable=`nvram get ss_enable`
ss_enable=${ss_enable:-"0"}
ss_type=`nvram get ss_type`
ss_run_ss_local=`nvram get ss_run_ss_local`

kcptun_enable=`nvram get kcptun_enable`
kcptun_enable=${kcptun_enable:-"0"}
kcptun2_enable=`nvram get kcptun2_enable`
kcptun2_enable=${kcptun2_enable:-"0"}
kcptun2_enable2=`nvram get kcptun2_enable2`
kcptun2_enable2=${kcptun2_enable2:-"0"}

kcptun_server=`nvram get kcptun_server`
if [ "$kcptun_enable" != "0" ] ; then
resolveip=`/usr/bin/resolveip -4 -t 10 $kcptun_server | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`nslookup $kcptun_server | awk 'NR==5{print $3}'` 
kcptun_server=$resolveip
fi
[ "$kcptun_enable" = "0" ] && kcptun_server=""
nvram set ss_server1=`nvram get ss_server`
nvram set ss_s1_port=`nvram get ss_server_port`
nvram set ss_s1_key=`nvram get ss_key`
nvram set ss_s1_method=`nvram get ss_method`

#以后多线支持弄个循环，现在只做两线就算了，如果
#如果server2 只设置了ip，则其他配置与S1一样
ss_s1_local_address=`nvram get ss_s1_local_address`
ss_s2_local_address=`nvram get ss_s2_local_address`
ss_s1_local_address=${ss_s1_local_address:-"0.0.0.0"}
ss_s2_local_address=${ss_s2_local_address:-"0.0.0.0"}
nvram set ss_s1_local_address=$ss_s1_local_address
nvram set ss_s2_local_address=$ss_s2_local_address
ss_s1_local_port=`nvram get ss_s1_local_port`
ss_s2_local_port=`nvram get ss_s2_local_port`
ss_s1_local_port=${ss_s1_local_port:-"1081"}
ss_s2_local_port=${ss_s2_local_port:-"1082"}
nvram set ss_s1_local_port=$ss_s1_local_port
nvram set ss_s2_local_port=$ss_s2_local_port
ss_server1=`nvram get ss_server1`
ss_server2=`nvram get ss_server2`

ss_s1_port=`nvram get ss_s1_port`
ss_s2_port=`nvram get ss_s2_port`
ss_s2_port=${ss_s2_port:-$ss_s1_port}
ss_s1_method=`nvram get ss_s1_method| tr 'A-Z' 'a-z'`
ss_s2_method=`nvram get ss_s2_method| tr 'A-Z' 'a-z'`
ss_s2_method=${ss_s2_method:-$ss_s1_method}
ss_s1_key=`nvram get ss_s1_key`
ss_s2_key=`nvram get ss_s2_key`
ss_s2_key=${ss_s2_key:-$ss_s1_key}
ss_pdnsd_wo_redir=`nvram get ss_pdnsd_wo_redir` #pdnsd  0、走代理；1、直连
ss_pdnsd_wo_redir=${ss_pdnsd_wo_redir:-"0"}
ss_mode_x=`nvram get ss_mode_x` #ss模式，0 为chnroute, 1 为 gfwlist, 2 为全局, 3为ss-local 建立本地 SOCKS 代理
ss_mode_x=${ss_mode_x:-"0"}
ss_working_port=`nvram get ss_working_port` #working port 不需要在界面设置，在watchdog里面设置。
ss_working_port=${ss_working_port:-"1090"}
ss_multiport=`nvram get ss_multiport`
[ -z "$ss_multiport" ] && ss_multiport="22,80,443" && nvram set ss_multiport=$ss_multiport
[ -n "$ss_multiport" ] && ss_multiport="-m multiport --dports $ss_multiport" || ss_multiport="-m multiport --dports 22,80,443" # 处理多端口设定
# 严重警告，如果走chnrouter 和全局模式，又不限制端口，下载流量都会通过你的ss服务器往外走，随时导致你的ss服务器被封或ss服务商封你帐号，设置连累你的SS服务商被封

# DNS 端口，用于防止域名污染用的PDNSD
DNS_Server=127.0.0.1#8053

ss_pdnsd_all=`nvram get ss_pdnsd_all`
[ "$ss_mode_x" != "0" ] && kcptun2_enable=$kcptun2_enable2
[ "$kcptun2_enable" = "2" ] && ss_server2=""
[ -z "$ss_server2" ] && [ "$kcptun2_enable" != "2" ] && kcptun2_enable=2 && logger -t "【SS】" "设置内容:非 chnroute 模式, 备服务器 停用"
[ "$ss_mode_x" != "0" ] && [ ! -z "$ss_server2" ] && [ "$kcptun2_enable" != "2" ] && kcptun2_enable=0 && logger -t "【SS】" "设置内容:非 chnroute 模式，备服务器 故障转移 模式"
[ "$ss_mode_x" != "0" ] && nvram set kcptun2_enable2=$kcptun2_enable
[ "$ss_mode_x" = "0" ] && nvram set kcptun2_enable=$kcptun2_enable
[ "$ss_pdnsd_all" = "1" ] && [ "$ss_mode_x" != "0" ] && ss_pdnsd_all=0 && logger -t "【SS】" "设置内容:非 chnroute 模式，不转全部发pdnsd"
[ "$ss_pdnsd_all" = "1" ] && [ "$kcptun2_enable" = "1" ] && ss_pdnsd_all=0 && logger -t "【SS】" "设置内容:开启 kcptun+gfwlist 模式，不转全部发 pdnsd"
nvram set ss_pdnsd_all=$ss_pdnsd_all
ss_3p_enable=`nvram get ss_3p_enable`
ss_3p_gfwlist=`nvram get ss_3p_gfwlist`
ss_3p_kool=`nvram get ss_3p_kool`


ss_sub1=`nvram get ss_sub1`
ss_sub2=`nvram get ss_sub2`
ss_sub3=`nvram get ss_sub3`
ss_sub4=`nvram get ss_sub4`

ss_tochina_enable=`nvram get ss_tochina_enable`
ss_tochina_enable=${ss_tochina_enable:-"0"}
ss_udp_enable=`nvram get ss_udp_enable` #udp转发  0、停用；1、启动
ss_udp_enable=${ss_udp_enable:-"0"}
ss_upd_rules=`nvram get ss_upd_rules`
if [ ! -z "$ss_upd_rules" ] ; then
    ss_upd_rules="-s $ss_upd_rules" 
fi
# ss_upd_rules UDP参数用法，暂时不考虑字符安全过滤的问题，单用户系统输入，并且全root开放的平台，你愿意注入自己的路由器随意吧。
# 范例 
# 单机全部 192.168.123.10 
# 多台单机 192.168.123.10,192.168.123.12
# 子网段  192.168.123.16/28  不知道怎么设置自己找在线子网掩码工具计算
# 单机但限定目的端口  192.168.123.10 --dport 3000:30010
# 如果需要更加细节的设置，可以让用户自己修改一个iptables 文件来处理。

ss_usage=`nvram get ss_usage`
ss_s2_usage=`nvram get ss_s2_usage`

# 混淆参数
ssr_type_obfs_custom=`nvram get ssr_type_obfs_custom`
ssr2_type_obfs_custom=`nvram get ssr2_type_obfs_custom`
[ ! -z "$ssr_type_obfs_custom" ] && [ "$ss_type" = "1" ] && ss_usage_json=" -g $ssr_type_obfs_custom"
[ ! -z "$ssr2_type_obfs_custom" ] && [ "$ss_type" = "1" ] && ss_s2_usage_json=" -g $ssr2_type_obfs_custom"
touch /etc/storage/shadowsocks_mydomain_script.sh
LAN_AC_IP=`nvram get LAN_AC_IP`
LAN_AC_IP=${LAN_AC_IP:-"0"}

lan_ipaddr=`nvram get lan_ipaddr`
ss_DNS_Redirect=`nvram get ss_DNS_Redirect`
ss_DNS_Redirect_IP=`nvram get ss_DNS_Redirect_IP`
[ -z "$ss_DNS_Redirect_IP" ] && ss_DNS_Redirect_IP=$lan_ipaddr

##  bigandy modify 
##  1. 增加xbox的支持 （未实现，下一版本）
##  2. 改写获取gfwlist逻辑
##  3. 增加对自定义域名的支持
##  4. 订阅机制，提供网站加速的列表订阅功能
##ss_xbox=`nvram get ss_xbox`  //andy
ss_s1_ip=""
ss_s2_ip=""

# 
GFWLIST_TARGET=""
ACB_TARGET=""
LAN_TARGET=""
WAN_TARGET=""
WAN_H_TARGET=""
SH_TARGET=""
SH_H_TARGET=""
ip_list=""
wifidognx=""

#检查 dnsmasq 目录参数
confdir=`grep conf-dir /etc/storage/dnsmasq/dnsmasq.conf | sed 's/.*\=//g'`
if [ -z "$confdir" ] ; then 
    confdir="/tmp/ss/dnsmasq.d"
fi
[ ! -z "$confdir" ] && mkdir -p $confdir

# 创建JSON
cat > "/tmp/SSJSON.sh" <<-\SSJSONSH
while getopts ":o:O:g:G:s:p:b:l:k:m:f:" arg; do
    case "$arg" in
        o)
            obfs=$OPTARG
            ;;
        O)
            protocol=$OPTARG
            ;;
        g)
            obfs_param=$OPTARG
            ;;
        G)
            protocol_param=$OPTARG
            ;;
        s)
            server=$OPTARG
            ;;
        p)
            server_port=$OPTARG
            ;;
        b)
            local_address=$OPTARG
            ;;
        l)
            local_port=$OPTARG
            ;;
        k)
            password=$OPTARG
            ;;
        m)
            method=$OPTARG
            ;;
        f)
            config_file=$OPTARG
            ;;
    esac
done
cat > "$config_file" <<-SSJSON
{
"server": "$server",
"server_port": "$server_port",
"local_address": "$local_address",
"local_port": "$local_port",
"password": "$password",
"timeout": "180",
"method": "$method",
"protocol": "$protocol",
"protocol_param": "$protocol_param",
"obfs": "$obfs",
"obfs_param": "$obfs_param"
}
SSJSON
SSJSONSH
chmod 755 /tmp/SSJSON.sh

start_ss_redir()
{
logger -t "【ss-redir】" "启动所有的 SS 连线, 出现的 SS 日志并不是错误报告, 只是使用状态日志, 请不要慌张, 只要系统正常你又看不懂就无视它！"
logger -t "【SS】" "SS服务器1 设置内容：$ss_server1 端口:$ss_s1_port 加密方式:$ss_s1_method "
[ -z "$ss_server1" ] && { logger -t "【SS】" "[错误!!] SS服务器没有设置"; stop_SS; exit 0; } 
[ ! -z "$ss_server1" ] && ss_s1_ip=`/usr/bin/resolveip -4 -t 10 $ss_server1 | grep -v : | sed -n '1p'`
[ -z "$ss_s1_ip" ] && ss_s1_ip=`nslookup $ss_server1 | awk 'NR==5{print $3}'` 
[ -z "$ss_s1_ip" ] && { logger -t "【SS】" "[错误!!] 实在找不到你的SS1服务器IP，麻烦看看哪里错了？"; stop_SS; exit 0; } 
[ ! -z "$ss_server2" ] && ss_s2_ip=`/usr/bin/resolveip -4 -t 10 $ss_server2 | grep -v : | sed -n '1p'`
[ ! -z "$ss_server2" ] && [ -z "$ss_s2_ip" ] && ss_s2_ip=`nslookup $ss_server2 | awk 'NR==5{print $3}'`
[ ! -z "$ss_server2" ] && [ -z "$ss_s2_ip" ] && { logger -t "【SS】" "[错误!!] 实在找不到你的SS2服务器IP，麻烦看看哪里错了？"; } 
[ ! -z "$ss_s2_ip" ] && ss_ip="$ss_s1_ip,$ss_s2_ip" || ss_ip=$ss_s1_ip
if [ "$ss_udp_enable" == 1 ] ; then
ss_usage="$ss_usage -u"
ss_s2_usage="$ss_s2_usage -u"
fi

options1=""
options1=${ss_usage//-o/}
options1=${options1//-O/}
options1=${options1//origin/}
options1=${options1//verify_simple/}
options1=${options1//verify_deflate/}
options1=${options1//verify_sha1/}
options1=${options1//auth_simple/}
options1=${options1//auth_sha1_v2/}
options1=${options1//auth_sha1_v4/}
options1=${options1//auth_aes128_md5/}
options1=${options1//auth_aes128_sha1/}
options1=${options1//auth_sha1/}
options1=${options1//plain/}
options1=${options1//http_simple/}
options1=${options1//http_post/}
options1=${options1//tls_simple/}
options1=${options1//random_head/}
options1=${options1//tls1.2_ticket_auth/}
options2=""
options2=${ss_s2_usage//-o/}
options2=${options2//-O/}
options2=${options2//origin/}
options2=${options2//verify_simple/}
options2=${options2//verify_deflate/}
options2=${options2//verify_sha1/}
options2=${options2//auth_simple/}
options2=${options2//auth_sha1_v2/}
options2=${options2//auth_sha1_v4/}
options2=${options2//auth_aes128_md5/}
options2=${options2//auth_aes128_sha1/}
options2=${options2//auth_sha1/}
options2=${options2//plain/}
options2=${options2//http_simple/}
options2=${options2//http_post/}
options2=${options2//tls_simple/}
options2=${options2//random_head/}
options2=${options2//tls1.2_ticket_auth/}

# 启动程序

    pidof ss-redir  >/dev/null 2>&1 && killall -9 ss-redir 2>/dev/null
    /tmp/SSJSON.sh -f /tmp/ss-redir_1.json $ss_usage $ss_usage_json -s $ss_s1_ip -p $ss_s1_port -l 1090 -b 0.0.0.0 -k $ss_s1_key -m $ss_s1_method
    ss-redir -c /tmp/ss-redir_1.json $options1 >/dev/null 2>&1 &
    if [ ! -z $ss_server2 ] ; then
        #启动第二个SS 连线
        [  -z "$ss_s2_ip" ] && { logger -t "【SS】" "[错误!!] 无法获得 SS 服务器2的IP, 请核查设置"; stop_SS; exit 0; }
        logger -t "【SS】" "SS服务器2 设置内容：$ss_server2 端口:$ss_s2_port 加密方式:$ss_s2_method "
        /tmp/SSJSON.sh -f /tmp/ss-redir_2.json $ss_s2_usage $ss_s2_usage_json -s $ss_s2_ip -p $ss_s2_port -l 1091 -b 0.0.0.0 -k $ss_s2_key -m $ss_s2_method
        ss-redir -c /tmp/ss-redir_2.json $options2 >/dev/null 2>&1 &
    fi
    check_ip
if [ "$ss_mode_x" = "3" ] || [ "$ss_run_ss_local" = "1" ] ; then
    [ "$ss_mode_x" = "3" ] && killall ss-redir
    logger -t "【ss-local】" "启动所有的 ss-local 连线, 出现的 SS 日志并不是错误报告, 只是使用状态日志, 请不要慌张, 只要系统正常你又看不懂就无视它！"
    pidof ss-local  >/dev/null 2>&1 && killall -9 ss-local 2>/dev/null
    logger -t "【ss-local】" "本地监听地址：$ss_s1_local_address 本地代理端口：$ss_s1_local_port SS服务器1 设置内容：$ss_server1 端口:$ss_s1_port 加密方式:$ss_s1_method "
    /tmp/SSJSON.sh -f /tmp/ss-local_1.json $ss_usage $ss_usage_json -s $ss_s1_ip -p $ss_s1_port -b $ss_s1_local_address -l $ss_s1_local_port -k $ss_s1_key -m $ss_s1_method
    ss-local -c /tmp/ss-local_1.json $options1 >/dev/null 2>&1 &
    if [ ! -z $ss_server2 ] ; then
        #启动第二个SS 连线
        [  -z "$ss_s2_ip" ] && { logger -t "【ss-local】" "[错误!!] 无法获得 SS 服务器2的IP,请核查设置"; stop_SS; exit 0; }
        logger -t "【ss-local】" "本地监听地址：$ss_s2_local_address 本地代理端口：$ss_s2_local_port SS服务器2 设置内容：$ss_server2 端口:$ss_s2_port 加密方式:$ss_s2_method "
        /tmp/SSJSON.sh -f /tmp/ss-local_2.json $ss_s2_usage $ss_s2_usage_json -s $ss_s2_ip -p $ss_s2_port -b $ss_s2_local_address -l $ss_s2_local_port -k $ss_s2_key -m $ss_s2_method
        ss-local -c /tmp/ss-local_2.json $options2 >/dev/null 2>&1 &
    fi
fi
}


check_ssr()
{
umount /usr/sbin/ss-redir
umount /usr/sbin/ss-local
if [ "$ss_type" = "1" ] ; then
    if [ -s "/usr/sbin/ssr-redir" ] ; then
        mount --bind /usr/sbin/ssr-redir /usr/sbin/ss-redir
    else
        if [ ! -s "/tmp/bin/ssr-redir" ] ; then
            logger -t "【SSR】" "找不到 ssr-redir. tmp下载程序"
            mkdir -p /tmp/bin
            /tmp/sh_download.sh "/tmp/bin/ssr-redir" "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/ssr-redir"
            chmod 777 "/tmp/bin/ssr-redir"
        fi
        mount --bind /tmp/bin/ssr-redir /usr/sbin/ss-redir
    fi
    if [ -s "/usr/sbin/ssr-local" ] ; then
        mount --bind /usr/sbin/ssr-local /usr/sbin/ss-local
    else
        if [ ! -s "/tmp/bin/ssr-local" ] ; then
            logger -t "【SSR】" "找不到 ssr-local. tmp下载程序"
            mkdir -p /tmp/bin
            /tmp/sh_download.sh "/tmp/bin/ssr-local" "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/ssr-local"
            chmod 777 "/tmp/bin/ssr-local"
        fi
        mount --bind /tmp/bin/ssr-local /usr/sbin/ss-local
    fi
fi
}


check_ip()
{
ss_check=`nvram get ss_check`
if [ "$ss_check" = "1" ] ; then
    # 检查主服务器是否能用
    checkip=0
    sleep 3
for action_port in 1090 1091
do
    action_port=$action_port
    echo $action_port
    [ $action_port == 1090 ] && action_ssip=$ss_s1_ip
    [ $action_port == 1091 ] && action_ssip=$ss_s2_ip
if [ ! -z "$action_ssip" ] ; then
    logger -t "【ss-redir】" "check_ip 检查 SS 服务器$action_port是否能用"
    lan_ipaddr=`nvram get lan_ipaddr`
    BP_IP="$ss_s1_ip,$ss_s2_ip,$kcptun_server"
    ss-rules -s "$action_ssip" -l "$action_port" -b $BP_IP -d "RETURN" -a "g,$lan_ipaddr" -e '-m multiport --dports 80' -o -O
    sleep 1
    wget --continue --no-check-certificate -s -q -T 10 www.baidu.com
    if [ "$?" == "0" ] ; then
        logger -t "【ss-redir】" "check_ip 检查 SS 服务器 $action_port 代理连接 www.baidu.com 成功"
        checkip=1
    else
        logger -t "【ss-redir】" "check_ip 检查 SS 服务器 $action_port 代理连接 www.baidu.com 失败"
        [ ${action_port:=1090} ] && [ $action_port == 1091 ] && Server=1090 || Server=1091
        #加上切换标记
        nvram set ss_working_port=$Server
        ss_working_port=`nvram get ss_working_port`
        [ "$checkip" == "0" ] && checkip=0
    fi
    # #使用高春辉的IPIP.net来解析ip，感觉应该会稳定吧。
    # getip=`wget --continue --no-check-certificate www.ipip.net -O- -q | grep ip_text | grep -o '\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}'`
    # echo "ssip: "$action_ssip
    # echo "ipip.net: "$getip
    # if [ "$action_ssip" != "$getip" ] ; then
        # logger -t "【ss-redir】" "check_ip 检查 SS 服务器 $action_port 代理连接失败，由于代理ip不符，启动设置ip为： $action_ssip 规则获取ip为： $getip"
        # [ ${action_port:=1090} ] && [ $action_port == 1091 ] && Server=1090 || Server=1091
        # #加上切换标记
        # nvram set ss_working_port=$Server
        # ss_working_port=`nvram get ss_working_port`
        # [ "$checkip" == "0" ] && checkip=0
    # else
        # logger -t "【ss-redir】" "check_ip 检查 SS 服务器 $action_port 代理连接成功, 规则获取ip为:$getip"
        # nvram set ss_working_port=$action_port
        # ss_working_port=`nvram get ss_working_port`
        # checkip=1
    # fi
fi
    ss-rules -f
done
echo "checkip: "$checkip
if [ "$checkip" == "0" ] ; then
    logger -t "【ss-redir】" "check_ip 检查两个 SS 服务器代理连接失败, 请检查配置, 10秒后重启shadowsocks"

    killall ss-local ss-redir
    sleep 10
    /etc/storage/ez_buttons_script.sh cleanss &
    sleep 5
    exit 0
fi
fi
}

start_pdnsd()
{
    logger -t "【SS】" "启动 pdnsd 防止域名污染"
    pidof pdnsd >/dev/null 2>&1 && killall -9 pdnsd 2>/dev/null
pdnsd_conf="/etc/storage/pdnsd.conf"
if [ ! -f "$pdnsd_conf" ] ; then
    cat > $pdnsd_conf <<-\END
global {
perm_cache=2048;
cache_dir="/var/pdnsd";
run_as="nobody";
server_port = 8053;
server_ip = 0.0.0.0;
status_ctl = on;
query_method=tcp_only;
min_ttl=1m;
max_ttl=1w;
timeout=5;
}

server {
label= "opendns";
ip = 208.67.222.222, 208.67.220.220; 
port = 443;       
root_server = on;    
uptest= none;         
}

server {
label= "google dns";
ip = 8.8.8.8, 8.8.4.4; 
port = 53;       
root_server = on;    
uptest= none;         
}


END
fi
    chmod 755 $pdnsd_conf
CACHEDIR=/var/pdnsd
CACHE=$CACHEDIR/pdnsd.cache

USER=nobody
GROUP=nogroup

if ! test -f "$CACHE"; then
    mkdir -p `dirname $CACHE`
    dd if=/dev/zero of="$CACHE" bs=1 count=4 2> /dev/null
    chown -R $USER.$GROUP $CACHEDIR
fi
pdnsd -c $pdnsd_conf -p /var/run/pdnsd.pid &

}


clean_ss_rules()
{
echo "clean_ss_rules"
flush_r
    ipset destroy gfwlist
    iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port 1090
    iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port 1090
    iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port 1091
    iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port 1091
    iptables -t nat -D OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j RETURN
    iptables -t nat -D OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j RETURN
}

flush_r() {
    iptables-save -c | grep -v "$TAG" | iptables-restore -c
    ip rule del fwmark 1 lookup 100 2>/dev/null
    ip route del local default dev lo table 100 2>/dev/null
    for setname in $(ipset -n list | grep -i "$TAG"); do
        ipset destroy $setname 2>/dev/null
    done
    [ -n "$FWI" ] && echo '#!/bin/sh' >$FWI
    return 0
}

start_ss_rules()
{
#载入iptables模块
for module in ip_set ip_set_bitmap_ip ip_set_bitmap_ipmac ip_set_bitmap_port ip_set_hash_ip ip_set_hash_ipport ip_set_hash_ipportip ip_set_hash_ipportnet ip_set_hash_net ip_set_hash_netport ip_set_list_set xt_set xt_TPROXY
do
    modprobe $module
done 
    logger -t "【SS】" "设置 SS 的防火墙规则"
    clean_ss_rules
    echo "start_ss_rules"
#内网LAN代理转发白名单设置
#    0  默认值, 常规, 未在以下设定的 内网IP 根据 SS配置工作模式 走 SS
#    1         全局, 未在以下设定的 内网IP 使用全局代理 走 SS
#    2         绕过, 未在以下设定的 内网IP 不使用 SS
mkdir /tmp/ss -p
if [ -n "$LAN_AC_IP" ] ; then
    case "${LAN_AC_IP:0:1}" in
        0)
            LAN_TARGET="SS_SPEC_WAN_AC"
            DNS_LAN_TARGET="SS_SPEC_DNS_WAN_AC"
            ;;
        1)
            LAN_TARGET="SS_SPEC_WAN_FW"
            DNS_LAN_TARGET="SS_SPEC_DNS_WAN_FW"
            ;;
        2)
            LAN_TARGET="RETURN"
            DNS_LAN_TARGET="RETURN"
            ;;
    esac
fi
    
    #如果是 gfwlist 模式，则 gfwlist 为 ipash，chnroute 模式，则为 hash:net模式
    ipset -! -N gfwlist iphash
    ipset -! -N cflist iphash

    # rules规则
    ipset -! restore <<-EOF || return 1
create ss_spec_src_ac hash:ip hashsize 64
create ss_spec_src_bp hash:ip hashsize 64
create ss_spec_src_fw hash:ip hashsize 64
create ss_spec_dst_sp hash:net hashsize 64
create ss_spec_dst_bp hash:net hashsize 64
create ss_spec_dst_fw hash:net hashsize 64
create ss_spec_dst_sh hash:net hashsize 64
create ss_spec_src_gfw hash:net hashsize 64
create ss_spec_src_chn hash:net hashsize 64
$(gen_special_purpose_ip | sed -e "s/^/add ss_spec_dst_sp /")
EOF


if [ "$ss_mode_x" = "0" ] ; then
# 0 为 chnroute 规则
    if [ "$kcptun2_enable" = "1" ] ; then
        # Kcptun_enable
        logger -t "【SS】" "备服务器 同时启用 GFW 规则代理"
        GFWLIST_TARGET="SS_SPEC_WAN_KCPTUN"
        ACB_TARGET="SS_SPEC_WAN_KAC"
    fi
    if [ "$ss_tochina_enable" = "0" ] ; then
    # 出国模式
        logger -t "【SS】" "出国模式" && echo "ss_tochina_enable:$ss_tochina_enable"
        SH_TARGET="RETURN"
        SH_H_TARGET="RETURN"
        WAN_TARGET="SS_SPEC_WAN_FW"
        WAN_H_TARGET="SS_SPEC_WAN_FW"
    else
    # 回国模式
        logger -t "【SS】" "回国模式" && echo "ss_tochina_enable:$ss_tochina_enable"
        SH_TARGET="SS_SPEC_WAN_FW"
        SH_H_TARGET="SS_SPEC_WAN_FW"
        WAN_TARGET="RETURN"
        WAN_H_TARGET="RETURN"
    fi
    if [ -f /tmp/ss/chnroute.txt ] ; then
        ipset flush ss_spec_dst_sh
        grep -v '^#' /tmp/ss/chnroute.txt | sort -u | grep -v "^$" | sed -e "s/^/-A ss_spec_dst_sh &/g" | ipset -R -!
    fi
fi

if [ "$ss_mode_x" = "1" ] ; then
# 1 为 gfwlist 规则
    ACB_TARGET="SS_SPEC_WAN_KAC"
    GFWLIST_TARGET="SS_SPEC_WAN_FW"
    WAN_H_TARGET="RETURN"
fi

if [ "$ss_mode_x" = "2" ] ; then
# 2 为 全局 规则
    #LAN_TARGET="SS_SPEC_WAN_FW"
    WAN_H_TARGET="SS_SPEC_WAN_FW"
    SH_H_TARGET="SS_SPEC_WAN_FW"
fi

# /etc/storage/shadowsocks_config_script.sh
# 内网(LAN)IP设定行为设置, 格式如 b,192.168.1.23, 多个值使用空格隔开
#   使用 b/g/n 前缀定义主机行为模式, 使用英文逗号与主机 IP 分隔
#   b: 绕过, 此前缀的主机IP 不使用 SS
#   g: 全局, 此前缀的主机IP 使用 全局代理 走 SS
#   n: 常规, 此前缀的主机IP 使用 SS配置工作模式 走 SS
#   1: 大陆白名单, 此前缀的主机IP 使用 大陆白名单模式 走 SS
#   2: gfwlist, 此前缀的主机IP 使用 gfwlist模式 走 SS
logger -t "【SS】" "设置内网(LAN)访问控制"
grep -v '^#' /etc/storage/shadowsocks_ss_spec_lan.sh | sort -u | grep -v "^$" | sed s/！/!/g > /tmp/ss_spec_lan.txt
while read line
do
for host in $line; do
    case "${host:0:1}" in
        n|N)
            ipset add ss_spec_src_ac ${host:2}
            ;;
        b|B)
            ipset add ss_spec_src_bp ${host:2}
            ;;
        g|G)
            ipset add ss_spec_src_fw ${host:2}
            ;;
        1|1)
            ipset add ss_spec_src_chn ${host:2}
            ;;
        2|2)
            ipset add ss_spec_src_gfw ${host:2}
            ;;
    esac
done
done < /tmp/ss_spec_lan.txt

# 加载 nat 规则
echo "ss_multiport:$ss_multiport"
EXT_ARGS_TCP="$ss_multiport"
include_ac_rules nat
get_wifidognx
gen_prerouting_rules nat $wifidognx
dns_redirect
iptables -t nat -A SS_SPEC_WAN_KCPTUN -p tcp -j REDIRECT --to-port 1091
iptables -t nat -A SS_SPEC_WAN_FW -p tcp -j REDIRECT --to-port $ss_working_port
wifidognx=""
wifidogn=`iptables -t nat -L OUTPUT --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
if [ -z "$wifidogn" ] ; then
    wifidogn=`iptables -t nat -L OUTPUT --line-number | grep vserver | awk '{print $1}' | awk 'END{print $1}'`  ## vserver
    if [ -z "$wifidogn" ] ; then
        wifidognx=1
    else
        wifidognx=`expr $wifidogn + 1`
    fi
else
    wifidognx=`expr $wifidogn + 1`
fi
iptables -t nat -N SS_SPEC_WAN_DG
iptables -t nat -A SS_SPEC_WAN_DG -m set --match-set ss_spec_dst_sp dst -j RETURN
iptables -t nat -A SS_SPEC_WAN_DG -p tcp $EXT_ARGS_TCP -j SS_SPEC_WAN_AC
iptables -t nat -I OUTPUT $wifidognx -p tcp -j SS_SPEC_WAN_DG
# 加载 mangle 规则
echo "ss_upd_rules:$ss_upd_rules"
EXT_ARGS_UDP="$ss_upd_rules"
if [ "$ss_udp_enable" == 1 ] ; then
    ip rule add fwmark 1 lookup 100
    ip route add local default dev lo table 100
    include_ac_rules mangle
    get_wifidognx_mangle
    gen_prerouting_rules mangle $wifidognx
    iptables -t mangle -A SS_SPEC_WAN_KCPTUN -p udp --dport 53  -m set ! --match-set ss_spec_dst_fw dst -j RETURN
    iptables -t mangle -A SS_SPEC_WAN_KCPTUN -p udp -j TPROXY --on-port 1091 --tproxy-mark 0x01/0x01
    iptables -t mangle -A SS_SPEC_WAN_FW -p udp --dport 53  -m set ! --match-set ss_spec_dst_fw dst -j RETURN
    iptables -t mangle -A SS_SPEC_WAN_FW -p udp -j TPROXY --on-port $ss_working_port --tproxy-mark 0x01/0x01
fi
# 加载 pdnsd 规则
logger -t "【SS】" "pdnsd 模式:$ss_pdnsd_wo_redir, 0走代理 1直连"
echo "ss_pdnsd_wo_redir:$ss_pdnsd_wo_redir"
if [ "$ss_pdnsd_wo_redir" == 0 ] ; then
    # pdnsd 0走代理
    iptables -t nat -I OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j REDIRECT --to-port $ss_working_port
    iptables -t nat -I OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j REDIRECT --to-port $ss_working_port
else
    # pdnsd 1直连
    iptables -t nat -I OUTPUT -p tcp -d 8.8.8.8,8.8.4.4 --dport 53 -j RETURN
    iptables -t nat -I OUTPUT -p tcp -d 208.67.222.222,208.67.220.220 --dport 443 -j RETURN
fi


# 外网(WAN)访问控制
    logger -t "【SS】" "外网(WAN)访问控制，设置 WAN IP 转发或忽略代理中转"
    grep -v '^#' /etc/storage/shadowsocks_ss_spec_wan.sh | sort -u | grep -v "^$" | sed s/！/!/g > /tmp/ss_spec_wan.txt
    rm -f /tmp/ss/wantoss.list
    rm -f /tmp/ss/wannoss.list
    while read line
    do
    del_line=`echo $line |grep "WAN@"`
    if [ ! -z "$del_line" ] ; then
        del_line=`echo $del_line | sed s/WAN@//g` #WAN@开头的 域名 使用 代理中转
        /usr/bin/resolveip -4 -t 10 $del_line | grep -v :  > /tmp/ss/tmp.list
        [ ! -s /tmp/ss/tmp.list ] && nslookup $del_line | tail -n +3 | grep "Address" | awk '{print $3}'| grep -v ":"  >> /tmp/ss/wantoss.list
        [ -s /tmp/ss/tmp.list ] && cat /tmp/ss/tmp.list >> /tmp/ss/wantoss.list && echo "" > /tmp/ss/tmp.list
    fi
    add_line=`echo $line |grep "WAN!"`
    if [ ! -z "$add_line" ] ; then
        add_line=`echo $add_line | sed s/WAN!//g` #WAN!开头的 域名 忽略 代理中转
        /usr/bin/resolveip -4 -t 10 $add_line | grep -v :  > /tmp/ss/tmp.list
        [ ! -s /tmp/ss/tmp.list ] && nslookup $add_line | tail -n +3 | grep "Address" | awk '{print $3}'| grep -v ":"  >> /tmp/ss/wannoss.list
        [ -s /tmp/ss/tmp.list ] && cat /tmp/ss/tmp.list >> /tmp/ss/wannoss.list && echo "" > /tmp/ss/tmp.list
    fi
        net_line=`echo $line |grep "WAN+"`
    if [ ! -z "$net_line" ] ; then
        net_line=`echo $net_line | sed s/WAN+//g` #WAN+开头的 IP网段/掩码 使用 代理
        echo $net_line  >> /tmp/ss/wantoss.list
    fi
        net_line=`echo $line |grep "WAN-"`
    if [ ! -z "$net_line" ] ; then
        net_line=`echo $net_line | sed s/WAN-//g` #WAN-开头的 IP网段/掩码 忽略 代理
        echo $net_line  >> /tmp/ss/wannoss.list
    fi
    done < /tmp/ss_spec_wan.txt
    if [ -s "/tmp/ss/wannoss.list" ] ; then
        sed -e "s/^/-A ss_spec_dst_bp &/g" -e "1 i\-N ss_spec_dst_bp hash:net " /tmp/ss/wannoss.list | ipset -R -!
    fi
    if [ -s "/tmp/ss/wantoss.list" ] ; then
        sed -e "s/^/-A ss_spec_dst_fw &/g" -e "1 i\-N ss_spec_dst_fw hash:net " /tmp/ss/wantoss.list | ipset -R -!
    fi
    logger -t "【SS】" "完成 SS 转发规则设置"
    sleep 1
    gen_include &
}

dns_redirect() {
    # 强制使用路由的DNS
    lan_ipaddr=`nvram get lan_ipaddr`
    if [ "$ss_DNS_Redirect" == "1" ] && [ ! -z "$lan_ipaddr" ] ; then
    iptables-restore -n <<-EOF
*nat
:SS_SPEC_DNS_LAN_DG - [0:0]
:SS_SPEC_DNS_LAN_AC - [0:0]
:SS_SPEC_DNS_WAN_AC - [0:0]
:SS_SPEC_DNS_WAN_FW - [0:0]
-A SS_SPEC_DNS_LAN_DG -m set --match-set ss_spec_dst_sp dst -j RETURN
-A SS_SPEC_DNS_LAN_DG -j SS_SPEC_DNS_LAN_AC
-A SS_SPEC_DNS_LAN_AC -m set --match-set ss_spec_src_bp src -j RETURN
-A SS_SPEC_DNS_LAN_AC -m set --match-set ss_spec_src_fw src -j SS_SPEC_DNS_WAN_FW
-A SS_SPEC_DNS_LAN_AC -m set --match-set ss_spec_src_ac src -j SS_SPEC_DNS_WAN_AC
-A SS_SPEC_DNS_LAN_AC -m set --match-set ss_spec_src_gfw src -j SS_SPEC_DNS_WAN_AC
-A SS_SPEC_DNS_LAN_AC -m set --match-set ss_spec_src_chn src -j SS_SPEC_DNS_WAN_AC
-A SS_SPEC_DNS_LAN_AC -j ${DNS_LAN_TARGET:=SS_SPEC_DNS_WAN_AC}
-A SS_SPEC_DNS_WAN_AC -m set --match-set ss_spec_dst_sp dst -j RETURN
-A SS_SPEC_DNS_WAN_AC -j SS_SPEC_DNS_WAN_FW
COMMIT
EOF
        logger -t "【SS】" "udp53端口（DNS）地址重定向为 $ss_DNS_Redirect_IP 强制使用重定向地址的DNS"
        iptables -t nat -A PREROUTING -s $lan_ipaddr/24 -p udp --dport 53 -j SS_SPEC_DNS_LAN_DG
        iptables -t nat -A SS_SPEC_DNS_WAN_FW -j DNAT --to $ss_DNS_Redirect_IP
    fi

}

gen_special_purpose_ip() {
#处理肯定不走通道的目标网段
lan_ipaddr=`nvram get lan_ipaddr`
kcptun_enable=`nvram get kcptun_enable`
kcptun_enable=${kcptun_enable:-"0"}
kcptun_server=`nvram get kcptun_server`
if [ "$kcptun_enable" != "0" ] && [ -z "$kcptun_server" ] ; then
resolveip=`/usr/bin/resolveip -4 -t 10 $kcptun_server | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`nslookup $kcptun_server | awk 'NR==5{print $3}'` 
kcptun_server=$resolveip
fi
[ "$kcptun_enable" = "0" ] && kcptun_server=""
if [ "$ss_enable" != "0" ] && [ -z "$ss_s1_ip" ] ; then
resolveip=`/usr/bin/resolveip -4 -t 10 $ss_server1 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`nslookup $ss_server1 | awk 'NR==5{print $3}'` 
ss_s1_ip=$resolveip
resolveip=`/usr/bin/resolveip -4 -t 10 $ss_server2 | grep -v : | sed -n '1p'`
[ -z "$resolveip" ] && resolveip=`nslookup $ss_server2 | awk 'NR==5{print $3}'` 
ss_s2_ip=$resolveip
fi
    cat <<-EOF | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}"
0.0.0.0/8
10.0.0.0/8
100.64.0.0/10
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.0.0.0/24
192.0.2.0/24
192.25.61.0/24
192.31.196.0/24
192.52.193.0/24
192.88.99.0/24
192.168.0.0/16
192.175.48.0/24
198.18.0.0/15
198.51.100.0/24
203.0.113.0/24
224.0.0.0/4
240.0.0.0/4
255.255.255.255
100.100.100.100
188.188.188.188
$ss_s1_ip
$ss_s2_ip
$kcptun_server
EOF
}
include_ac_rules() {
    iptables-restore -n <<-EOF
*$1
:SS_SPEC_LAN_DG - [0:0]
:SS_SPEC_LAN_AC - [0:0]
:SS_SPEC_WAN_AC - [0:0]
:SS_SPEC_WAN_ACB - [0:0]
:SS_SPEC_WAN_FW - [0:0]
:SS_SPEC_WAN_KAC - [0:0]
:SS_SPEC_WAN_KCPTUN - [0:0]
-A SS_SPEC_LAN_DG -m set --match-set ss_spec_dst_sp dst -j RETURN
-A SS_SPEC_LAN_DG -j SS_SPEC_LAN_AC
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_bp src -j RETURN
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_fw src -j SS_SPEC_WAN_FW
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_ac src -j SS_SPEC_WAN_AC
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_gfw src -j SS_SPEC_WAN_AC
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_gfw src -j RETURN
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_chn src -j SS_SPEC_WAN_AC
-A SS_SPEC_LAN_AC -m set --match-set ss_spec_src_chn src -j RETURN
-A SS_SPEC_LAN_AC -j ${LAN_TARGET:=SS_SPEC_WAN_AC}
-A SS_SPEC_WAN_AC -m set --match-set ss_spec_dst_sp dst -j RETURN
-A SS_SPEC_WAN_AC -m set --match-set ss_spec_dst_fw dst -j SS_SPEC_WAN_FW
-A SS_SPEC_WAN_AC -m set --match-set ss_spec_dst_bp dst -j RETURN
-A SS_SPEC_WAN_AC -m set --match-set ss_spec_src_gfw src -m set --match-set gfwlist dst -j ${GFWLIST_TARGET:=SS_SPEC_WAN_FW}
-A SS_SPEC_WAN_AC -m set --match-set ss_spec_src_gfw src -m set --match-set cflist dst -j ${GFWLIST_TARGET:=SS_SPEC_WAN_FW}
-A SS_SPEC_WAN_AC -m set --match-set ss_spec_src_gfw src -j RETURN
-A SS_SPEC_WAN_AC -m set --match-set ss_spec_src_chn src -m set --match-set ss_spec_dst_sh dst -j ${SH_TARGET:=RETURN}
-A SS_SPEC_WAN_AC -m set --match-set ss_spec_src_chn src -j ${WAN_TARGET:=SS_SPEC_WAN_FW}
-A SS_SPEC_WAN_AC -j ${ACB_TARGET:=SS_SPEC_WAN_ACB}
-A SS_SPEC_WAN_KAC -m set --match-set gfwlist dst -j ${GFWLIST_TARGET:=SS_SPEC_WAN_FW}
-A SS_SPEC_WAN_KAC -m set --match-set cflist dst -j ${GFWLIST_TARGET:=SS_SPEC_WAN_FW}
-A SS_SPEC_WAN_KAC -j SS_SPEC_WAN_ACB
-A SS_SPEC_WAN_ACB -m set --match-set ss_spec_dst_sh dst -j ${SH_H_TARGET:=RETURN}
-A SS_SPEC_WAN_ACB -j ${WAN_H_TARGET:=SS_SPEC_WAN_FW}
COMMIT
EOF
}

get_wifidognx() {
    wifidognx=""
    wifidogn=`iptables -t nat -L PREROUTING --line-number | grep AD_BYBY | awk '{print $1}' | awk 'END{print $1}'`  ## AD_BYBY
    if [ -z "$wifidogn" ] ; then
        wifidogn=`iptables -t nat -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
        if [ -z "$wifidogn" ] ; then
            wifidogn=`iptables -t nat -L PREROUTING --line-number | grep vserver | awk '{print $1}' | awk 'END{print $1}'`  ## vserver
            if [ -z "$wifidogn" ] ; then
                wifidognx=1
            else
                wifidognx=`expr $wifidogn + 1`
            fi
        else
            wifidognx=`expr $wifidogn + 1`
        fi
    else
        wifidognx=`expr $wifidogn + 1`
    fi
    wifidognx=$wifidognx
}

get_wifidognx_mangle() {
    wifidognx=""
    wifidogn=`iptables -t mangle -L PREROUTING --line-number | grep Outgoing | awk '{print $1}' | awk 'END{print $1}'`  ## Outgoing
        if [ -z "$wifidogn" ] ; then
            wifidogn=`iptables -t mangle -L PREROUTING --line-number | grep UP | awk '{print $1}' | awk 'END{print $1}'`  ## UP
            if [ -z "$wifidogn" ] ; then
                wifidognx=1
            else
                wifidognx=`expr $wifidogn + 1`
            fi
        else
            wifidognx=`expr $wifidogn + 1`
        fi
    wifidognx=$wifidognx
}

gen_prerouting_rules() {
    local protocol=$([ "$1" = "mangle" ] && echo udp $EXT_ARGS_UDP || echo tcp $EXT_ARGS_TCP )
    iptables -t $1 -I PREROUTING $2 -p $protocol -j SS_SPEC_LAN_DG
}

gen_include() {
[ -n "$FWI" ] || return 0
cat <<-CAT >>$FWI
iptables-restore -n <<-EOF
$(iptables-save | grep -E "$TAG|^\*|^COMMIT" |sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOF
CAT
return $?
}

#获取所有被墙domain
#1 获取gfwlist 被墙列表
update_gfwlist()
{
echo "gfwlist updating"
if [ -f /tmp/cron_ss.lock ] ; then
      logger -t "【SS】" "Other SS GFWList updating...."
else
    touch /tmp/cron_ss.lock
    mkdir -p /tmp/ss/dnsmasq.d
    logger -t "【SS】" "正在处理 gfwlist 列表，此时 SS 未能使用，请稍候...."
    sed -Ei '/conf-dir=/d' /etc/storage/dnsmasq/dnsmasq.conf
    [ ! -z "$confdir" ] && echo "conf-dir=$confdir" >> /etc/storage/dnsmasq/dnsmasq.conf
    sleep 1
    echo "从代理获取list"
    sed -Ei '/github|ipip.net/d' /etc/storage/dnsmasq/dnsmasq.conf
    cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\_CONF
ipset=/githubusercontent.com/gfwlist
server=/githubusercontent.com/127.0.0.1#8053
ipset=/github.io/gfwlist
#ipset=/ipip.net/gfwlist
server=/github.io/127.0.0.1#8053
_CONF
    restart_dhcpd ; sleep 1
    
    if [ "$ss_3p_enable" = "1" ] ; then
        if [ "$ss_3p_gfwlist" = "1" ] ; then
            logger -t "【SS】" "正在获取官方 gfwlist...."
            wget --continue --no-check-certificate  --quiet  -t3 -O  /tmp/ss/gfwlist.b64 https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt
            base64 -d  /tmp/ss/gfwlist.b64 > /tmp/ss/gfwlist.txt
            cat /tmp/ss/gfwlist.txt | sort -u |
                    sed '/^$\|@@/d'|
                    sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' | 
                    sed '/\*/d; /apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /qq\.com/d' |
                    sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' |
                    grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | sed 's#^\.\+##'  | sort -u > /tmp/ss/gfwlist_domain.txt
        fi
        if [ "$ss_3p_kool" = "1" ] ; then
            #2 获取koolshare.github.io/maintain_files/gfwlist.conf
            logger -t "【SS】" "正在获取 koolshare 列表...."
            wget --continue --no-check-certificate  --quiet -t3 http://koolshare.github.io/maintain_files/gfwlist.conf -O- | sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' > /tmp/ss/gfwdomain_1.txt
            wget --continue --no-check-certificate  --quiet -t3 https://raw.githubusercontent.com/koolshare/koolshare.github.io/master/maintain_files/gfwlist.conf -O- | sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' > /tmp/ss/gfwdomain_2.txt
        fi
    fi

    #合并多个域名列表（自定义域名，GFWLIST，小宝的两个列表）
    logger -t "【SS】" "根据选项不同，分别会合并固件自带、gfwlist官方、koolshare以及自定义列表...."
    touch /etc/storage/shadowsocks_mydomain_script.sh
    cat /etc/storage/shadowsocks_mydomain_script.sh | sed '/^$\|#/d' | sed "s/http://g" | sed "s/https://g" | sed "s/\///g" | sort -u > /tmp/ss/gfwdomain_0.txt
    cat /etc/storage/basedomain.txt /tmp/ss/gfwdomain_0.txt /tmp/ss/gfwdomain_1.txt /tmp/ss/gfwdomain_2.txt /tmp/ss/gfwlist_domain.txt | 
        sort -u > /tmp/ss/gfwall_domain.txt

    #删除忽略的域名
    while read line
    do
    del_line=`echo $line |grep "WAN@"`
    if [ ! -z "$del_line" ] ; then
        del_line=`echo $del_line | sed s/WAN@//g` #WAN@开头的 域名 使用 代理中转
        echo "$del_line" >> /tmp/ss/gfwall_domain.txt
    fi
    add_line=`echo $line |grep "WAN!"`
    if [ ! -z "$add_line" ] ; then
        add_line=`echo $add_line | sed s/WAN!//g` #WAN!开头的 域名 忽略 代理中转
        sed -Ei "/$add_line/d" /tmp/ss/gfwall_domain.txt
    fi
    done < /tmp/ss_spec_wan.txt

    cat /tmp/ss/gfwall_domain.txt | sort -u > /tmp/ss/all_domain.txt

    # 到此全域名列表都已经获取完毕，开始构造dnsmasq.conf
    rm -f /tmp/ss/gfw*.txt
    rm -f $confdir/r.gfwlist.conf


#killall -9 sh_adblock_hosts.sh
#/tmp/sh_adblock_hosts.sh $confdir &

    #用awk代替文件逐行读写，速度快3倍以上。
    awk '{printf("server=/%s/127.0.0.1#8053\nipset=/%s/gfwlist\n", $1, $1 )}' /tmp/ss/all_domain.txt > $confdir/r.gfwlist.conf

    #订阅处理
    #此处订阅有3种内容, 需要在UI里面增加订阅3个列表的选项，对应 ss_sub1,2,3三个值。
    #1. 海外加速，用于直连速度慢的网站  https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/list.txt
    #2. 域名解释加速，用于有亚洲CDN，但是DNS不能正确识别中国IP返回美国服务器IP的情况，通常用于XBOX Live 联网  https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/dnsonly.txt 
    #3. 需要忽略的域名处理，用于国内有CDN的节点 https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/passby.txt
    #处理订阅了加速列表的域名
if [ "$ss_3p_enable" = "1" ] ; then
    if [ "$ss_sub1" = "1" ] ; then
        logger -t "【SS】" "处理订阅列表1...."
        wget --continue --no-check-certificate  --quiet -t3 https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/list.txt -O- |
            sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' |
            awk '{printf("server=/%s/127.0.0.1#8053\nipset=/%s/gfwlist\n", $1, $1 )}'  > $confdir/r.sub.conf
    fi
    #处理只做dns解释的域名
    if [ "$ss_sub2" = "1" ] ; then
        logger -t "【SS】" "处理订阅列表2...."
        wget --continue --no-check-certificate  --quiet  -t3 https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/dnsonly.txt -O- |
            sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' |
            awk '{printf("server=/%s/127.0.0.1#8053\n", $1 )}'  >> $confdir/r.sub.conf
    fi
    #处理需要排除的域名解释
    if [ "$ss_sub3" = "1" ] ; then
        logger -t "【SS】" "处理订阅列表3...."
        DNS=`nvram get wan0_dns |cut -d ' ' -f1`
        [ -z "$DNS" ] && DNS="114.114.114.114"
    awk_cmd="awk '{printf(\"server=/%s/$DNS\\n\", \$1 )}'  >> $confdir/r.sub.conf"
    #echo $awk_cmd
        wget --continue --no-check-certificate  --quiet  -t3 https://coding.net/u/bigandy/p/DogcomBooster/git/raw/master/passby.txt -O- |
            sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' |
            eval $awk_cmd
            #awk '{printf("server=/%s/114.114.114.114\n", $1 )}'  >> $confdir/r.sub.conf
    fi
fi
    #订阅处理完成
    #删除ipset=，留下server=
    # if [ "$ss_mode_x" = "0" ] ; then
        # if [ "$kcptun2_enable" ! = "1" ] ; then
            # logger -t "【SS】" "模式一：DNSList update 重启 dnsmasq 更新列表"
            # cd $confdir
            # ls -R |awk '{print i$0}' i=`pwd`'/' | grep -v ':' > /tmp/tmp_dnsmasqd
            # while read line
            # do
                # logger -t "【SS】" "删除【ipset=】DNSList: $line"
                # sed -Ei '/ipset=/d' $line
            # done < /tmp/tmp_dnsmasqd
        # fi
        # gfwlist3=`nvram get gfwlist3`
        # Update="DNSlist"
    # else
        # gfwlist3=""
        # Update="Update: "$(date)"  GFWlist"
    # fi
    gfwlist3=`nvram get gfwlist3`
    Update="GFWlist"
    lines=`cat $confdir/* | wc -l`
    logger -t "【SS】" "规则 $lines 行  $gfwlist3"
    logger -t "【SS】" "所有规则处理完毕，SS即将开始工作"
    nvram set gfwlist3="$Update 规则 $lines 行  $gfwlist3"
    echo `nvram get gfwlist3`
    rm -f /tmp/cron_ss.lock
    # [ "$ss_mode_x" = "1" ] && adbyby_cflist
    # [ "$ss_mode_x" = "0" ] && [ "$kcptun2_enable" = "1" ] && adbyby_cflist
    adbyby_cflist
    logger -t "【SS】" "GFWList update 重启 dnsmasq 更新列表"
    ipset flush gfwlist
    restart_dhcpd ; sleep 1
fi

}


update_chnroutes()
{
echo "chnroutes updating"
if [ -f /tmp/cron_ss.lock ] ; then
    logger -t "【SS】" "Other SS chnroutes updating...."
else


#killall -9 sh_adblock_hosts.sh
#/tmp/sh_adblock_hosts.sh $confdir &
# if [ "$ss_mode_x" != "2" ] ; then
    touch /tmp/cron_ss.lock
    mkdir /tmp/ss -p
    # 启动时先用高春辉的这个列表，更新交给守护进程去做。
    # 完整apnic 列表更新指令，不需要去重，ipset -! 会自动去重。此指令暂时屏蔽，这个列表获取10~90秒不等，有时候甚至卡住不动。
    # wget --continue --no-check-certificate -q -O- 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' | sed -e "s/^/-A nogfwnet &/g" | ipset -R -!
    logger -t "【SS】" "下载 chnroutes"
    ip_list="ss_spec_dst_sh"
        echo $ip_list
        # wget --continue --no-check-certificate -O- 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' | awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > /tmp/ss/chnroute.txt
        # echo ""  >> /tmp/ss/chnroute.txt
        wget --continue --no-check-certificate  -t2 -q -O- https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt > /tmp/ss/chnroute.txt
        echo ""  >> /tmp/ss/chnroute.txt
        wget --continue --no-check-certificate  -t2 -q -O- https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/chnroute.txt >> /tmp/ss/chnroute.txt
        ipset flush ss_spec_dst_sh
        grep -v '^#' /tmp/ss/chnroute.txt | sort -u | grep -v "^$" | sed -e "s/^/-A $ip_list &/g" | ipset -R -!
    
    nvram set gfwlist3="chnroutes规则`ipset list $ip_list -t | awk -F: '/Number/{print $2}'` 行 Update: $(date)"
    echo `nvram get gfwlist3`
# fi
    if [ "$ss_mode_x" = "2" ] || [ "$ss_pdnsd_all" = "1" ] ; then
        # 2 为全局,模式3全局代理。加速国内dns访问
        logger -t "【SS】" "加速国内 dns 访问，模式:$ss_mode_x, pdnsd_all:$ss_pdnsd_all, 下载 accelerated-domains.china.conf"
        DNS_china=`nvram get wan0_dns |cut -d ' ' -f1`
        [ -z "$DNS_china" ] && DNS_china="114.114.114.114"
        wget --continue --no-check-certificate  --quiet  -t3 https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/accelerated-domains.china.conf -O- |
            sort -u | sed 's/^[[:space:]]*//g; /^$/d; /#/d' |
            sed -e "s|^\(server.*\)/[^/]*$|\1/$DNS_china|" > /tmp/ss/accelerated-domains.china.conf
        sed -Ei '/accelerated-domains/d' /etc/storage/dnsmasq/dnsmasq.conf
        echo "conf-file=/tmp/ss/accelerated-domains.china.conf" >> "/etc/storage/dnsmasq/dnsmasq.conf"
    fi
    logger -t "【SS】" "chnroutes update 重启 dnsmasq 更新列表"
    restart_dhcpd ; sleep 1
    rm -f /tmp/cron_ss.lock

fi
}


#================华丽的分割线====================================



adbyby_cflist()
{
    logger -t dnsmasq "restart adbyby_cflist"
    ipsets=`nvram get adbyby_mode_x`
if [ "$ipsets" == 1 ] ; then
    if [ -s "/tmp/7620adm/adm" ] ; then
        port=$(iptables -t nat -L | grep 'ports 18309' | wc -l)
        PIDS=$(ps | grep "/tmp/7620adm/adm" | grep -v "grep" | wc -l)
        if [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
            /tmp/sh_adm18309.sh D &
            sleep 1
            killall -15 adm
            killall -9 adm
            /tmp/7620adm/adm >/dev/null 2>&1 &
            sleep 10
            /tmp/sh_adm18309.sh A &
        fi
    fi
    if [ -s "/tmp/bin/adbyby" ] ; then
        sed -Ei '/ipset=/d' /tmp/bin/adhook.ini
        echo ipset=1 >> /tmp/bin/adhook.ini
        sed -Ei '/sh_adb8118.sh|restart_dhcpd/d' /tmp/bin/adbybyfirst.sh /tmp/bin/adbybyupdate.sh
        echo /tmp/sh_adb8118.sh C $confdir "/r.gfwlist.conf" "gfwlist" >> /tmp/bin/adbybyfirst.sh
        echo /tmp/sh_adb8118.sh C $confdir "/r.gfwlist.conf" "gfwlist" >> /tmp/bin/adbybyupdate.sh
        port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
        PIDS=$(ps | grep "/tmp/bin/adbyby" | grep -v "grep" | grep -v "adbybyupdate.sh" | grep -v "adbybyfirst.sh" | wc -l)
        if [ "$port" -ge 1 ] || [ "$PIDS" != 0 ] ; then
            /tmp/sh_adb8118.sh D &
            sleep 1
            killall -15 adbyby
            killall -9 adbyby
            /tmp/bin/adbyby >/dev/null 2>&1 &
            sleep 10
            /tmp/sh_adb8118.sh A &
        fi
    else
        sed -Ei '/ipset=/d' /tmp/bin/adhook.ini
        echo ipset=0 >> /tmp/bin/adhook.ini
        sed -Ei '/sh_adb8118.sh|restart_dhcpd/d' /tmp/bin/adbybyfirst.sh /tmp/bin/adbybyupdate.sh
    fi
fi
}

dnsmasq_reconf()
{
    #防火墙转发规则加载
    # for dnsmasq 
    sed -Ei '/no-resolv|server=|server=127.0.0.1|server=208.67.222.222|dns-forward-max=1000|min-cache-ttl=1800|github/d' /etc/storage/dnsmasq/dnsmasq.conf
if [ "$ss_mode_x" = "2" ] || [ "$ss_pdnsd_all" = "1" ] ; then 
#   #方案三
    cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\EOF
no-resolv
server=127.0.0.1#8053
dns-forward-max=1000
min-cache-ttl=1800
EOF
fi
#启动PDNSD防止域名污染
start_pdnsd
sed -Ei '/github/d' /etc/storage/dnsmasq/dnsmasq.conf
cat >> "/etc/storage/dnsmasq/dnsmasq.conf" <<-\_CONF
server=/githubusercontent.com/127.0.0.1#8053
server=/github.io/127.0.0.1#8053
_CONF
restart_dhcpd ; sleep 1
}


start_SS()
{
    restart_dhcpd
    logger -t "【SS】" "启动 SS"
    stop_SS
    nvram set ss_internet="2"
    optssredir="0"
if [ "$ss_mode_x" != "3" ] ; then
    hash ss-redir 2>/dev/null || optssredir="1"
else
    hash ss-local 2>/dev/null || optssredir="1"
fi
if [ "$optssredir" = "1" ] ; then
    # 找不到ss-redir，安装opt
    if [ ! -d "/opt/bin" ] ; then
    upanPath=""
    ss_opt_x=`nvram get ss_opt_x`
    [ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
    [ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    [ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
    if [ ! -z $upanPath ] ; then
        mkdir -p /media/$upanPath/opt
        mount -o bind /media/$upanPath/opt /opt
        ln -sf /media/$upanPath /tmp/AiDisk_00
    else
        mkdir -p /tmp/AiDisk_00/opt
        mount -o bind /tmp/AiDisk_00/opt /opt
    fi
    mkdir -p /opt/bin
    fi
    optssredir="0"
    if [ "$ss_mode_x" != "3" ] ; then
        hash ss-redir 2>/dev/null || optssredir="1"
    else
        hash ss-local 2>/dev/null || optssredir="1"
    fi
    if [ "$optssredir" = "1" ] ; then
        if [ "$ss_mode_x" != "3" ] ; then
            optssredir="0"
            hash ss-redir 2>/dev/null || optssredir="1"
            if [ "$optssredir" = "1" ] ; then
                logger -t "【SS】" "找不到 ss-redir. opt下载程序"
                /tmp/sh_download.sh "/opt/bin/ss-redir" "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/ss-redir"
                chmod 777 "/opt/bin/ss-redir"
            fi
            hash ss-redir 2>/dev/null || { logger -t "【SS】" "找不到 ss-redir, 请检查系统"; nvram set ss_enable=0 && nvram set ss_status=0 && nvram commit; exit 1; }
        else
            optssredir="0"
            hash ss-local 2>/dev/null || optssredir="1"
            if [ "$optssredir" = "1" ] ; then
                logger -t "【SS】" "找不到 ss-local. opt 下载程序"
                /tmp/sh_download.sh "/opt/bin/ss-local" "https://code.aliyun.com/hiboyhiboy/padavan-opt/raw/master/ss-local"
                chmod 777 "/opt/bin/ss-local"
            fi
            hash ss-local 2>/dev/null || { logger -t "【SS】" "找不到 ss-local, 请检查系统"; nvram set ss_enable=0 && nvram set ss_status=0 && nvram commit; exit 1; }
        fi
    fi
fi
check_ssr
echo "Debug: $DNS_Server"
    rm -f /tmp/cron_ss.lock
    logger -t "【SS】" "###############启动程序###############"
    if [ "$ss_mode_x" = "3" ] ; then
        start_ss_redir
    logger -t "【ss-local】" "启动. 可以配合 Proxifier、chrome(switchysharp、SwitchyOmega) 代理插件使用."
    logger -t "【SS】" "shadowsocks 进程守护启动"
    /tmp/sh_ssmon.sh &
    exit 0
    fi
    dnsmasq_reconf
    start_ss_redir
    start_ss_rules
    # [ "$ss_mode_x" != "1" ] && update_chnroutes
    # [ "$ss_mode_x" != "2" ] && [ "$ss_pdnsd_all" != "1" ] && update_gfwlist
    update_chnroutes
    update_gfwlist
    #检查网络
    logger -t "【SS】" "SS 检查网络连接"
    sleep 1
    resolveip=`/usr/bin/resolveip -4 -t 10 "www.baidu.com" | grep -v : | sed -n '1p'`
    [ -z "$resolveip" ] && resolveip=`nslookup baidu.com | tail -n +3 | grep "Address" | awk '{print $3}'| grep -v ":" | tail -n 1`
if [ -z "$resolveip" ] ; then 
    logger -t "【SS】" "连 baidu.com 的域名都解析不了, 你的网络能用？？"
    #nvram set ss_enable=0
    nvram set ss_status=00
    #nvram commit
    logger -t "【SS】" "SS 网络连接有问题, 请更新 opt 文件夹、检查 U盘 文件和 SS 设置"
    stop_SS
    /etc/storage/crontabs_script.sh &
    exit 0
fi
    /etc/storage/ez_buttons_script.sh 3 &
    logger -t "【SS】" "SS 启动成功"
    logger -t "【SS】" "启动后若发现一些网站打不开, 估计是 DNS 被污染了. 解决 DNS 被污染方法："
    logger -t "【SS】" "①路由 SS 设置选择其他 DNS 服务模式；"
    logger -t "【SS】" "②电脑设置 DNS 自动获取路由 ip。检查 hosts 是否有错误规则。"
    logger -t "【SS】" "③电脑运行 cmd 输入【ipconfig /flushdns】, 清理浏览器缓存。"
    logger -t "【SS】" "shadowsocks 进程守护启动"
    nvram set ss_internet="1"
    /tmp/sh_ssmon.sh &
}





stop_SS()
{
ss-rules -f
    nvram set ss_internet="0"
    nvram set ss_working_port="1090" #恢复主服务器端口
    ss_working_port=`nvram get ss_working_port`
    sed -Ei '/no-resolv|server=|dns-forward-max=1000|min-cache-ttl=1800|accelerated-domains|github|ipip.net/d' /etc/storage/dnsmasq/dnsmasq.conf
    restart_dhcpd
    clean_ss_rules
    eval $(ps  | grep "/tmp/sh_ssmon.sh" | grep -v grep | awk '{print "kill "$1}')
    killall -9 sh_ssmon.sh &
    [ -n "`pidof ss-redir`" ] &&  killall -9 ss-redir 2>/dev/null
    [ -n "`pidof ss-tunnel`" ] &&  killall -9 ss-tunnel 2>/dev/null
    [ -n "`pidof ss-local`" ] &&  killall -9 ss-local 2>/dev/null
    [ -n "`pidof pdnsd`" ] &&  killall -9 pdnsd 2>/dev/null
    rm -f /var/log/ss-tunnel.lock
    rm -f $confdir/r.gfwlist.conf
    rm -f $confdir/r.sub.conf
    rm -f $confdir/r.adhost.conf
    rm -f $confdir/accelerated-domains.china.conf
    [ -f /opt/etc/init.d/S24chinadns ] && { rm -f /var/log/chinadns.lock; /opt/etc/init.d/S24chinadns stop& }
    [ -f /opt/etc/init.d/S26pdnsd ] && { rm -f /var/log/pdnsd.lock; /opt/etc/init.d/S26pdnsd stop& }
    [ -f /opt/etc/init.d/S27pcap-dnsproxy ] && { rm -f /var/log/pcap-dnsproxy.lock; /opt/etc/init.d/S27pcap-dnsproxy stop& }
    logger -t "【SS】" "ss-redir stop."
    nvram set gfwlist3="ss-redir stop."
    sleep 1
    /etc/storage/ez_buttons_script.sh 3 &
umount /usr/sbin/ss-redir
umount /usr/sbin/ss-local

}

check_setting()
{
A_restart=`nvram get ss_status`
B_restart="$ss_enable$lan_ipaddr$ss_DNS_Redirect$ss_DNS_Redirect_IP$ss_DNS_Redirect$ss_type$ss_check$ss_run_ss_local$ss_s1_local_address$ss_s2_local_address$ss_s1_local_port$ss_s2_local_port$ss_server1$ss_server2$ss_s1_port$ss_s2_port$ss_s1_method$ss_s2_method$ss_s1_key$ss_s2_key$ss_pdnsd_wo_redir$ss_mode_x$ss_multiport$ss_sub4$ss_sub1$ss_sub2$ss_sub3$ss_upd_rules$ss_usage$ss_s2_usage$ss_usage_json$ss_s2_usage_json$ss_tochina_enable$ss_udp_enable$LAN_AC_IP$ss_3p_enable$ss_3p_gfwlist$ss_3p_kool$ss_pdnsd_all$kcptun_server$ss_xbox`nvram get wan0_dns |cut -d ' ' -f1`$(cat /etc/storage/shadowsocks_ss_spec_lan.sh /etc/storage/shadowsocks_ss_spec_wan.sh /etc/storage/shadowsocks_config_script.sh /etc/storage/shadowsocks_mydomain_script.sh | grep -v '^#' | grep -v "^$")"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
    nvram set ss_status=$B_restart
    needed_restart=1
    /etc/storage/ez_buttons_script.sh ping &
else
    needed_restart=0
fi
if [ "$needed_restart" = "0" ] ; then
    if [ -n "`pidof ss-redir`" ] && [ "$ss_enable" = "1" ] && [ "$ss_mode_x" != "3" ] ; then
        port=$(iptables -t nat -L | grep 'SS_SPEC' | wc -l)
        if [ "$port" = 0 ] ; then
            logger -t "【SS】" "检测:找不到 SS_SPEC 转发规则, 重新添加"
            /tmp/ss.sh rules &
        fi
    fi
    exit 0
fi
    [ ${ss_enable:=0} ] && [ "$ss_enable" -eq "0" ] && [ "$needed_restart" = "1" ] && { stop_SS; eval $(ps  | grep "/tmp/ss.sh" | grep -v grep | awk '{print "kill "$1}'); exit 0; }
    # Check if have ss-redir and ss-tunnel
if [ "$ss_mode_x" != "3" ] ; then
    hash ss-redir 2>/dev/null || {  logger -t "【SS】" "找不到, 需要安装 ss-redir"; }
    hash pdnsd 2>/dev/null || { logger -t "【SS】" "找不到, 需要安装 pdnsd"; }
fi
    # Check the ss config from nvram

    [ $ss_server1 ] || logger -t "【SS】" "服务器地址:未填写"
    [ $ss_s1_port ] || logger -t "【SS】" "服务器端口:未填写"
    [ $ss_s1_method ] || logger -t "【SS】" "服务器密码:未填写"
    [ $ss_s1_key ] || logger -t "【SS】" "加密方式:未填写"
    [ $ss_server1 ] && [ $ss_s1_port ] && [ $ss_s1_method ] \
    && [ $ss_s1_key ] ||  { logger -t "【SS】" "SS配置有错误，请到扩展功能检查SS配置页面"; stop_SS; exit 1; }
}

##############################
### ready go
##############################



case "$1" in
start)
        check_setting
        start_SS
        ;;
rules)
        start_ss_rules
        ;;
flush)
        clean_ss_rules
        ;;
update)
        #check_setting
        [ ${ss_enable:=0} ] && [ "$ss_enable" -eq "0" ] && exit 0
        # [ "$ss_mode_x" = "3" ] && exit 0
        #随机延时
        if [ -z "$RANDOM" ] ; then
        SEED=`tr -cd 0-9 </dev/urandom | head -c 8`
        else
        SEED=$RANDOM
        fi
        RND_NUM=`echo $SEED 1 120|awk '{srand($1);printf "%d",rand()*10000%($3-$2)+$2}'`
        # echo $RND_NUM
        logger -t "【SS】" "$RND_NUM 秒后进入处理状态, 请稍候"
        sleep $RND_NUM
        # start_ss_rules
        # [ "$ss_mode_x" != "1" ] && update_chnroutes
        # [ "$ss_mode_x" != "2" ] && [ "$ss_pdnsd_all" != "1" ] && update_gfwlist
        update_chnroutes
        update_gfwlist
        ;;
stop)
        stop_SS
        ;;
repdnsd)
        start_pdnsd
        ;;
help)
        echo "Usage: $0 {start|rules|flush|update|stop}"
        ;;
*)
        check_setting
        start_SS
        exit 0
        ;;
esac





FOF
chmod 777 "/tmp/ss.sh"

cat > "/tmp/sh_adblock_hosts.sh" <<-\EOFH
#!/bin/sh
sleep 20
confdir=$1
ss_sub4=`nvram get ss_sub4`
mkdir /tmp/ss -p
    # adblock hosts广告过滤规则
    #处理最基础的广告域名替换为127.0.0.1 感谢 phrnet 的原帖：http://www.right.com.cn/forum/thread-184121-1-4.html
if [ "$ss_sub4" = "1" ] ; then
    wget --continue --no-check-certificate  --quiet -t3  http://c.nnjsx.cn/GL/dnsmasq/update/adblock/malwaredomainlist.txt -O- | sed 's/127.0.0.1  //g' | dos2unix > /tmp/ss/adhost.txt
    wget --continue --no-check-certificate  --quiet -t3  http://c.nnjsx.cn/GL/dnsmasq/update/adblock/yhosts.txt -O- | sed 's/127.0.0.1 //g' | dos2unix >> /tmp/ss/adhost.txt
    wget --continue --no-check-certificate  --quiet -t3  http://c.nnjsx.cn/GL/dnsmasq/update/adblock/easylistchina.txt -O- | sed 's/address=\///g; s/\/127.0.0.1//g' | dos2unix >> /tmp/ss/adhost.txt
    cat /tmp/ss/adhost.txt | sort -u | sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d; s/^/address=\//; s/$/\/127.0.0.1/' > $confdir/r.adhost.conf
    sed -Ei '/conf-dir=/d' /etc/storage/dnsmasq/dnsmasq.conf
    [ ! -z "$confdir" ] && echo "conf-dir=$confdir" >> /etc/storage/dnsmasq/dnsmasq.conf
else
    rm -f $confdir/r.adhost.conf
fi
    logger -t "【Adblock hosts】" "规则： `sed -n '$=' $confdir/r.adhost.conf | sed s/[[:space:]]//g ` 行"
    nvram set adhosts="ad hosts规则： `sed -n '$=' $confdir/r.adhost.conf | sed s/[[:space:]]//g ` 行"
restart_dhcpd
EOFH
chmod 755 "/tmp/sh_adblock_hosts.sh"

. /etc/storage/script0_script.sh
ln -s "/etc_ro/basedomain.txt" "/etc/storage/basedomain.txt"
ln -sf "/etc/storage/PhMain.ini" "/etc/PhMain.ini"
ln -sf "/etc/storage/init.status" "/etc/init.status"
rm -f "/opt/etc/init.d/S96sh3.sh"
echo "" > /var/log/shadowsocks_watchdog.log
echo "" > /var/log/Pcap_DNSProxy_watchdog.log
echo "" > /var/log/chinadns_watchdog.log
nvram set dnspod_status=000
nvram set cloudxns_status=000
nvram set aliddns_status=000
nvram set adbyby_status=000
nvram set adm_status=000
nvram set ss_status=000
nvram set FastDicks_status=000
nvram set youku_status=000
nvram set ngrok_status=000
nvram set frp_status=000
nvram set serverchan_status=000
nvram set kcptun_status=000
nvram set tinyproxy_status=000
nvram set vpnproxy_status=000
nvram set shellinabox_status=000
nvram set theme_status=000
nvram set mproxy_status=000
nvram set lnmp_status=000
nvram set mentohust_status=000
nvram set ssserver_status=000
nvram set ssrserver_status=000
nvram set wifidog_status=000
nvram set display_status=000
nvram set softether_status=000
nvram set cow_status=000
nvram set meow_status=000
upopt=`nvram get upopt_enable`
http_username=`nvram get http_username`
export PATH='/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin'
export LD_LIBRARY_PATH=/lib:/opt/lib
sed -Ei '/taobao.org/d' /etc/storage/dnsmasq/dnsmasq.servers
echo 'server=/taobao.org/223.5.5.5' >> /etc/storage/dnsmasq/dnsmasq.servers
sed -Ei '/adbyby_host.conf|cflist.conf|AiDisk_00|server=|accelerated-domains|tmp|github/d' /etc/storage/dnsmasq/dnsmasq.conf
rm -f /tmp/ss/dnsmasq.d/*
killall crond
restart_dhcpd ; sleep 1
nvram set ss_internet="0"
/etc/storage/inet_state_script.sh 12 t
/tmp/sh_mento_hust.sh &
baidu='http://passport.baidu.com/passApi/img/small_blank.gif'
/tmp/sh_download.sh /tmp/small_blank.gif $baidu
rb=1
while [ ! -s /tmp/small_blank.gif ];
do
logger -t "【自定义脚本】" "等待联网后开始脚本"
/tmp/sh_download.sh /tmp/small_blank.gif $baidu
rb=`expr $rb + 1`
if [ "$rb" -gt 3 ] ; then
    logger -t "【自定义脚本】" "等待联网超时"
    echo "等待联网超时" > /tmp/small_blank.gif
    #exit
fi
done
/tmp/sh_theme.sh &
rm -f /tmp/small_blank.gif
if [[ $(cat /tmp/apauto.lock) == 1 ]] ; then
    killall sh_apauto.sh
    /tmp/sh_apauto.sh &
fi
adbybys=`nvram get adbyby_enable`
ipsets=`nvram get adbyby_mode_x`
CPUAverages=`nvram get adbyby_CPUAverages`
ssproxys=`nvram get ss_enable`
gfwlists=`nvram get ss_mode_x`
syncys=`nvram get syncys`
xunleis=`nvram get xunleis`
FastDick_enable=`nvram get FastDick_enable`
FastDicks=`nvram get FastDicks`
uid=`nvram get FastDick_uid`
pwd=`nvram get FastDick_pwd`
phddns=`nvram get phddns`
youku_enable=`nvram get youku_enable`
upanPath=""
ss_opt_x=`nvram get ss_opt_x`
[ -z "$ss_opt_x" ] || [ "$ss_opt_x" = "0" ] && nvram set ss_opt_x=1
[ "$ss_opt_x" = "3" ] || [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}'| grep AiCard | sed -n '1p'`
[ -z $upanPath ] && [ "$ss_opt_x" = "1" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
[ "$ss_opt_x" = "4" ] && upanPath=`ls -l /media/ | awk '/^d/ {print $NF}' | grep -v AiCard | sed -n '1p'`
installs=1
[ -z $upanPath ] && installs=2
optinstall=`nvram get optinstall`
optw_enable=`nvram get optw_enable`
if [ "$optw_enable" != "2" ] && [ "$installs" = "1" ] && [ "$optinstall" = "1" ] ; then
    nvram set optw_enable=2
    nvram commit
fi
if [ "$optw_enable" != "0" ] && [ "$installs" = "2" ] && [ "$optinstall" = "1" ] ; then
    nvram set optw_enable=0
    nvram commit
fi
mountpoint -q /opt && installs=1 && logger -t "【opt】" "U盘 已经挂载，自动转换 U盘 安装"
shadowsockssh="/tmp/AiDisk_00/shadowsocks/shadowsocks"
if [ "$FastDick_enable" = "1" ] && [ "$FastDicks" = "1" ] ; then
installs=1
optinstall=1
fi

if [ "$syncys" = "1" ] ; then
installs=1
optinstall=1
fi
. /tmp/sh_upopt.sh
if [ "$optinstall" = "1" ] && [ "$installs" = "1" ] ; then
    logger -t "【opt】" "opt U盘 安装，模式:$installs"
    [ ! -z $upanPath ] && /tmp/sh_installs.sh $ssfile 1
    if [ ! -f "/opt/opti.txt" ] ; then
        logger -t "【opt】" "U盘 安装失败, 请插入 U盘，按要求设置"
        logger -t "【opt】" "U盘 安装失败, 自动转换内存安装"
        [ "$installs" = "1" ] && installs=2
        [ "$FastDicks" = "1" ] && FastDicks=2
    fi
fi
if [ "$optinstall" = "1" ] && [ "$installs" = "2" ] ; then
    logger -t "【opt】" "opt 内存安装, 模式:$installs, 没有百度云"
    /tmp/sh_installs.sh $ssfile2 2
    syncys=0
    if [ ! -f "/opt/opti.txt" ] ; then
        logger -t "【opt】" "内存安装失败"
    fi
fi
rm -f /tmp/cron_adb.lock
#/tmp/sh_func_load_adbyby.sh
echo "2016-12-26-2" > /etc/storage/scripti.txt
[ -f /tmp/scripti.txt ] && { nvram set scriptt=`cat /tmp/scripti.txt`; scriptx1=$(cat /tmp/scripti.txt); }
[ -f /etc/storage/scripti.txt ] && { nvram set scripto=`cat /etc/storage/scripti.txt`; scriptx2=$(cat /etc/storage/scripti.txt); }
[ -f /opt/lnmpi.txt ] && nvram set lnmpt=`cat /tmp/lnmpi.txt`
[ -f /opt/lnmp.txt ] && nvram set lnmpo=`cat /opt/lnmp.txt`
[ ! -f /etc/storage/PhMain.ini ] && touch /etc/storage/PhMain.ini
[ ! -f /etc/storage/init.status ] && touch /etc/storage/init.status
restart_firewall &
sleep 10
/tmp/sh_upopt.sh
touch /tmp/webui_yes
nvram set ssserver_status=0000
nvram set ssrserver_status=0000
/etc/storage/crontabs_script.sh &
rm -f /tmp/script.lock
logger -t "【自定义脚本】" "脚本完成"
