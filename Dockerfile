FROM hashicorp/terraform:0.13.2
RUN mkdir -p /root/.terraform.d/plugin-cache
ENV TF_PLUGIN_CACHE_DIR /root/.terraform.d/plugin-cache
RUN mkdir /root/workdir
WORKDIR /root/workdir
COPY main.tf .
RUN terraform init
ENTRYPOINT ["/bin/terraform"]
