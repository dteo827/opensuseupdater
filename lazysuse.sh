#!/bin/bash
# OpenSUSE Configuration and Updater version 2.0
# Optimized for OpenSUSE 11.3
# Please contact dteo827@gmail.com with bugs or feature requests

""
"Computer info: \nVersion:" >> changes
lsb_release -r >> changes
uname -r >> changes
date >> changes
dpkg -l >> changes

clear
version="2.0"
#some variables
DEFAULT_ROUTE=$(ip route show default | awk '/default/ {print $3}')
IFACE=$(ip route show | awk '(NR == 2) {print $3}')
JAVA_VERSION=`java -version 2>&1 |awk 'NR==1{ gsub(/"/,""); print $3 }'`
MYIP=$(ip route show | awk '(NR == 2) {print $9}')

if [ $UID -ne 0 ]; then
    echo -e "\033[31This program must be run as root.This will probably fail.\033[m"
    sleep 3
    fi

###### Install script if not installed
if [ ! -e "/usr/bin/lazysuse" ];then
        echo "Script is not installed. Do you want to install it ? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
                cp -v $0 /usr/bin/lazysuse
                chmod +x /usr/bin/lazysuse
                #rm $0
                echo "Script should now be installed. Launching it !"
                sleep 3
                lazysuse
                exit 1
        else
                echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi
else
        echo "Script is installed"
        sleep 1
fi
### End of install process

#### pause function
function pause(){
   read -sn 1 -p "Press any key to continue..."
}

