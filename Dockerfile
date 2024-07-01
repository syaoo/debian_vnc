################################################
# build vnc server
################################################
ARG DISABLE_SSH="n"
ARG DISABLE_VNC="n"
ARG DISABLE_X11="n"
# 系统时区
ARG LOCAL_TIME=Asia/Shanghai

FROM scratch
ARG REBUILD="n"
ARG LOCAL_TIME
ADD rootfs.tar.xz /
COPY script/* /etc/
RUN echo "calc and nuSolve with vnc on xfce." \
&& chmod +x /etc/create.sh \
&& /etc/create.sh  \
&& rm -rf /etc/create.sh \
&& chmod +x /etc/entry.sh \
&& echo "calc and nuSolve with vnc Done."
ENTRYPOINT ["/etc/entry.sh"]
CMD ["-u", "foo", "-p", "123456", "-v"]
