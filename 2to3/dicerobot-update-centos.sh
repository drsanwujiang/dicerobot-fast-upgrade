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
printf "\033[32m                                         DiceRobot 快速更新脚本\033[0m\n"
printf "======================================================================================================\n\n"

# Check privilege
if [[ $EUID -ne 0 ]]; then
  process_failed "请使用 sudo 权限运行此脚本"
fi

# Check directories
if [ ! -d "dicerobot" ];then
  process_failed "未检测到 DiceRobot 安装目录，无法更新"
fi

if [ ! -d "mirai" ];then
  process_failed "未检测到 Mirai 安装目录，无法更新"
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

# Update Swoole
printf "\033[32m2. 更新 Swoole\033[0m\n"
printf "这一步可能需要数分钟时间，请耐心等待……\n"

dnf -y -q install curl-devel php-curl
rm -f /etc/php/7.4/cli/conf.d/20-swoole.ini
pecl uninstall swoole > /dev/null 2>&1
printf "yes\nyes\nyes\nno\nyes\nyes\n" | pecl install https://dl.drsanwujiang.com/dicerobot/swoole.tgz > /dev/null 2>&1
echo "extension=swoole.so" > /etc/php/7.4/mods-available/swoole.ini
ln -s /etc/php/7.4/mods-available/swoole.ini /etc/php/7.4/cli/conf.d/20-swoole.ini

if ! (php --ri swoole > /dev/null 2>&1); then
  process_failed "Swoole 安装失败"
fi

printf "\nDone\n\n"

# Update Mirai
printf "\033[32m3. 更新 Mirai\033[0m\n"

wget -q https://dl.drsanwujiang.com/dicerobot/dicerobot3-mirai.zip
rm -rf mirai/config
rm -rf mirai/libs
rm -rf mirai/logs
rm -rf mirai/plugins
unzip -qq dicerobot3-mirai.zip -d mirai
rm -f dicerobot3-mirai.zip
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
cors:
  - '*'
host: 0.0.0.0
port: 8080
authKey: 12345678
cacheSize: 4096
enableWebsocket: false
report:
  enable: true
  groupMessage:
    report: true
  friendMessage:
    report: true
  tempMessage:
    report: true
  eventMessage:
    report: true
  destinations: [
    "http://127.0.0.1:9500/report"
  ]
  extraHeaders: {}

heartbeat:
  enable: true
  delay: 1000
  period: 300000
  destinations: [
    "http://127.0.0.1:9500/heartbeat"
  ]
  extraBody: {}
  extraHeaders: {}
EOF

printf "\nDone\n\n"

# Update DiceRobot
printf "\033[32m4. 更新 DiceRobot\033[0m\n"

wget -q https://dl.drsanwujiang.com/dicerobot/dicerobot3-skeleton-update.zip
unzip -qq dicerobot3-skeleton-update.zip -d dicerobot
rm -f dicerobot3-skeleton-update.zip
composer --no-interaction --quiet update --working-dir dicerobot --no-dev

printf "\nDone\n\n"

# Normal termination
printf "======================================================================================================\n\n"
printf "DiceRobot 及其运行环境已经更新完毕，接下来请依照说明文档运行 DiceRobot 及 Mirai 即可\n"
