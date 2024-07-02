#!/bin/bash
################################################################
# this script functions
# set up base environment, install function package, and some setup options.
# default function is all of below.
# can choosen at build use argumets.
# 1. ssh 
# 2. x11 forward
# 3. vnc with xfce
# -ns for no ssh, -nx for no x11, -nv for no vnc
###############################################################

set -e

disable_ssh=false
disable_x11=false
disable_vnc=false
local_time=""
while getopts ":n:L:h" opt; do
	case $opt in
		n)
			if [[ $OPTARG == *s* ]];then
				disable_ssh=true;
			fi
			if [[ $OPTARG  == *x* ]];then
				disable_x11=true;
			fi
			if [[ $OPTARG == *v* ]];then
				disable_vnc=true;
			fi
			;;
		L)
			local_time=$OPTARG
			;;
		h)
			echo "$0 [-nxvc] [-LAsia/Shanghai]" 
			exit 0;
			;;
		*)
			echo "Invalid option -$OPTARG"
			exit 1;
			;;
	esac
done

echo "Function ssh: $disable_ssh"
echo "Function x11: $disable_x11"
echo "Function vcn: $disable_vnc"
if [ ! -z "$local_time" ];then
	echo "Set time region: $local_time"
fi

check_success(){
	if [ $1 -ne 0 ];then
        	echo "operate fail [$1]."
        	exit 1
	fi
}
export DEBIAN_FRONTEND=noninteractive
echo "Install base package..."
apt-get update
apt-get install -y locales fonts-wqy-zenhei python3 vim-tiny \
	curl bzip2
check_success $?

sed -i '/^[^#[:space:]]/ s/^\([^#]\)/# \1/' /etc/locale.gen
sed -i '/^# en_US\.UTF-8 UTF-8/ s/^# //' /etc/locale.gen
locale-gen en_US.UTF-8 
update-locale LANG=en_US.UTF-8
update-locale LC_ALL=en_US.UTF-8
source /etc/default/locale
echo "export LANG=en_US.UTF-8" >> /etc/bash.bashrc
echo "export LC_ALL=en_US.UTF-8" >> /etc/bash.bashrc

if [ -z `which python` ]; then
        ln -sf /usr/bin/python3 /usr/bin/python
fi
ln -sf /usr/bin/vim.tiny /usr/bin/vim

# set time
if [ -z ${local_time} ];then
	local_time=$(curl --fail -s https://ipapi.co/timezone)
	[[ $? -ne 0 ]] && local_time=Asia/Shanghai
fi
ln -sf /usr/share/zoneinfo/${local_time} /etc/localtime

# for ssh
if [ $disable_ssh == false ];then
	echo "Install ssh server."
	apt-get install -y openssh-server
	check_success $?
	# for x11 Forward
	if [ $disable_x11  == false ];then
		echo "Enable x11 forward."
		echo "Install x11-apps for test x11 forward function..."
		apt-get install -y x11-apps 
		sed -i "s/#X11UseLocalhost yes"/"X11UseLocalhost no"/g /etc/ssh/sshd_config
	fi
fi

# for vnc
if [ $disable_vnc == false ];then
	echo "VNC server and desktop environment..."
	apt-get install -y xfdesktop4 xfwm4 xfdesktop4 xfce4-settings \
		xfce4-session xfconf xfce4-notifyd xfce4-panel \
		thunar xfce4-terminal dbus-x11 x11vnc xvfb gosu
	check_success $?

	# ibus-rime about 600MB
	echo "Install ibus-rime..."
	apt-get install -y ibus-rime
	# firefox-esr about 800MB
	# apt-get install -y firefox-esr # 使用waterfox替代
	echo  "Download waterfox..."
	DURL=`curl -s https://www.waterfox.net/download/ -o - | grep -oP 'href="(\Khttps://cdn1.waterfox.net/waterfox/releases/G.*/Linux_x86_64/waterfox-G.*bz2)(?=")'`
	if [ -z $DURL ]; then
		echo "Get Waterfox download url fail."
		exit 1;
	fi
	curl ${DURL} -o waterfox.tar.bz2
	if [ $? -eq 0 ]; then
		tar -xf waterfox.tar.bz2 -C /etc
		rm waterfox.tar.bz2
		update-alternatives --install /usr/bin/x-www-browser x-www-browser /etc/waterfox/waterfox 90\
			--slave /usr/share/man/man1/x-www-browser.1.gz x-www-browser.1.gz /usr/local/share/man/man1/waterfox.1.gz
		echo "[Desktop Entry]" > /usr/share/applications/waterfox.desktop
		echo "Name=Waterfox" >> /usr/share/applications/waterfox.desktop
		echo "Exec=/etc/waterfox/waterfox %u" >> /usr/share/applications/waterfox.desktop
		echo "Terminal=false"  >> /usr/share/applications/waterfox.desktop
		echo "X-MultipleArgs=false"  >> /usr/share/applications/waterfox.desktop
		echo "Type=Application"  >> /usr/share/applications/waterfox.desktop
		echo "Icon=/etc/waterfox/browser/chrome/icons/default/default48.png" >> /usr/share/applications/waterfox.desktop
		echo "Categories=Network;WebBrowser;" >> /usr/share/applications/waterfox.desktop
		echo "MimeType=text/html;text/xml;application/xhtml+xml;application/xml;"`
			`"application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;"`
			`"image/gif;image/jpeg;image/png;x-scheme-handler/http;"`
			`"x-scheme-handler/https;" >> /usr/share/applications/waterfox.desktop
		echo "StartupWMClass=Waterfox" >> /usr/share/applications/waterfox.desktop
		echo "StartupNotify=true" >> /usr/share/applications/waterfox.desktop
		echo "Categories=Network;WebBrowser;Internet" >> /usr/share/applications/waterfox.desktop
	fi
fi

# clean 
echo "Clean cache..."
apt-get clean
rm -r /var/lib/apt/lists/*

