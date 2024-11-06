#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

echo -e "${GREEN}"
cat << "EOF"
███████ ██      ██ ██   ██ ██ ██████      ███    ██  ██████  ██████  ███████ 
██      ██      ██  ██ ██  ██ ██   ██     ████   ██ ██    ██ ██   ██ ██      
█████   ██      ██   ███   ██ ██████      ██ ██  ██ ██    ██ ██   ██ █████   
██      ██      ██  ██ ██  ██ ██   ██     ██  ██ ██ ██    ██ ██   ██ ██      
███████ ███████ ██ ██   ██ ██ ██   ██     ██   ████  ██████  ██████  ███████

________________________________________________________________________________________________________________________________________


███████  ██████  ██████      ██   ██ ███████ ███████ ██████      ██ ████████     ████████ ██████   █████  ██████  ██ ███    ██  ██████  
██      ██    ██ ██   ██     ██  ██  ██      ██      ██   ██     ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ████   ██ ██       
█████   ██    ██ ██████      █████   █████   █████   ██████      ██    ██           ██    ██████  ███████ ██   ██ ██ ██ ██  ██ ██   ███ 
██      ██    ██ ██   ██     ██  ██  ██      ██      ██          ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ██  ██ ██ ██    ██ 
██       ██████  ██   ██     ██   ██ ███████ ███████ ██          ██    ██           ██    ██   ██ ██   ██ ██████  ██ ██   ████  ██████  
                                                                                                                                         
                                                                                                                                         
 ██  ██████  ██       █████  ███    ██ ██████   █████  ███    ██ ████████ ███████                                                         
██  ██        ██     ██   ██ ████   ██ ██   ██ ██   ██ ████   ██    ██    ██                                                             
██  ██        ██     ███████ ██ ██  ██ ██   ██ ███████ ██ ██  ██    ██    █████                                                          
██  ██        ██     ██   ██ ██  ██ ██ ██   ██ ██   ██ ██  ██ ██    ██    ██                                                             
 ██  ██████  ██      ██   ██ ██   ████ ██████  ██   ██ ██   ████    ██    ███████

Donate: 0x0004230c13c3890F34Bb9C9683b91f539E809000
EOF
echo -e "${NC}"

function install_node {
    echo -e "${BLUE}Обновляем сервер...${NC}"
    sudo apt-get update -y && sudo apt upgrade -y && sudo apt install -y curl git jq lz4 build-essential unzip ca-certificates gnupg lsb-release

    echo -e "${BLUE}Устанавливаем Docker...${NC}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker
    echo -e "${YELLOW}Перезагрузите текущую сессию или выполните команду 'newgrp docker', чтобы изменения вступили в силу.${NC}"

    echo -e "${BLUE}Создаем директорию для ноды Elixir...${NC}"
    mkdir -p /root/elixir && cd /root/elixir

    echo -e "${BLUE}Загружаем конфигурационный файл...${NC}"
    wget https://files.elixir.finance/validator.env

    echo -e "${YELLOW}Заполняем конфигурационный файл...${NC}"
    read -p "Введите окружение (prod или testnet-3): " ENV
    read -p "Введите IP-адрес сервера: " STRATEGY_EXECUTOR_IP_ADDRESS
    read -p "Введите имя валидатора: " STRATEGY_EXECUTOR_DISPLAY_NAME
    read -p "Введите адрес кошелька для вознаграждений: " STRATEGY_EXECUTOR_BENEFICIARY
    read -p "Введите приватный ключ (без '0x'): " SIGNER_PRIVATE_KEY

    cat << EOF > validator.env
ENV=$ENV
STRATEGY_EXECUTOR_IP_ADDRESS=$STRATEGY_EXECUTOR_IP_ADDRESS
STRATEGY_EXECUTOR_DISPLAY_NAME=$STRATEGY_EXECUTOR_DISPLAY_NAME
STRATEGY_EXECUTOR_BENEFICIARY=$STRATEGY_EXECUTOR_BENEFICIARY
SIGNER_PRIVATE_KEY=$SIGNER_PRIVATE_KEY
EOF

    echo -e "${BLUE}Загружаем Docker-образ валидатора...${NC}"
    docker pull elixirprotocol/validator:v3

    echo -e "${BLUE}Запускаем ноду Elixir...${NC}"
    docker run -d --env-file /root/elixir/validator.env --name elixir --platform linux/amd64 elixirprotocol/validator:v3

    echo -e "${GREEN}Нода Elixir успешно установлена и запущена!${NC}"
}

function restart_node {
    echo -e "${BLUE}Перезапускаем Docker контейнер...${NC}"
    docker restart elixir
}

function view_logs {
    echo -e "${YELLOW}Просмотр логов (выход из логов CTRL+C)...${NC}"
    docker logs -f elixir --tail=50
}

function change_port {
    echo -e "${YELLOW}Введите новый порт: ${NC}"
    read new_port
    if [ -f "/root/elixir/validator.env" ]; then
        sed -i "s/EXISTING_PORT_VARIABLE=.*/EXISTING_PORT_VARIABLE=$new_port/" /root/elixir/validator.env
        echo -e "${BLUE}Перезапускаем контейнер с новым портом...${NC}"
        docker restart elixir
        echo -e "${GREEN}Порт успешно изменен на $new_port и контейнер перезапущен.${NC}"
    else
        echo -e "${RED}Файл конфигурации validator.env не найден.${NC}"
    fi
}

function remove_node {
    echo -e "${BLUE}Удаляем Docker контейнер и директорию...${NC}"
    docker stop elixir && docker rm elixir --force 2>/dev/null || echo -e "${RED}Контейнер elixir не найден.${NC}"
    if [ -d "/root/elixir" ]; then
        rm -rf /root/elixir
        echo -e "${GREEN}Нода успешно удалена.${NC}"
    else
        echo -e "${RED}Директория elixir не найдена.${NC}"
    fi
}

function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установка ноды${NC}"
        echo -e "${CYAN}2. Рестарт ноды${NC}"
        echo -e "${CYAN}3. Просмотр логов${NC}"
        echo -e "${CYAN}4. Изменить порт${NC}"
        echo -e "${CYAN}5. Удаление ноды${NC}"
        echo -e "${CYAN}6. Выход${NC}"
       
        echo -e "${YELLOW}Введите номер действия:${NC} "
        read choice
        case $choice in
            1) install_node ;;
            2) restart_node ;;
            3) view_logs ;;
            4) change_port ;;
            5) remove_node ;;
            6) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
    done
}

main_menu
