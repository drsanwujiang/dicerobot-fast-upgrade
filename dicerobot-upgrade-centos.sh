#!/bin/bash

function exceptional_termination() {
  printf "======================================================================================================\n\n"
  printf "脚本意外终止\n"
  exit 1
}

function process_failed() {
  printf "\033[31m%s\033[0m\n\n" "$1"
  exceptional_termination
}

printf "======================================================================================================\n"
printf "\033[32m                                         DiceRobot 快速升级脚本\033[0m\n"
printf "======================================================================================================\n\n"

# Check privilege
if [[ $EUID -ne 0 ]]; then
  process_failed "请使用 sudo 权限运行此脚本"
fi

# Check directories
if [ ! -d "dicerobot" ]; then
  process_failed "未检测到 DiceRobot 安装目录，无法升级"
fi

if [ ! -d "mirai" ]; then
  process_failed "未检测到 Mirai 安装目录，无法升级"
fi

# Check services
if (systemctl --quiet is-active mirai); then
  printf "\033[33m检测到 Mirai 运行中，正在停止……\033[0m\n\n"
  systemctl stop mirai
fi

if (systemctl --quiet is-active dicerobot); then
  printf "\033[33m检测到 DiceRobot 运行中，正在停止……\033[0m\n\n"
  systemctl stop dicerobot
fi

# Input QQ account profile
printf "\033[32m1. 输入 QQ 账号信息\033[0m\n"

while true
do
  read -r -p "请输入机器人的 QQ 号码: " qq_id
  read -r -p "请输入机器人的 QQ 密码: " qq_password

  printf "\n****************************************\n"
  printf "%-15s   %-20s\n" " QQ 号码" "   QQ 密码"
  printf "****************************************\n"
  printf "%-15s   %-20s\n" "${qq_id}" "${qq_password}"
  printf "****************************************\n"
  printf "\033[33m请确认以上信息是否正确？\033[0m [Y/N] "
  read -r is_correct
  printf "\n"

  case $is_correct in
    [yY][eE][sS]|[yY])
      break
      ;;

    *)
      ;;
  esac
done

printf "Done\n\n"

# Upgrade Swoole
printf "\033[32m2. 升级 Swoole\033[0m\n"
printf "这一步可能需要 1~2 分钟时间，请耐心等待……\n"

dnf -y -q install curl-devel php-curl
rm -f /etc/php.d/20-swoole.ini
pecl uninstall swoole > /dev/null 2>&1
printf "yes\nyes\nyes\nno\nyes\nyes\n" | pecl upgrade https://dl.drsanwujiang.com/dicerobot/dicerobot3-swoole.tgz > /dev/null 2>&1
echo "extension=swoole.so" > /etc/php.d/20-swoole.ini

if ! (php --ri swoole > /dev/null 2>&1); then
  process_failed "Swoole 安装失败"
fi

printf "\nDone\n\n"

# Upgrade Mirai
printf "\033[32m3. 升级 Mirai\033[0m\n"

wget -q https://dl.drsanwujiang.com/dicerobot/dicerobot3-mirai.zip
rm -rf mirai/config
rm -rf mirai/libs
rm -rf mirai/logs
rm -rf mirai/plugins
unzip -qq -o dicerobot3-mirai.zip -d mirai
rm -f dicerobot3-mirai.zip
rm -rf mirai/data/net.mamoe.mirai-api-http
mv mirai/data/MiraiApiHttp mirai/data/net.mamoe.mirai-api-http
cat > mirai/config/Console/AutoLogin.yml <<EOF
accounts:
  -
    account: ${qq_id}
    password:
      kind: PLAIN
      value: ${qq_password}
    configuration:
      protocol: ANDROID_PHONE
EOF
cat > mirai/config/net.mamoe.mirai-api-http/setting.yml <<EOF
adapters:
  - http
  - webhook

enableVerify: false
verifyKey: 12345678

singleMode: true

cacheSize: 4096

adapterSettings:
  http:
    host: 127.0.0.1
    port: 8080
    cors:
      - *

  webhook:
    destinations:
      - "http://127.0.0.1:9500/report"
EOF

printf "\nDone\n\n"

# Upgrade DiceRobot
printf "\033[32m4. 升级 DiceRobot\033[0m\n"

wget -q https://dl.drsanwujiang.com/dicerobot/dicerobot3-skeleton-update.zip
unzip -qq -o dicerobot3-skeleton-update.zip -d dicerobot
rm -f dicerobot3-skeleton-update.zip
composer --no-interaction --quiet update --working-dir dicerobot --no-dev

printf "\nDone\n\n"

# Normal termination
printf "======================================================================================================\n\n"
printf "DiceRobot 及其运行环境已经升级完毕，接下来请正常运行 DiceRobot 及 Mirai 即可\n"
