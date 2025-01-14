


<https://wiki.alpinelinux.org/wiki/Setting_up_an_NFS_server>


example docker run

```bash
docker run --rm -it \
    --name nfs-server \
    --cap-add SYS_ADMIN \
    -e ALLOWED_CLIENTS="127.0.0.1.0/24" \
    -v (pwd)/test:/exports \
    --network host \
    nfs-server
```

currently not working, i like the idea of running the nfs server in a docker container, but doing it as a nixos module is probably better