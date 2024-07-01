#!/bin/bash
# 1. 创建用户
# 2. 初始化环境
# 3. 启动ssh、vnc（如需要）
# set -e

genstart(){
echo "#!/bin/sh
date >> \${HOME}/.vnc/x11vnc.log
#x11vnc -forever -usepw -create -rfbport $1 >> \${HOME}/.vnc/x11vnc.log 2>&1 &
nohup x11vnc -forever -usepw -create -rfbport $1 -shared >> \${HOME}/.vnc/x11vnc.log 2>&1 &
sleep 1
date >> \${HOME}/.vnc/xfce.log
# startxfce4 >> \${HOME}/.vnc/xfce.log 2>&1
# 修改输入法设置
dconf write /desktop/ibus/general/preload-engines \"['xkb:us::eng', 'rime']\"
# 启动输入法守护进程
ibus-daemon --xim --daemonize
export LC_ALL=en_US.UTF-8
exec startxfce4 >> \${HOME}/.vnc/xfce.log 2>&1
" > $2
}

runvnc(){
	passwd=$1
	vnc_port=$2
	if [ ! -d {$HOME}/.vnc ];
		then mkdir ${HOME}/.vnc 
	fi
	x11vnc -storepasswd $passwd ${HOME}/.vnc/passwd
	genstart $vnc_port $HOME/.vnc/start.sh
	xvfb-run --server-args="-screen 0, 1920x1080x24" $HOME/.vnc/start.sh
}

user_name='foo' # 用户名
user_passwd='123456' # 密码
use_ugID='no'
uid_par='' #用户ID 用户组ID
have_vnc='no' #是否启用VNC

# 参数处理
while getopts ":u:p:U:v" opt;do
        case $opt in
                u)
                        # usrname
                        user_name=$OPTARG
                        ;;
                p)
                        # user password
                        user_passwd=$OPTARG
                        ;;
                U)
                        # user id or user group id
                        use_ugID='yes'
                        uid_par=$OPTARG
                        ;;
                v)
                        # enable vnc
                        have_vnc="yes"
                        ;;
                ?)
                        iopts=($*)
                        idx=$[$OPTIND-2]
                        echo "Invalid option: ${iopts[$idx]}"
                        exit 1
                        ;;
        esac
done

echo "user name is:" $user_name
echo "user password is:" $user_passwd

USER=$user_name
PASSWD=$user_passwd
vnc_port=5900

echo "Start ssh server..."
/etc/init.d/ssh start

# Add user
id $USER > /dev/null 2>&1
if [ $? -ne 0 ];then
	echo "Creat user: $USER"
	if [ "${use_ugID,,}" == "yes" ];then
		userID=${uid_par%:*}
		groupID=${uid_par#*:}
		addgroup --gid $groupID $USER
		useradd -m -s /bin/bash $USER -u $userID -g $groupID
	else
		useradd -m -s /bin/bash $USER
	fi
else
	echo "User: $USER already exist."
fi
echo "Chang $USER passwd"
yes $PASSWD | passwd ${USER} > /dev/null 2>&1
# echo $USER:${PASSWD} | chpasswd


if [ "${have_vnc,,}" == "yes" ];then
	# config vnc
	# generate password file
	echo "Start vnc server.."
	# create passwd file
	if [ ! -d /home/${USER}/.vnc ];then
		mkdir /home/${USER}/.vnc
	fi
	x11vnc -storepasswd $PASSWD /home/${USER}/.vnc/passwd
	genstart $vnc_port /home/${USER}/.vnc/start.sh
	chmod +x /home/${USER}/.vnc/start.sh
	chown ${USER}:${USER} -R /home/${USER}/.vnc/
	#su - $USER -c "xvfb-run --server-args=\"-screen 0, 1920x1080x24\" \$HOME/.vnc/start.sh &"
	gosu $USER xvfb-run -a --server-args="-screen 0, 1920x1080x24" /home/$USER/.vnc/start.sh &
#	su $USER -c if [ ! -d {$HOME}/.vnc ];then mkdir ${HOME}/.vnc fi; && \
#		x11vnc -storepasswd $PASSWD ${HOME}/.vnc/passwd; && \
#		genstart $vnc_port $HOME/.vnc/start.sh; && \
#		xvfb-run --server-args="-screen 0, 1920x1080x24" $HOME/.vnc/start.sh &
#else
#	su - $USER
fi

# Change user
#su - $USER
#gosu $USER bash

#LANG=C.utf8
bash
