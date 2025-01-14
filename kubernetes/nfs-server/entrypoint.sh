#!/bin/bash
set -e

ALLOWED_CLIENTS="${ALLOWED_CLIENTS:-*}"

echo "/exports $ALLOWED_CLIENTS(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports

rpcbind || true
rpc.statd || true

echo "Starting NFS server..."



mount -t nfsd nfsd /proc/fs/nfsd

rpc.nfsd -N 3 -V 4 --grace-time 10 $nfsd_debug_opt &
rpc.mountd -N 2 -N 3 -V 4 --foreground $mountd_debug_opt &

wait

# rpc.mountd -N 2 -N 3 -V 4 --foreground

# wait
