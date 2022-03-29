#!/bin/bash

docker run -it -v media-volume:/root --name aws amazon/aws-cli configure
docker start aws
docker exec -it aws ls /root/
docker exec -it aws aws s3 sync /root/images s3://danyanftguy

docker stop aws
docker rm aws
