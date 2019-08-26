FROM jupyter/scipy-notebook:2ce7c06a61a1
MAINTAINER Antti Parviainen <antti.parviainen@aalto.fi>

# Install pyflinn, line_profiler and pyspark dependency for jupyterlab_variableinspector extension
RUN pip install --upgrade pip && \
    conda update -n base conda && \
    conda install --quiet --yes pyflann line_profiler && \
    conda install --quiet --yes -c conda-forge nodejs

# Install jupyterlab_variableinspector extension
RUN git clone https://github.com/lckr/jupyterlab-variableInspector && \
	cd jupyterlab-variableInspector/ && \
	npm install && \
	npm run build && \
	jupyter labextension install .

# Install Jupyter Notebook variable inspector extension. Not as good as the Lab.
RUN conda install --quiet --yes -c conda-forge jupyter_contrib_nbextensions && \
	jupyter nbextension enable varInspector/main --user

# Change, if you want to build with a different version of OpenCV
ENV OPENCV_VERSION 4.1.1

# Change to root
USER root

# Install OpenCV dependencies that are not already there
RUN apt-get update && apt-get install --yes \
	cmake \
	libgtk2.0-dev \
	libavcodec-dev \
	libavformat-dev \
	libswscale-dev

ENV OPENCV_CONTRIB_GIT_DIR=/opt/opencv_contrib
ENV OPENCV_GIT_DIR=/opt/opencv
ENV OPENCV_BUILD_DIR=/tmp/opencv/build
ENV CONDA_DIR=/opt/conda

RUN echo 'Prepare OpenCV extra modules' && \
	git clone https://github.com/opencv/opencv_contrib.git $OPENCV_CONTRIB_GIT_DIR && \
	cd $OPENCV_CONTRIB_GIT_DIR && \
	git checkout $OPENCV_VERSION && \
	echo 'Prepare OpenCV' && \
	git clone https://github.com/opencv/opencv.git $OPENCV_GIT_DIR && \
	cd $OPENCV_GIT_DIR && \
	git checkout $OPENCV_VERSION && \
	echo 'Prepare build (Python directories specified in the parent image)' && \
	mkdir -p $OPENCV_BUILD_DIR && \
	cd $OPENCV_BUILD_DIR && \
	cmake -D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/usr/local \
	-D OPENCV_EXTRA_MODULES_PATH=$OPENCV_CONTRIB_GIT_DIR/modules \
	-D OPENCV_ENABLE_NONFREE=ON \
	-D PYTHON3_EXECUTABLE=$CONDA_DIR/bin/python3.7 \
	-D PYTHON3_LIBRARY=$CONDA_DIR/lib/libpython3.7m.so \
	-D PYTHON3_INCLUDE_DIR=$CONDA_DIR/include/python3.7m \
	-D PYTHON3_NUMPY_INCLUDE_DIRS=$CONDA_DIR/lib/python3.7/site-packages/numpy/core/include \
	-D PYTHON3_PACKAGES_PATH=$CONDA_DIR/lib/python3.7/site-packages \
	$OPENCV_GIT_DIR && \
	echo 'Install' && \
	make -j $(nproc) && make install && ldconfig && \
	echo 'Clean installation and temporary files' && \
	rm -rf /opt/opencv* && \
	rm -rf /tmp/*

# Back to the default directory
WORKDIR /home/$NB_USER/work

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_USER
