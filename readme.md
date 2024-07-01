rootfs.tar.xz download from https://github.com/debuerreotype/docker-debian-artifacts/raw/8d227a7d1f698c702d82e7de764ed0a7df65fb7c/bookworm/rootfs.tar.xz

工程目录结构：

```sh
$ tree ./ -L 2
./
├── compose.yaml
├── Dockerfile
├── readme.md
├── rootfs.tar.xz
└── script
    ├── entry.sh
    └── init_install_environment.sh
```

镜像可以选择性的使用ssh、vnc、x11 forward服务，内置浏览器、中文输入法等。

## 编译镜像

有两个方法：

1. 使用 docker compose 编译，在工作目录使用命令`docker compose build`
2. 使用docker build编译，在工作目录下使用如下命`docker build . -t debian_vnc:v1`

可选编译参数：

使用方法

```
docker build . -t debian_vnc --build-arg DISABLE_SSH=y
```
 
## 启动镜像

使用如下命令启动镜像
```
docker run --security-opt seccomp=unconfined -p 2224:22 -p 5982:5900 -dit debian_vnc
```

其中`-p 2224:22`是将docker容器中的ssh所使用的22端口，映射到宿主机2224端口，可使用宿主机机IP通过2224端口访问容器SSH服务；
`-p 5982:5900`是将docker容器中的vnc使用的5900端口号映射到宿主机的5982端口，可使用宿主机机IP通过5982端口访问容器VNC服务。

**使用VNC需要增加`--security-opt seccomp=unconfined`**

### 挂载宿主机目录

```sh
docker run --security-opt seccomp=unconfined -p 2224:22 -p 5982:5900 -dit  -v /mnt/F-dat/:/dat1 -v /mnt/T-dat/:/dat2 DISABLE_SSH=
```

使用`-v`参数挂载目标，`:`冒号前面是宿主机目录路径，冒号后是容器内路径，上面示例中挂载了两个目录，在容器内通过/dat1，/dat2分别访问宿主机/mnt/F-dat/和/mnt/T-dat/目录

### 启动参数

默认情况下，容器启动后用户名为foo，密码为123456. 也可根据需要使用选项对用户名密码等进行设置，可用选项有：

-u <用户名>  设置用户名  
-p <密码> 设置密码  
-U <用户ID[:组ID]> 设置用户ID及其所属组ID  
-v 	设置是是否启动VNC，默认不启动  

其中-U选项主要用于解决挂载主机目录时产生的读写权限问题。例如下面示例中，挂载主机目录/mnt/F-dat/、/mnt/T-dat/的所属用户为abc, 所属用户组为abc，

```
$ ls -l
drwxrwxr-x 2 abc abc  4096 2月  12 20:31 F-dat
drwx------ 2 abc abc  4096 2月  19 12:14 T-dat
```

使用ID命令查看abc的uid=1001和gid=1001
```
$ id abc
uid=1001(abc) gid=1001(abc) groups=1001(abc)
```

为了能够在容器内正常访问挂载的本机目录，使用`-U 1001:1001`设置启动容器用户的uid和gid

```sh
docker run --security-opt seccomp=unconfined -p 2224:22 -p 5982:5900 -dit  -v /mnt/F-dat:/dat1 -v //mnt/F-dat:/dat2 calc:v3  -u xyz -p 12345 -U 1001:1001 -v
```

## 3. 容器访问

1. 直接连接容器
```
docker exec -it <id> bash
```

其中id为容器id，成功运行docker镜像会输出一组字符串为该容器ID，也是使用`docker container ls`命令查看

2. 通过ssh连接

```
ssh <user>@ip -p <port>
```

ssh连接时增加`-X`选项，还可以通过X11转发打开图形界面


```
ssh -X  <user>@ip -p <port>
```

登录后，输入启动命令即可打开图像界面，例如打开waterfox浏览器：`/etc/waterfox/waterfox`

3. 通过VNC访问

使用vnc客户端输入ip和端口号连接

