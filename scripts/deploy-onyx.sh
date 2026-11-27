#!/usr/bin/env bash
# Publish Burrow to the Gno.land Onyx testnet and claim it.
#
# This script does not deploy by itself in CI. Run it on a machine that holds
# the gnokey key you want to own the realm.
#
#   scripts/deploy-onyx.sh <gnokey-key-name>
#
# What you need first
#   - gno and gnokey built from gnolang/gno master
#     (this repo pins 58af98ed7956844df743c12f26834c5a1d3468e4).
#   - A local key:  gnokey add --recover <key-name>
#   - Testnet coins for that address from https://faucet.gno.land
#     (choose the current testnet, Onyx). Confirm with:
#       gnokey query bank/balances/<g1-address> \
#         -remote https://rpc.onyx.testnets.gno.land:443
#
# Named namespaces such as gno.land/r/faddat/... are not available yet
# (see gnolang/gno docs/resources/users-and-teams.md). The source tree keeps
# the faddat path so `gno test` and `gnodev` have a stable module path. This
# script copies the packages and rewrites that path to the signing key's
# address, which is the permissionless namespace:
#
#   gno.land/p/<g1-address>/burrow
#   gno.land/r/<g1-address>/burrow
#
# Set NAMESPACE to override the path segment. Only do that when the name is
# actually registered; otherwise addpkg is rejected.
#
# The first successful Claim becomes the owner. Run this script through the
# Claim step before advertising the realm, or someone else can claim it.
#
# Onyx enables a new package a few seconds after addpkg. If a call is refused
# immediately, wait and retry. https://gpas.latest.testnets.gno.land explains
# a refusal. This script does not call enablepkg; that transaction is for
# package approvers, not for the deployer.
#
# Environment
#   NAMESPACE            path segment (default: the key's g1 address)
#   CHAIN_ID             default onyx-1
#   REMOTE               default https://rpc.onyx.testnets.gno.land:443
#   GNO_HOME             passed as gnokey --home when set
#   GNO_PASSWORD         if set, piped once per transaction via
#                        --insecure-password-stdin. Leave unset to type it.
#   GAS_WANTED_DEPLOY    default 20000000
#   GAS_FEE_DEPLOY       default 20000ugnot   (meets 1ugnot / 1000 gas)
#   MAX_DEPOSIT_DEPLOY   default 20000000ugnot
#   GAS_WANTED_CALL      default 10000000
#   GAS_FEE_CALL         default 10000ugnot
#   MAX_DEPOSIT_CALL     default 5000000ugnot

set -euo pipefail