#### credits
function credits {
clear
echo -e "
\033[31m#######################################################\033[m
                       Credits To
\033[31m#######################################################\033[m"
echo -e "\033[36m
David Teo For Making the script.
Pashapasta for the idea and version 1.0
lazykali.sh for UI 
Adam Shuman for mysql stuff

and anyone else I may have missed.
#vi /etc/apache/sites-enabled

#directory - > /var/www | change to index.php

#/public_htm

\033[m"
}

#### Screwup function
function screwup {
        echo "You Screwed up somewhere, try again."
        pause 
        clear
}

######## Update OpenSuse
function answerUpdate {
        echo "This will fully update OpenSUSE, this will take a while. Do you want to do this? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
                echo -e "\e[31m[+] Updating OpenSUSE now! \nHope you have some time to burn... \e[0m"
                zypper ar -f http://ftp5.gwdg.de/pub/opensuse/discontinued/distribution/11.3/repo/non-oss/ non_oss
                zypper ar -f http://ftp5.gwdg.de/pub/opensuse/discontinued/distribution/11.3/repo/oss oss
                sudo zypper refresh
                sudo zypper up
                sudo zypper install cups
                echo "Fully Updated OpenSUSE release, this task was completed at: " $(date) >> changes
                echo -e "\e[32m[-] Done Updating!\e[0m"           
        else
                echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi

}
#############################
#    Hardening Scripts      #
#############################
######## resetMysql 
function disableAccounts {
        echo "This will disable login on all accounts except the ones made during/after install. Do you want to do this? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
                echo -e "\e[31m[+] Resetting now!\e[0m"
                passwd at -l
                passwd avahi -l
                passwd bin -l
                passwd daemon -l
                passwd dnsmasq -l
                passwd ftp -l
                passwd games -l
                passwd gdm -l
                passwd haldaemon -l
                passwd lp -l
                passwd mail -l
                passwd man -l
                passwd messagebus -l
                passwd news -l
                passwd nobody -l
                passwd ntp -l
                passwd polkituser -l
                passwd postfix -l
                passwd pulse -l
                passwd rtkit -l
                passwd sshd -l
                passwd suse-ncc -l
                passwd uucp -l
                passwd wwwrun -l
                echo "All accounts disabled, this task was completed at: " $(date) >> changes
                echo -e "\e[32m[-] Done disabling accounts !\e[0m"           
        else
                echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi        
}

##### Download and compile Grsecurity
function grsecurity {
        echo "This will install Grsecurity. Do you want to do this? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
            #download kernel 
            wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.14.37.tar.xz --no-check-certificate

            #unzip and change directories
            tar -xf linux-3.14.37.tar.xz
            cd linux-3.14.37

            #download grsec and gradm inside kernel directory
            wget https://grsecurity.net/stable/grsecurity-3.1-3.14.37-201504051405.patch --no-check-certificate
            wget https://grsecurity.net/stable/gradm-3.1-201503211320.tar.gz --no-check-certificate
            tar -zxvf gradm-3.1-201503211320.tar.g
            #patch kernel
            sudo zypper install patch
            sudo zypper install make
            sudo zypper install gcc
            sudo zypper install ncurses-devel

            patch -p1make <grsecurity-3.1-3.14.37-201504051405.patch
            make menuconfig
            make rpm
            cd /usr/src/packages/RPMS/i386/
            rpm -ivh kernel-3.14.37_0.6_desktop-1.i386.rpm
            mkinitrd
            # Add kernel entry to boot menu
            echo -e "
            \033[31m#######################################################\033[m
                        DOUBLE CHECK mkinitrd ADD TO /boot/grub/menu.lst
            \033[31m#######################################################\033[m"
            echo "OpenSuse 11.3 With Grsecurity 3.14.37-0.6" >> /boot/grub/menu.lst
            #echo "     root (hd0,1)" >> /boot/grub/menu.lst
            #echo "     kernel /boot/vmlinuz-3.14.37-0.6-desktop root=/dev/sda2 resume=/dev/disk/by-id/ata-OpenSUSE_11.3-0_SSD_JNKM3MF2V3Z4DFYXB0EX-part2 resume=/dev/disk/by-id/ata-OpenSUSE_11.3-0_SSD_JNKM3MF2V3Z4DFYXB0EX-part1 splash=silent crashkernel=256M-:128M showopts vga=0x339" >> /boot/grub/menu.lst            
            #echo "     initrd /boot/initrd-3.14.37-0.6-desktop" >> /boot/grub/menu.lst
            
        else
             echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi   

}

######## resetMysql 
function resetMysql {
        echo "This will reset the mysql password. Do you want to do this? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
                echo -e "\e[31m[+] Resetting now!\e[0m"
                kill `ps aux | grep mysqld`
                read -p "What would you like the password to be? " password
                sudo echo UPDATE mysql.user SET Password='$password' WHERE User='root';'\n'FLUSH PRIVILEGES;'\n'quit; >> /root/mysql-init
                mysqld_safe --init-file=/root/mysql-init
                rm /home/root/mysql-init
                /etc/init.d/mysql restart
                echo "Reset mySQL Password, this task was completed at: " $(date) >> changes
                echo -e "\e[32m[-] Done resetting mysql !\e[0m"           
        else
                echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi        
}

######## Fix Shellshock
function answerShellshock {
        echo "This will fix shellshock. Do you want to do this ? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
                echo -e "\e[31m[+] Installing PROGRAM now!\e[0m"
                cd /src
                wget http://ftp.gnu.org/gnu/bash/bash-4.3.tar.gz
                #download all patches
                for i in $(seq -f "%03g" 1 28); do wget http://ftp.gnu.org/gnu/bash/bash-4.3-patches/bash43-$i; done
                tar zxvf bash-4.3.tar.gz
                cd bash-4.3
                #apply all patches
                for i in $(seq -f "%03g" 1 28);do patch -p0 < ../bash43-$i; done
                #build and install
                ./configure --prefix=/ && make && make install
                cd ../../
                rm -r src
                echo "Fixed Shellshock vulnerability, this task was completed at: " $(date) >> changes
                echo -e "\e[32m[-] Shellshock fixed !\e[0m"           
        else
                echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi        
}

#### HardeningScripts
function answerHardeningScripts {
clear
echo -e "
\033[31m#######################################################\033[m
                Hardening Scripts
\033[31m#######################################################\033[m"

select menusel in "Grsecurity" "mySQL" "Shellshock" "Disable all other Accounts" "Install All" "Back to Main"; do
case $menusel in
        "Grsecurity")
                grsecurity
                pause
                answerHardeningScripts ;;
        "mySQL")
                resetMysql
                pause
                answerHardeningScripts ;;
                
        "Shellshock")
                answerShellshock
                pause
                answerHardeningScripts ;;

        "Disable all other Accounts")
                disableAccounts
                pause
                answerHardeningScripts ;;

        "Install All")
                echo -e "\e[31m[+] Installing Extra's\e[0m"
                answerMysql
                answershellshock
                disableAccounts
                echo -e "\e[32m[-] Done Installing Extra's\e[0m"
                pause
                answerHardeningScripts ;;         

        "Back to Main")
                clear
                mainmenu ;;
                
        *)
                screwup
                answerHardeningScripts ;;
               
esac

break

done
}

