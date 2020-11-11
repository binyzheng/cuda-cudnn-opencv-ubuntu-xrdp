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