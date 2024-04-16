
FROM nvidia/cuda:11.7.1-cudnn8-devel-ubuntu20.04

# Get deps
RUN apt-get update && \
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
python3-dev python3-pip python3-setuptools git g++ wget make libprotobuf-dev protobuf-compiler libopencv-dev \
libgoogle-glog-dev libboost-all-dev libhdf5-dev libatlas-base-dev

# For python api headless
RUN pip3 install --upgrade pip
RUN pip3 install numpy Flask opencv-python-headless

# Get Cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v3.16.0/cmake-3.16.0-Linux-x86_64.tar.gz && \
tar xzf cmake-3.16.0-Linux-x86_64.tar.gz -C /opt && \
rm cmake-3.16.0-Linux-x86_64.tar.gz
ENV PATH="/opt/cmake-3.16.0-Linux-x86_64/bin:${PATH}"

# Set the working directory to /openpose
WORKDIR /openpose
COPY ./openpose ./

# Create and move into the build directory to compile OpenPose
WORKDIR /openpose/build
RUN cmake -DBUILD_PYTHON=ON -DUSE_CUDNN=OFF .. && \
make -j `nproc`

WORKDIR /openpose/build/python/openpose
RUN cp ./pyopenpose.cpython-38-x86_64-linux-gnu.so /usr/local/lib/python3.8/dist-packages && \
    cd /usr/local/lib/python3.8/dist-packages && \
    ln -s pyopenpose.cpython-38-x86_64-linux-gnu.so pyopenpose
ENV LD_LIBRARY_PATH=/openpose/build/python/openpose

CMD ["python3", "-c", "import pyopenpose as op;"]
# Set the final working directory to /openpose
WORKDIR /openpose/api

EXPOSE 8081

CMD ["python3", "app.py"]