##########################################
#           Defense Programs             #
##########################################

######## Install OSSEC
function answerOSSEC {
        echo "This is not yet implemented"
        #echo "This will install OSSEC. Do you want to install it ? (Y/N)"
        #read install
        #if [[ $install = Y || $install = y ]] ; then
        #        echo -e "\e[31m[+] Installing OSSEC now!\e[0m"
        #        cd /tmp
        #        
        #        echo -e "\e[32m[-] Done Installing OSSEC!\e[0m"           
        #else
        #        echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        #fi        
}

######## Install Nessus
function answerNessus {
        echo "This will install Nessus. Do you want to install it ? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
                echo -e "\e[31m[+] Installing Nessus now!\e[0m"
                cd /tmp
                wget http://downloads.nessus.org/nessus3dl.php?file=Nessus-6.3.3-suse11.i586.rpm&licence_accept=yes&t=3cc0e52131cd121bbda2ee0190a4f224 --
                echo "Installed Nessus, this task was completed at: " $(date) >> changes
                echo -e "\e[32m[-] Done Installing Nessus!\e[0m"           
        else
                echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi        
}

######## Install Nmap
function answerNmap {
        echo "This will install Nmap. Do you want to install it ? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
                echo -e "\e[31m[+] Installing Nmap now!\e[0m"
                cd /tmp
                zypper install nmap
                echo "Installed Nmap, this task was completed at: " $(date) >> changes
                echo -e "\e[32m[-] Done Installing Nmap!\e[0m"           
        else
                echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi        
}


######## Install Artillery
function answerArtillery {
        echo "This will install Artillery. Do you want to install it ? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
                echo -e "\e[31m[+] Installing Artillery now!\e[0m"
                cd /tmp
                git clone git://github.com/trustedsec/artillery
                cd artillery
                ./setup.py
                echo "Installed Artillery, this task was completed at: " $(date) >> changes
                echo -e "\e[32m[-] Done Installing Artillery!\e[0m"           
        else
                echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi        
}


######## Install Nikto
function answerNikto {
        echo "This will install Nikto. Do you want to install it ? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
                echo -e "\e[31m[+] Installing Nikto now!\e[0m"
                cd /tmp
                wget https://github.com/sullo/nikto/archive/master.zip --no-check-certificate
                unzip nikto-master.zip
                cd nikto-master
                cd program
                chmod a+x nikto.pl 
                chmod 777 nikto.pl
                ./nikto.pl -host localhost
                echo "Installed Nikto, this task was completed at: " $(date) >> changes
                echo -e "\e[32m[-] Done Installing Nikto!\e[0m"           
        else
                echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi        
}

######## Install Fail2ban
function answerFail2ban {
        echo "This will install Fail2ban . Do you want to install it ? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
                echo -e "\e[31m[+] Installing Fail2ban now!\e[0m"
                cd /tmp
                zypper ar -f -n packman http://packman.inode.at/suse/openSUSE_11.3/ packman
                sudo yast2 -i fail2ban 
                sudo chkconfig --add fail2ban 
                sudo /etc/init.d/fail2ban start
                /etc/init.d/fail2ban start
                echo "Installed Fail2ban, this task was completed at: " $(date) >> changes
                echo -e "\e[32m[-] Done Installing Fail2ban!\e[0m"           
        else
                echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi        
}


