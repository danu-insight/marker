ARG IMAGE_TAG=2.1.0-cuda11.8-cudnn8-runtime

FROM pytorch/pytorch:${IMAGE_TAG}

VOLUME /root/.cache

WORKDIR /app

COPY ./scripts /app/scripts

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
  && apt-get install apt-transport-https software-properties-common lsb-release -y \
  && add-apt-repository ppa:alex-p/tesseract-ocr-devel \
  && scripts/install/ghostscript_install.sh \
  && apt-get install -y $(cat scripts/install/apt-requirements.txt) \
  && rm -rf /var/lib/apt/lists/*

COPY ./pyproject.toml ./poetry.lock ./

RUN pip install pip==23.3.1 \
  && pip install poetry==1.5.0 \
  && poetry config virtualenvs.create false \
  && poetry install --no-dev --no-interaction --no-ansi --no-root

COPY . .


ARG TESSDATA_PREFIX=/usr/share/tesseract-ocr/5/tessdata
ENV TESSDATA_PREFIX=${TESSDATA_PREFIX}

# Test to make sure the TESSDATA_PREFIX is set correctly
RUN find / -name tessdata 2> /dev/null | grep "${TESSDATA_PREFIX}"

# The following are copied from https://github.com/runpod/containers/blob/main/official-templates/pytorch/Dockerfile
# Update, upgrade, install packages and clean up
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt install --yes --no-install-recommends git wget curl bash libgl1 software-properties-common openssh-server nginx && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# Start Scripts
RUN wget -O /start.sh https://raw.githubusercontent.com/runpod/containers/main/container-template/start.sh
RUN chmod +x /start.sh

# Welcome Message
RUN echo 'echo -e "\nWelcome to the `marker` Docker image."' >> /root/.bashrc

# Set the default command for the container
CMD [ "/start.sh" ]
