#!/bin/bash

# Function to gracefully handle repository operations (clone or link existing)
init_repository() {
    local repo_name="$1"
    local repo_url="$2"
    if [ -d "$repo_name" ]; then
        # 使用绿色字体显示已存在目录的提示信息
        echo -e "\033[32mThe '$repo_name' directory already exists. Skipping clone operation.\033[0m"
    else
        read -p "Do you have an existing local '$repo_name' repository? (y/n) " choice
        case "$choice" in
            [Yy])
                read -p "Please enter the path of the existing '$repo_name' repository: " repo_path
                ln -s "$repo_path" "$repo_name"
                ;;
            [Nn])
                git clone "$repo_url"
                ;;
            *)
                echo -e "\033[31mInvalid input. Please enter 'y' or 'n'.\033[0m"
                init_repository "$repo_name" "$repo_url"
                ;;
        esac
    fi
    # todo: next line???
    echo -e "\033[34mRepository initialization for '$repo_name' is finished.\033[0m"
}

# Handle 'hvisor' repository
init_repository "hvisor" "https://github.com/syswonder/hvisor"

# Handle 'hvisor-tool' repository
init_repository "hvisor-tool" "https://github.com/syswonder/hvisor-tool"
