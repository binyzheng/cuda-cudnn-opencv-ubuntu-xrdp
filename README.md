# cuda-cudnn-opencv-ubuntu-xrdp
该docker镜像是基于[这篇ubuntu-xrdp](https://github.com/danielguerra69/ubuntu-xrdp)，只是在这个基础上加入cuda10.2和cudnn8以及OpenCV4.5.0        
## 构建方法
```
sudo docker build -t xxx .      # xxx代表镜像命名
```
## 启动方法
```
sudo docker run -d --gpus all --shm-size 1g -p 3389:3389 xxx
```
## 采用docker-compose启动
由于这里开启了cuda,所以需要在`/etc/docker/daemon.json`文件添加
```
"runtimes": {
"nvidia": {
"path": "/usr/bin/nvidia-container-runtime",
"runtimeArgs": []
}
}
```
接下来重启docker服务
```
sudo systemctl daemon-reload
sudo systemctl restart docker
```
启动compose
```
sudo docker-compose -d up
```
关闭compose
```
sudo docker-compose down
```