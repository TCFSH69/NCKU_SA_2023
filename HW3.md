# NASA HW3


## Tools
  ```shell!
  sudo pkg install logrotate wget
  ```
  
## General
![](https://hackmd.io/_uploads/SkSI8OmHn.png)

  ```shell!
  service zfs start
  ```
  
## Zpool Config
![](https://hackmd.io/_uploads/Hk8owO7H3.png)

```shell!
zpool create sa_pool raidz1 /dev/ada1 /dev/ada2 /dev/ada3
mkdir /sa_data
zfs create -o compression=lz4 -o copies=2 -o atime=off sa_pool/data
zfs set mountpoint=/sa_data sa_pool/data
##chown for permission if needed
```

## logrotate
```shell!
 mkdir /var/log/fakelog 
 mkdir /etc/logrotate.d
 vim /etc/logrotate.d/fakelog
 ```
  ```shell=
  /var/log/fakelog.log {
    rotate 10
    size=1k
    olddir /var/log/fakelog/
  }
  ```

## ZFS Tool
1. sabktool
```shell!
vim sabktool
```
```shell=
#!/usr/local/bin/bash
if [ "$#" -eq 0 ]; then
        echo 'invalid'
fi

if [ "$1" == 'create' ]; then
        if [ "$#" -eq 1 ]; then
                exit 1
        fi
        sudo zfs snapshot sa_pool/data@"$2"
elif [ "$1" == 'remove' ]; then
        if [ "$#" -eq 1 ]; then
                exit 1
        fi
        if [ "$2" == 'all' ]; then
                sudo zfs list -rt snapshot sa_pool/data | awk '(NR>1){print $1}' | xargs -n 1 sudo zfs destroy
        else
                sudo zfs destroy sa_pool/data@"$2"
        fi
elif [ "$1" == 'list' ]; then
        if [ "$#" -eq 0 ]; then
                exit 1
        fi
         sudo zfs list -rt snapshot sa_pool/data | awk '(NR>1){print $1}'
elif [ "$1" == 'roll' ]; then
        if [ "$#" -eq 1 ]; then
                exit 1
        fi
        sudo zfs rollback -r sa_pool/data@"$2"
elif [ "$1" == 'logrotate' ]; then
        sudo logrotate /etc/logrotate.d/sabklog
fi
```

2. sabklog
```shell!
vim sabklog
```
```shell=
/var/log/fakelog.log {
        copytruncate
        rotate 10
        size=1k
        olddir /sa_data/log
}
```

3. move to /usr/bin
```shell!
chmod +x sabktool
cp sabktool /usr/bin
```
