#!/bin/sh

#=============================================================#

#Define Variables For Saving Dotfiles and Folders to Git Repo
dot_array=(".zshrc" ".zshenv" ".zprofile" ".xinitrc")
suckless_array=("dwm" "st" "dmenu" "dwmblocks")

de_folder="$HOME/desktop_setup"
suckless_folder="${de_folder}/suckless"
suckless_folder="${de_folder}/suckless"
base_folder="${de_folder}/$(basename $(pwd))"
config_folder="${de_folder}/$(basename $(pwd))/config"
script_folder="${de_folder}/$(basename $(pwd))/scripts"

#=============================================================#

#Making sure we have relevant folders for Organisation
if [ -d "${de_folder}" ]; then
    echo "desktop env folder already exists"
else
    mkdir $de_folder
    echo "desktop env folder created"
fi

if [ -d "${suckless_folder}" ]; then
    echo "suckless folder already exists"
else
    mkdir $suckless_folder
    echo "suckless folder created"
fi

function copy_local {
    echo "Copying Local System Configuration Git Repo"
    echo "==========================================="
    #Looping Through Dotfile Array
    for file in "${dot_array[@]}"; do
        if [ -f $HOME/${file} ]; then 
            echo "Saving dotfile ${file}"
            cp $HOME/${file} ${config_folder}/dotfiles/${file}
        fi
    done

    echo "------------------------------------------"

    #Looping Through Config Array
    for folder in "$HOME/.config"/*; do
        if [ -d "$folder" ] && [ "$(basename $folder)" != "dotfiles" ]; then 
            echo "Saving config $(basename $folder)"
            cp -r $folder ${config_folder}
        fi 
    done

    echo "------------------------------------------"

    #Looping Through Scripts 
    for file in "$HOME/.local/bin"/*; do
        if [ -f $file ]; then
            echo "Saving script $(basename $file)"
            cp $file ${script_folder}
        fi 
    done

    echo "------------------------------------------"

    #Saving Fonts
    echo "Saving Fonts"
    cp -r $HOME/.local/share/fonts $base_folder

    #Saving Crontabs
    #crontab -l > ${script_folder}/filip_crontab
}

function deploy_config {
    echo "Deploying Git Repo Config to Local System"
    echo "========================================="
    #Looping Through Git Dotfiles
    for file in "${dot_array[@]}"; do
        if [ -f ${config_folder}/dotfiles/${file} ]; then 
            echo "Deploying dotfile $file"
            cp  ${config_folder}/dotfiles/${file} $HOME/$file
        fi
    done

    echo "------------------------------------------"

    #Looping Through Git Configs 
    for folder in "${config_folder}"/*; do
        if [ -d "$folder" ] && [ $(basename $folder) != "dotfiles" ]; then 
            echo "Deploying config $(basename $folder)"
            cp -r $folder $HOME/.config
        fi 
    done

    echo "------------------------------------------"

    #Looping Through Scripts 
    for file in "${script_folder}"/*; do
        if [ -f $file ]; then
            echo "Deploying script $(basename $file)"
            cp $file $HOME/.local/bin
        fi 
    done

    #-----
    #Deploying Crontabs -- TO DO
    #-----
}

function program_install {
    csv_file="${de_folder}/$(basename $(pwd))/programs.csv"
    declare -a program_array
    declare -a pArray

    while IFS= read -ra line; do
        program_array+=("$(echo "$line" | tr ',' ' ')")
    done < "$csv_file"

    for program in "${program_array[@]}"; do
        pArray+=$program
    done

    echo "Run System Update - Enter PW"
    #sudo pacman -Syu
    echo "The following programs are going to be installed:"
    echo $pArray
    sudo pacman -S $pArray

    echo "Installing Image Previewer ctpv from github"
    cd $de_folder
    git clone https://github.com/NikitaIvanovV/ctpv
    cd $de_folder/ctpv
    make
    sudo make install
}

function suckless_install {
    echo "Suckless Install Procedure"
    echo "=========================="

    for program in "${suckless_array[@]}"; do
        cd $suckless_folder
                                                           
        if [ -d "${suckless_folder}/${program}" ]; then
            echo "${program} - already exists"
        else
            echo "${program} - does not exist - cloning from repo"
            git clone https://github.com/Filpill/${program}.git
            cd ${suckless_folder}/${program}
            git remote set-url origin git@github.com:Filpill/${program}.git
            sudo make clean install
        fi
    done
}

function git_push {
    echo "Pushing Config and Script Update to Github"
    echo "=========================================="

    git add .
    msg="updating config files `date`"
    if [ $# -eq 1 ]
        then msg="$1"
    fi
    git commit -m "$msg"
    git push origin main
}

#-------------Script Starts Here------------------
# Hashmap to define what options this script can execute
declare -A actions=(
    [1]="1 - Copy Local System Configuration to Git" 
    [2]="2 - Deploy Repository Config to Local System" 
    [3]="3 - Install Required Arch Linux Programs"
    [4]="4 - Clone and Install Suckless Programs: dwm | st | dmenu | dwmblocks"
    [5]="5 - Push Changes to Git Repository"
)
keys_sorted=($(echo ${!actions[@]} | tr ' ' '\n' | sort -n))

# Run the selected function defined in the script
while true; do
    echo "=============================================="
    echo "Please Select An Action (Enter Integer Value):"
    echo "=============================================="
    for key in "${keys_sorted[@]}"; do
        echo "  ${actions[$key]}"
    done
    read num
    case $num in
        1) copy_local ;;
        2) deploy_config ;;
        3) program_install ;;
        4) suckless_install  ;;
        5) git_push ;;
        *) 
            clear
            echo "-------------------------------------------------"
            echo "---  Invalid Selection - Enter Value on List  ---"
            echo "-------------------------------------------------
            "
            continue ;;
    esac
    break
done
