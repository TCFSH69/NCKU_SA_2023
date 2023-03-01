# NASA HW1

[![hackmd-github-sync-badge](https://hackmd.io/hhFLHXlMTyelEds-NHPNjA/badge)](https://hackmd.io/hhFLHXlMTyelEds-NHPNjA)

## Patch
  ```shell!
  freebsd-update fetch install
  ```
  
## 安裝套件
  ```shell!
  pkg
  pkg update && pkg upgrade
  pkg install curl sudo wireguard vim python3 mtr
  ```
  
## Add user "judge"
- <b>密碼自填</b>

![](https://i.imgur.com/2cU2N73.png)

## 權限調整
  ```shell!
  vim /usr/local/etc/sudoers
  #新增 judge ALL=(ALL:ALL) NOPASSWD:ALL 以給予judge sudo的權限
  ```
![](https://i.imgur.com/Ko6wHpT.png)

## \*.conf/rsa_pubkey
#### 注意：judge.conf是給vm用的，test.conf是給host自己測試用的
1. 在host上ssh-keygen
2. 複製rsa_pubkey到authorized_keys
3. scp兩個file到vm (```scp judge.conf rsa_pubkey judge@x.x.x.x:~```)

![](https://i.imgur.com/kuopSIW.png)



## Wireguard settings(\*.conf)
  ```shell!
  su judge
  sudo cp ~/judge.conf /usr/local/etc/wireguard/
  sudo wg-quick up judge
  ifconfig
  ```
  這時候應該會出現名為judge的網卡
  ![](https://i.imgur.com/e6zXUOC.png)

## SSH no password settings(rsa_pubkey)
  ```shell!
  cd ~
  mkdir .ssh
  cp authorized_keys .ssh/
  ```
  如此一來再使用```ssh judge@x.x.x.x```時就能免密碼登入了
