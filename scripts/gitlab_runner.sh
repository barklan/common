#!/bin/bash

# bash <(curl -s https://raw.githubusercontent.com/barklan/common/main/cicd/gitlab_runner.sh)

docker volume create gitlab-runner-config

docker run -d --name gitlab-runner --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v gitlab-runner-config:/etc/gitlab-runner \
    gitlab/gitlab-runner:latest

docker run --rm -it -v gitlab-runner-config:/etc/gitlab-runner gitlab/gitlab-runner:latest register

read -r -d '' runnerconfig << EOF || true
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "docker:stable"
    privileged = true
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/certs/client", "/cache"]
    shm_size = 0
EOF

sudo sed -i '1,/custom_build_dir/!d' /var/lib/docker/volumes/gitlab-runner-config/_data/config.toml

sudo bash -c "echo '  ${runnerconfig}' >> /var/lib/docker/volumes/gitlab-runner-config/_data/config.toml"

docker restart gitlab-runner