######## Install Lynis
function answerLynis {
        echo "This will install Lynis. Do you want to install it ? (Y/N)"
        read install
        if [[ $install = Y || $install = y ]] ; then
                echo -e "\e[31m[+] Installing Lynis now!\e[0m"
                cd /tmp
                wget https://cisofy.com/files/lynis-2.0.0.tar.gz -O lynis.tar.gz --no-check-certificate
                tar -zxvf lynis.tar.gz
                cd lynis
                sudo chmod 777 lynis
                sudo chmod a+x lynis
                chown root ./inculde/consts
                chown root ./inculde/functions
                chgrp root ./inculde/osdetection
                chown root ./inculde/profiles
                chgrp root ./inculde/binaries
                sudo ./lynis -q audit system --log-file /home/lynis_output
                cd /home/Downloads
                echo "Installed Lynis, this task was completed at: " $(date) >> changes
                echo -e "\e[32m[-] Done Installing Lynis!\e[0m"           
        else
                echo -e "\e[32m[-] Ok,maybe later !\e[0m"
        fi        
}

function answerDefense {
clear
echo -e "
\033[31m#######################################################\033[m
                Install Defense Programs
\033[31m#######################################################\033[m"

select menusel in "Lynis" "Fail2ban" "Nikto" "Nmap" "Nessus" "OSSEC" "Artillery" "Install All" "Back to Main"; do
case $menusel in
        "Lynis")
                answerLynis
                pause 
                answerDefense;;
                
        "Fail2ban")
                answerFail2ban
                pause
                answerDefense;;
                
        "Nikto")
                answerNikto
                pause 
                answerDefense;;
                
        "Nmap")
                answerNmap
                pause 
                answerDefense;;
                
        "Nessus")
                answerNessus
                pause 
                answerDefense;;
                
        "OSSEC")
                answerOSSEC
                pause 
                answerDefense;;
                                
        "Artillery")
                answerArtillery
                pause 
                answerDefense ;;
                
        "Install All")
                echo -e "\e[31m[+] Installing Extra's\e[0m"
                answerLynis
                answerFail2ban
                answerNikto
                answerNmap
                answerNessus
                answerOSSEC
                answerArtillery
                echo -e "\e[32m[-] Done Installing Extra's\e[0m"
                pause
                answerDefense ;;         

        "Back to Main")
                clear
                mainmenu ;;
                
        *)
                screwup
                answerDefense ;;
        
                
esac

break

done
}

########################################################
##             Main Menu Section
########################################################
function mainmenu {
echo -e "
\033[31m################################################################\033[m
\033[1;36m
.____                          .____        .____  .____
|    |   _____  ___________.__.|      |    ||      |
|    |   \__  \ \___   <   |  ||____. |    ||____. |____
|    |___ / __ \_/    / \___  |     | |    |     | |
|_______ (____  /_____ \/ ____| ____| |____| ____| |____
        \/    \/      \/\/                          

\033[m                                        
                   Script by dteo827
                    version : \033[32m$version\033[m
Script Location : \033[32m$0\033[m
Connection Info :-----------------------------------------------
  Gateway: \033[32m$DEFAULT_ROUTE\033[m Interface: \033[32m$IFACE\033[m My LAN Ip: \033[32m$MYIP\033[m
\033[31m################################################################\033[m"

select menusel in "Update SUSE" "Hardening Scripts" "Defense Programs" "HELP!" "Credits" "EXIT PROGRAM"; do
case $menusel in
        "Update SUSE")
                answerUpdate
                clear ;;
        
        "Hardening Scripts")
                answerHardeningScripts
                clear ;;
                        
        "Defense Programs")
                answerDefense
                clear ;;
        
        "HELP!")
                echo "What do you need help for, seems pretty simple!"
                pause
                clear ;;
                
        "Credits")
                credits
                pause
                clear ;;

        "EXIT PROGRAM")
                clear && exit 0 ;;
                
        * )
                screwup
                clear ;;
esac

break

done
}

while true; do mainmenu; done
