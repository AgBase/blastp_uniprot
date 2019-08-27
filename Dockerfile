## Dockerfile
FROM ubuntu:16.04
MAINTAINER Amanda Cooksey	
LABEL Description="AgBase GOanna tool"

# Install all the updates and download dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    wget \
    bzip2

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda2-4.0.5-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh


# give write permissions to conda folder
RUN chmod 777 -R /opt/conda/

ENV PATH=$PATH:/opt/conda/bin

RUN conda config --add channels bioconda

RUN conda upgrade conda

# add blast 2.7.1--i added this
RUN conda install -c conda-forge -c bioconda blast==2.7.1

ENV PATH /blastp_uniprot.sh/:$PATH

# add blastp_uniprot--i added this
ADD blastp_uniprot.sh /usr/bin

# Change the permissions and the path for the wrapper script
RUN chmod +x /usr/bin/blastp_uniprot.sh

RUN mkdir /work-dir
RUN mkdir /uniprot_database

# Entrypoint
ENTRYPOINT ["/usr/bin/blastp_uniprot.sh"]


# Add path to working directory
WORKDIR /work-dir
