docker-build:
  docker run --privileged --rm -it -v ./:/workdir ghcr.io/joeyeamigh/nixos-superbird/builder:latest

installer:
  #!/usr/bin/env bash
  set -euo pipefail

  nix build '.#nixosConfigurations.superbird.config.system.build.installer' --show-trace
  echo "kernel is $(stat -Lc%s -- result/builder/kernel | numfmt --to=iec)"
  echo "rootfs is $(stat -Lc%s -- result/rootfs.img | numfmt --to=iec)"

  sudo rm -rf ./out
  mkdir ./out
  cp -r ./result/* ./out/
  chown -R $(whoami):$(whoami) ./out
  cd ./out

  sudo ./scripts/make-bootfs.sh
  echo "bootfs built!"

  just zip-installer

zip-installer:
  #!/usr/bin/env bash
  set -euo pipefail

  cd ./out/
  zip nixos.zip rootfs.img bootfs.bin meta.json env.txt readme.md

push:
  nix run github:serokell/deploy-rs