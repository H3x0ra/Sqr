#!/bin/bash

# Function to display the welcome banner
function display_banner() {
    echo -e "
  --------      ------    ------------ --------    ********   
 **********    ********   ************ ********   ----------  
----    ----  ----------  ----           ----    ************ 
***      *** ****    **** ************   ****    ---  --  --- 
---   --  -- ------------ ------------   ----    ***  **  *** 
****   ** ** ************        *****   ****    ---  --  --- 
 ------ -- - ----    ---- ------------ --------  ***  **  *** 
  ******* ** ****    **** ************ ********  ---      --- 
        --------------------------------------------------
        WELCOME TO BASH SCANNER TOOL
        Network & Port Scanning Utility
        Created by: H3x0ra Qasim Tawalbeh
        --------------------------------------------------  
    "
    echo
}

# Function to check for required dependencies
dependency_check() {
    for cmd in nc ping; do
        if ! command -v $cmd &>/dev/null; then
            echo "[ERROR] Required command '$cmd' not found. Please install it."
            exit 1
        fi
    done
}

# Function to get the host's IP address
get_host_ip() {
    hostname -I | awk '{print $1}'  # Extract the first IP address
}

# Function for Network Discovery
network_discovery() {
    echo "Do you want to scan:"
    echo "1. Your network"
    echo "2. Another network"
    read -p "Enter your choice (1 or 2): " choice

    case "$choice" in
        1)
            host_ip=$(get_host_ip)
            network_prefix=$(echo $host_ip | cut -d '.' -f 1-3)
            echo "Detected host IP: $host_ip"
            echo "Scanning the network ${network_prefix}.0/24..."
            ;;
        2)
            read -p "Enter the network prefix to scan (e.g., 192.168.1): " network_prefix
            echo "Scanning the network ${network_prefix}.0/24..."
            ;;
        *)
            echo "Invalid choice. Returning to the main menu."
            return
            ;;
    esac

    for i in {1..254}; do
        {
            if ping -c 1 -W 1 ${network_prefix}.$i &>/dev/null; then
                echo "Discovered IP: ${network_prefix}.$i"
            fi
        } &
        [[ $(jobs -r -p | wc -l) -ge 50 ]] && wait  # Limit concurrent processes
    done
    wait
    echo -e "\e[34m[INFO] Network discovery complete!\e[0m"
}

# Function to scan ports for a specific host
port_scanning() {
    echo "Do you want to scan:"
    echo "1. Your host IP"
    echo "2. Another host IP"
    read -p "Enter your choice (1 or 2): " choice

    case "$choice" in
        1)
            host=$(get_host_ip)
            echo "Detected host IP: $host"
            ;;
        2)
            read -p "Enter the host IP or domain to scan: " host
            ;;
        *)
            echo "Invalid choice. Returning to the main menu."
            return
            ;;
    esac

    echo -e "\e[34mChoose scan option:\e[0m"
    echo -e "\e[34m1. Scan all ports (1-65535)\e[0m"
    echo -e "\e[34m2. Scan specific ports\e[0m"
    echo -e "\e[34m0. Exit\e[0m"
    read -p "Enter your choice (1, 2, or 0 to exit): " scan_choice

    case "$scan_choice" in
        1)
            echo "Scanning all ports on $host..."
            for port in {1..65535}; do
                {
                    if nc -zv -w 1 $host $port &>/dev/null; then
                        echo -e "\e[32mPort $port is open.\e[0m"
                    fi
                } &
                [[ $(jobs -r -p | wc -l) -ge 50 ]] && wait  # Limit concurrent processes
            done
            wait
            echo -e "\e[34m[INFO] Port scanning complete!\e[0m"
            ;;
        2)
            read -p "Enter the port(s) to scan (e.g., 22, 80 or 0-80 for range): " input
            if [[ $input =~ ^[0-9]+-[0-9]+$ ]]; then
                IFS='-' read -r start_port end_port <<< "$input"
                for port in $(seq $start_port $end_port); do
                    if nc -zv -w 1 $host $port &>/dev/null; then
                        echo -e "\e[32mPort $port is open.\e[0m"
                    else
                        echo -e "\e[31mPort $port is closed.\e[0m"
                    fi
                done
            elif [[ $input =~ ^[0-9]+$ ]]; then
                if nc -zv -w 1 $host $input &>/dev/null; then
                    echo -e "\e[32mPort $input is open.\e[0m"
                else
                    echo -e "\e[31mPort $input is closed.\e[0m"
                fi
            else
                echo "Invalid input. Please enter a single port or a valid range (e.g., 0-80)."
            fi
            ;;
        0)
            echo "Exiting the tool. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Returning to the main menu."
            ;;
    esac
}

# Main execution
clear
dependency_check
display_banner

while true; do
    echo -e "\e[34mChoose an option:\e[0m"
    echo -e "\e[34m1. Network Discovery\e[0m"
    echo -e "\e[34m2. Port Scanning\e[0m"
    echo -e "\e[34m0. Exit\e[0m"
    read -p "Enter your choice (1, 2, or 0 to exit): " choice

    case "$choice" in
        1) network_discovery ;;
        2) port_scanning ;;
        0)
            echo "Exiting the tool. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac
done
