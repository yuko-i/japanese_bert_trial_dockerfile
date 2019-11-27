FROM pytorch/pytorch:latest

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"
ENV HOME=/home/$NB_USER
#RUN git clone https://github.com/NVIDIA/apex.git && cd apex && python setup.py install --cuda_ext --cpp_ext
RUN pip install transformers pyknp

USER root
ADD fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions && \
    chmod g+w /etc/passwd && \
    sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc  && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER  && \
    fix-permissions /home/$NB_USER && \
    apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential cmake libboost-all-dev google-perftools libgoogle-perftools-dev wget unzip

RUN wget -P /home/jovyan -q http://nlp.ist.i.kyoto-u.ac.jp/nl-resource/JapaneseBertPretrainedModel/Japanese_L-12_H-768_A-12_E-30_BPE_WWM_transformers.zip && \
    cd  /home/jovyan && unzip Japanese_L-12_H-768_A-12_E-30_BPE_WWM_transformers.zip

USER $NB_USER
RUN cd /home/$NB_USER && \
    wget http://lotus.kuee.kyoto-u.ac.jp/nl-resource/jumanpp/jumanpp-1.01.tar.xz && \
    tar xJvf jumanpp-1.01.tar.xz && \
    cd jumanpp-1.01 && \
    ./configure && \
    make

USER root
RUN cd /home/$NB_USER/jumanpp-1.01 && make install && \
    pip install jupyter notebook && \
    jupyter notebook --generate-config

EXPOSE 8888

RUN mkdir /etc/jupyter/ && fix-permissions /etc/jupyter/
COPY start-jupyter-notebook.sh /etc/jupyter/
COPY jupyter_notebook_config.py /etc/jupyter/
RUN chmod 744 /etc/jupyter/start-jupyter-notebook.sh && \
    chmod 777 -R /home/jovyan/.jupyter/


USER $NB_USER
