#!/bin/bash

for sf in "$@"; do
    curl https://repository.surfsara.nl/datasets/cwi/lsqb/files/lsqb-merged/social-network-sf${sf}-merged-fk.tar.zst       --output social-network-sf${sf}-merged-fk.tar.zst
    curl https://repository.surfsara.nl/datasets/cwi/lsqb/files/lsqb-projected/social-network-sf${sf}-projected-fk.tar.zst --output social-network-sf${sf}-projected-fk.tar.zst
done

for sf in "$@"; do
    tar --use-compress-program=zstd -xvf social-network-sf${sf}-merged-fk.tar.zst
    tar --use-compress-program=zstd -xvf social-network-sf${sf}-projected-fk.tar.zst
done