if [[ $# -ne 1 || -z ${1:-} ]]; then
  echo "usage: scripts/deploy-onyx.sh <gnokey-key-name>" >&2
  exit 2
fi

KEY=$1
CHAIN_ID=${CHAIN_ID:-onyx-1}
REMOTE=${REMOTE:-https://rpc.onyx.testnets.gno.land:443}
GAS_WANTED_DEPLOY=${GAS_WANTED_DEPLOY:-20000000}
GAS_FEE_DEPLOY=${GAS_FEE_DEPLOY:-20000ugnot}
MAX_DEPOSIT_DEPLOY=${MAX_DEPOSIT_DEPLOY:-20000000ugnot}
GAS_WANTED_CALL=${GAS_WANTED_CALL:-10000000}
GAS_FEE_CALL=${GAS_FEE_CALL:-10000ugnot}
MAX_DEPOSIT_CALL=${MAX_DEPOSIT_CALL:-5000000ugnot}

ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOME_ARGS=()
if [[ -n ${GNO_HOME:-} ]]; then
  HOME_ARGS=(--home "$GNO_HOME")
fi

command -v gnokey >/dev/null

ADDR=$(gnokey "${HOME_ARGS[@]}" list | awk -v key="$KEY" '
  $2 == key {
    for (i = 1; i <= NF; i++) if ($i == "addr:") { print $(i + 1); exit }
  }
')
if [[ -z $ADDR || $ADDR != g1* ]]; then
  echo "could not read a g1 address for key $KEY from gnokey list" >&2
  exit 1
fi

NS=${NAMESPACE:-$ADDR}
if [[ $NS == */* || $NS == *.* || -z $NS ]]; then
  echo "NAMESPACE must be a single path segment, got: $NS" >&2
  exit 1
fi
if [[ $NS != g1* ]]; then
  echo "warning: $NS is not an address. Named namespaces are not supported yet; addpkg will fail unless this name is registered." >&2
fi

PURE_PATH="gno.land/p/${NS}/burrow"
REALM_PATH="gno.land/r/${NS}/burrow"

stage_pkg() {
  local src=$1 dest=$2
  mkdir -p "$dest"
  cp "$src/gnomod.toml" "$dest/gnomod.toml"
  find "$src" -maxdepth 1 -type f -name '*.gno' \
    ! -name '*_test.gno' ! -name '*_filetest.gno' \
    -exec cp {} "$dest/" \;
  find "$dest" -type f -print0 | while IFS= read -r -d '' file; do
    local tmp
    tmp=$(mktemp)
    sed \
      -e "s#gno.land/p/faddat/burrow#${PURE_PATH}#g" \
      -e "s#gno.land/r/faddat/burrow#${REALM_PATH}#g" \
      "$file" >"$tmp"
    mv "$tmp" "$file"
  done
}

gnokey_tx() {
  if [[ -n ${GNO_PASSWORD:-} ]]; then
    printf '%s\n' "$GNO_PASSWORD" | gnokey "${HOME_ARGS[@]}" "$@" --insecure-password-stdin
  else
    gnokey "${HOME_ARGS[@]}" "$@"
  fi
}

wait_query() {
  local path=$1 data=$2
  local i
  for i in $(seq 1 30); do
    if gnokey query "$path" -data "$data" -remote "$REMOTE" >/dev/null 2>&1; then
      echo "visible: $data"
      return 0
    fi
    sleep 4
  done
  echo "still not queryable: $data" >&2
  echo "see https://gpas.latest.testnets.gno.land and retry the call. This script does not send enablepkg." >&2
  return 1
}

STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
stage_pkg "$ROOT/gno.land/p/faddat/burrow" "$STAGE/p"
stage_pkg "$ROOT/gno.land/r/faddat/burrow" "$STAGE/r"

echo "deploying $PURE_PATH"
gnokey_tx maketx addpkg \
  -pkgpath "$PURE_PATH" \
  -pkgdir "$STAGE/p" \
  -gas-fee "$GAS_FEE_DEPLOY" \
  -gas-wanted "$GAS_WANTED_DEPLOY" \
  -max-deposit "$MAX_DEPOSIT_DEPLOY" \
  -chainid "$CHAIN_ID" \
  -remote "$REMOTE" \
  "$KEY"
wait_query vm/qfile "${PURE_PATH}/gnomod.toml"

echo "deploying $REALM_PATH"
gnokey_tx maketx addpkg \
  -pkgpath "$REALM_PATH" \
  -pkgdir "$STAGE/r" \
  -gas-fee "$GAS_FEE_DEPLOY" \
  -gas-wanted "$GAS_WANTED_DEPLOY" \
  -max-deposit "$MAX_DEPOSIT_DEPLOY" \
  -chainid "$CHAIN_ID" \
  -remote "$REMOTE" \
  "$KEY"
wait_query vm/qrender "${REALM_PATH}:"

echo "claiming $REALM_PATH for $ADDR"
gnokey_tx maketx call \
  -pkgpath "$REALM_PATH" \
  -func Claim \
  -gas-fee "$GAS_FEE_CALL" \
  -gas-wanted "$GAS_WANTED_CALL" \
  -max-deposit "$MAX_DEPOSIT_CALL" \
  -chainid "$CHAIN_ID" \
  -remote "$REMOTE" \
  "$KEY"

echo
echo "Burrow is claimed by $ADDR"
echo "  pure package  $PURE_PATH"
echo "  realm         $REALM_PATH"
echo "  gnoweb        https://onyx.testnets.gno.land/r/${NS}/burrow"
echo "  gnoweb alias  https://latest.testnets.gno.land/r/${NS}/burrow"
echo "The first Claim wins. If this Claim was rejected because the realm was already claimed, do not advertise this deployment as yours."
