#!/bin/bash

# Config Script for Chip PC ThinX OS v1.8
# Version validated for ThinX OS v2.0.1, 2.0.2, 2.0.3 and 1.1.4
# By Romain DUCHENE, rduchene@chippc.com

# Configurable variable
CONFIGFILE="/xcalibur/deployment/scripts/config.ini"
SCRIPTPATH="/xcalibur/deployment/scripts"

# Do not modify below
INTERFACEFILENAME="/etc/network/interfaces"
RESOLVFILENAME="/etc/resolv.conf"
NETWORKRESTART="/etc/init.d/networking restart"
MODEL_FILE="/etc/chippc/registry/lm/software/chippc/xtreme/info/model"
VERSION_FILE="/etc/chippc/registry/lm/software/chippc/xtreme/info/softverssion"
#PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/lib/chippc/scripts"

if [ -e $CONFIGFILE ];
then
# Reading configuration
  . ${SCRIPTPATH}/lib/read_ini.sh
  read_ini $CONFIGFILE

# Checking Device model
DEVICE_MODEL=
FIRMWARE_VERSION=

if grep -a "8" ${MODEL_FILE} > /dev/null
then
	DEVICE_MODEL="8xxx"
	FIRMWARE_VERSION=201
fi
if grep -a "2" ${MODEL_FILE} > /dev/null
then
	DEVICE_MODEL="2xxx"
	FIRMWARE_VERSION=114
fi
echo "Device model: ${DEVICE_MODEL}"

# Checking Firmware version
if diff ${SCRIPTPATH}/data/fwversion/softverssion-1.1.4 ${VERSION_FILE} >/dev/null
then
	FIRMWARE_VERSION=114
fi
if diff ${SCRIPTPATH}/data/fwversion/softverssion-2.0.1 ${VERSION_FILE} >/dev/null
then
	FIRMWARE_VERSION=201
fi
if diff ${SCRIPTPATH}/data/fwversion/softverssion-2.0.2 ${VERSION_FILE} >/dev/null
then
	FIRMWARE_VERSION=202
fi
if diff ${SCRIPTPATH}/data/fwversion/softverssion-2.0.3 ${VERSION_FILE} >/dev/null
then
	FIRMWARE_VERSION=203
fi
echo "Firmware version: ${FIRMWARE_VERSION}"

# ############################################
# VIDEO SETTINGS
# ############################################
# Video Resolution (format: 1024x768, 1280x1024, 1920x1080) / TODO
if [ ${INI__video__resolution} ]
  then
    echo "video resolution to set: ${INI__video__resolution}"
  fi

# Video Color (format: 16,32) / TODO
  if [ ${INI__video__color} ]
  then
    echo "video color to set: ${INI__video__color}"
  fi

# Video DDC (format: 1 to enable, 0 to do nothing)
  if [ "${INI__video__ddc}" == "1" ] ;
  then
    echo "Enabling DDC"
    eval 'rm -f /usr/lib/X11/xorg.conf.d/10-xorgscreen.conf'
    eval "cp ${SCRIPTPATH}/data/0000001b-ddc-enable /etc/chippc/registry/lm/chippcpolicy70/00000065/0000001b"
  fi

# ############################################
# SYSTEM SETTINGS
# ############################################
# Shutdown Time (format: HH:MM)
  if [ ${INI__system__shutdownTime} ]
  then
    echo "Shutdown time: ${INI__system__shutdownTime}"
    eval "shutdown -h ${INI__system__shutdownTime}&"
  fi
  
# Reboot Time (format: HH:MM)
  if [ ${INI__system__rebootTime} ]
  then
    echo "Reboot time: ${INI__system__rebootTime}"
    eval "shutdown -r ${INI__system__rebootTime}&"
  fi

# Mac Host Config File (format: filename or false)
  if [ ${INI__system__macConfigFile} ]
  then
    # getting MAC address
    MAC=$(cat /sys/class/net/eth0/address | sed -e 's/://g')
    echo "MAC Address: $MAC"
  
    # update hostname with file
    HOST=$(grep -i $MAC ${INI__system__macConfigFile} | cut -d ' ' -f 2 | tr -d '\n')
    if [ "$HOST" != "" ] ;
    then
      # Checking if hostname is new or not
      if [ $(hostname) != $HOST ];
      then
        echo "Hostname to update: $HOST"
        echo $HOST > /etc/hostname
        hostname $HOST
        echo "Updated !"
      else
        echo "No change in hostname"
      fi
    else
      echo "No hostname found for this MAC !"
    fi
  
    # update IP configuration
    IPADDRESS=$(grep -i $MAC ${INI__system__macConfigFile} | cut -d ' ' -f 3 | tr -d '\n' | tr -d '\r')
    if [ "$IPADDRESS" != "" ] ;
    then
      echo "IP Address : $IPADDRESS"
      if [ $IPADDRESS = "dhcp" ] ;
      then
        # It's a DHCP config to apply
        ACTUALIPTYPE=$(grep -i "iface eth0 inet" $INTERFACEFILENAME | cut -d ' ' -f 4 | tr -d '\n')
        if [ $ACTUALIPTYPE = "dhcp" ] ;
        then
          echo "IP Configuration is already DHCP, no change to apply"
        else
          # We need to update the interfaces configuration file to be DHCP
          echo "auto lo" > $INTERFACEFILENAME
          echo "iface lo inet loopback" >> $INTERFACEFILENAME
          echo "auto eth0" >> $INTERFACEFILENAME
          echo "iface eth0 inet dhcp" >> $INTERFACEFILENAME
          eval $NETWORKRESTART        
          echo "IP Configuration changed to DHCP"
          HOST_CHANGED="1"
        fi
      else
        # It's a fixed IP address to apply
        # Getting gateway, netmask, dns1, dns2, domainname
        NETMASK=$(grep -i $MAC ${INI__system__macConfigFile} | cut -d ' ' -f 4 | tr -d '\n' | tr -d '\r')
        GATEWAY=$(grep -i $MAC ${INI__system__macConfigFile} | cut -d ' ' -f 5 | tr -d '\n' | tr -d '\r')
        DNS1=$(grep -i $MAC ${INI__system__macConfigFile} | cut -d ' ' -f 6 | tr -d '\n' | tr -d '\r')
        DNS2=$(grep -i $MAC ${INI__system__macConfigFile} | cut -d ' ' -f 7 | tr -d '\n' | tr -d '\r')
        DOMAINNAME=$(grep -i $MAC ${INI__system__macConfigFile} | cut -d ' ' -f 8 | tr -d '\n' | tr -d '\r')

        ACTUALIPADDRESS=$(grep -i "address" $INTERFACEFILENAME | cut -d ' ' -f 2 | tr -d '\n')
        if [ "$ACTUALIPADDRESS" = $IPADDRESS ] ;
        then
          echo "IP is already $IPADDRESS, no change to do"
        else
          # We need to update the interfaces configuration file to be the new IP
          echo "auto lo" > $INTERFACEFILENAME
          echo "iface lo inet loopback" >> $INTERFACEFILENAME
          echo "auto eth0" >> $INTERFACEFILENAME
          echo "iface eth0 inet static" >> $INTERFACEFILENAME
          echo "address $IPADDRESS" >> $INTERFACEFILENAME
          echo "netmask $NETMASK" >> $INTERFACEFILENAME
          echo "gateway $GATEWAY" >> $INTERFACEFILENAME
          # Updating also the DNS file
          echo "nameserver $DNS1" > $RESOLVFILENAME
          echo "nameserver $DNS2" >> $RESOLVFILENAME
          echo "domain $DOMAINNAME" >> $RESOLVFILENAME
          echo "search $DOMAINNAME" >> $RESOLVFILENAME
          echo "IP Configuration updated : IP: $IPADDRESS / Mask: $NETMASK / Gateway: $GATEWAY / DNS: $DNS1/$DNS2 / DOMAIN: $DOMAINNAME"
          eval $NETWORKRESTART
          IP_CHANGED="1"        
        fi
      fi
    else
      echo "No IP Address found for this MAC !"
    fi
  fi

# User Config File / TODO
  if [ ${INI__system__userConfigFile} ]
  then
    echo "User Config File: ${INI__system__userConfigFile}"
  fi

# Updating Time Zone
  if [ ${INI__system__timeZone} ]
  then
    echo "Updating Time Zone to : ${INI__system__timeZone}"
    if [ -e /usr/share/zoneinfo/${INI__system__timeZone} ]
    then
    	eval "mv /etc/localtime /etc/localtime-old"
    	eval "ln -sf /usr/share/zoneinfo/${INI__system__timeZone} /etc/localtime"
    	eval "/sbin/hwclock --systohc"
    	echo "Timezone changed !"
    else
   		echo "Error: Timezone not found !"
    fi
  fi

# /root/NULL fix for RDP Flash issue
  if [ ${INI__system__nullFix} = "1" ]
  then
    echo "Fixing /root/NULL issue: ${INI__system__nullFix}"
    eval "ln -sf /dev/null /root/NULL"    
  fi

# Folder Sync (Generic tool)
  if [ ${INI__system__syncFolder} = "1" ]
  then
    echo "Folder Synchro: ${INI__system__nullFix}"
    if [ -e /root/.script_sync_folder_done ]
    then
      echo "Folder already sync !"
    else
      if [ -e ${SCRIPTPATH}/sync/${DEVICE_MODEL}.tar.gz ]
      then
        # If we have a .tgz file to deploy first...
        echo "Local ${DEVICE_MODEL}.tar.gz Found !"
        eval "tar zxvf ${SCRIPTPATH}/sync/${DEVICE_MODEL}.tar.gz -C /"
      fi
      # We deploy the regular files...
      echo "Sync files..."
      eval "cp -rfv ${SCRIPTPATH}/sync/${DEVICE_MODEL}/* /"
      eval "touch /root/.script_sync_folder_done"
    fi
  fi

# Fix for MS Natural Keyboard on 2xxx only
  if [ ${INI__system__fixMSNatural} = "1" -a ${DEVICE_MODEL} = "2xxx" ]
  then
    echo "Fixing MS Natural Keyboard: ${INI__system__fixMSNatural}"
    if [ -e /root/.script_fix_ms_natural ]
    then
      echo "MS Natural already fixed !"
    else
      # We deploy the files...
      eval "tar zxvf ${SCRIPTPATH}/data/hid_drv_ms_natural.tar.gz -C /"
      eval "depmod -a"
      eval "touch /root/.script_fix_ms_natural"
      echo "MS Natural fix: ok"
    fi
  fi

# Fix for USB Speed on 8xxx only (need to check on 2xxx)
  if [ ${INI__system__fixUSBSpeed} = "1" -a ${DEVICE_MODEL} = "8xxx" ]
  then
    echo "Fixing USB Speed writting: ${INI__system__fixUSBSpeed}"
    if [ -e /root/.script_fix_usb_speed ]
    then
      echo "USB Speed writting already fixed !"
    else
      # We are patching the file
      eval "sed -i -e '/sync,noexec,nodev,noatime,nodiratime/c \
MOUNTOPTIONS=\"async,noexec,nodev,noatime,nodiratime\"' /etc/usbmount/usbmount.conf"
      eval "touch /root/.script_fix_usb_speed"
      echo "USB Speed writting fix: ok"
    fi
  fi

# Modifying DNS search domain (changing DHCP client config file to append search domain)
  if [ ${INI__system__dnsSearchDomain} != "" ]
  then
    DNS_SEARCH_DOMAIN=`echo ${INI__system__dnsSearchDomain} | sed -r 's/;/ /g'`
    echo "Changing DNS Search Domain: ${DNS_SEARCH_DOMAIN}"
#    eval "sed -i -e 's/search/search ${DNS_SEARCH_DOMAIN}/g' /etc/resolv.conf"
    DNS_SEARCH_DOMAIN_DHCP=`echo ${INI__system__dnsSearchDomain} | sed -r 's/;/", "/g'`
    DNS_SEARCH_DOMAIN_DHCP='"'${DNS_SEARCH_DOMAIN_DHCP}'"'
    echo "DHCP Search: ${DNS_SEARCH_DOMAIN_DHCP}";
    echo "append domain-search "${DNS_SEARCH_DOMAIN_DHCP}";">>/etc/dhcp3/dhclient.conf
    echo "Updating DNS Search Domain: ok"
  fi

# ############################################
# GUI SETTINGS
# ############################################

# Theme selection (format: SilverXP, IceClearlooks)
  if [[ ( $INI__gui__theme && $DEVICE_MODEL = "8xxx" && $FIRMWARE_VERSION -eq "201" ) ]]
  then
    case ${INI__gui__theme} in
      "IceClearlooks" ) THEME="IceClearlooks" ;;
      * ) THEME="SilverXP";;
    esac
    echo "Theme: ${INI__gui__theme}"
    echo "Theme=\"$THEME/default.theme\"" > /root/.icewm/theme
  fi

# Language in menu (format: french, german, english)
  if [[ ( $INI__gui__language && ( $FIRMWARE_VERSION -eq "201" || $FIRMWARE_VERSION -eq "114" )) ]]
  then
    case ${INI__gui__language} in
      "french" )
        TXT_REBOOT="Redemarrer"
        TXT_SHUTDOWN="Arreter"
        TXT_LOGOFF="Deconnexion"
        TXT_SETTINGS="Reglages"
        TXT_MYLBT="Ma Configuration"
        TXT_APPLICATIONS="Applications"
        TXT_DEVICE="Terminal"
        TXT_UPGRADE="Mise a jour"
        TXT_CONNECTIONS="Mes Connexions"
        TXT_NEW_X_CONNECTION="Nouvelle Connexion X"
        TXT_NEW_RDP_CONNECTION="Nouvelle Connexion RDP"
        TXT_NEW_FREERDP_CONNECTION="Nouvelle Connexion FreeRDP"
        TXT_NEW_WEB_CONNECTION="Nouvelle Connexion Web";;
      "german" )
        TXT_REBOOT="Neu Starten"
        TXT_SHUTDOWN="Herunterfahren"
        TXT_LOGOFF="Abmelden"
        TXT_SETTINGS="Einstellungen"
        TXT_MYLBT="Meine Einstellungen"
        TXT_APPLICATIONS="Applications"
        TXT_DEVICE="Konfiguration"
        TXT_UPGRADE="Upgrade"
        TXT_CONNECTIONS="Verbindungen"
        TXT_NEW_X_CONNECTION="Neue X-VerbindungX"
        TXT_NEW_RDP_CONNECTION="Neue RDP-Verbindung"
        TXT_NEW_FREERDP_CONNECTION="Neue FreeRDP-Verbindung"
        TXT_NEW_WEB_CONNECTION="Neue Internet-Verbindung";;
      "dutch" )
        TXT_REBOOT="Opnieuw Opstarten"
        TXT_SHUTDOWN="Afsluiten"
        TXT_LOGOFF="Afmelden"
        TXT_SETTINGS="Instellingen"
        TXT_MYLBT="Mijn Instellingen"
        TXT_APPLICATIONS="Applicaties"
        TXT_DEVICE="Configuratie"
        TXT_UPGRADE="Upgrade"
        TXT_CONNECTIONS="Verbindingen"
        TXT_NEW_X_CONNECTION="Nieuwe X-Verbinding"
        TXT_NEW_RDP_CONNECTION="Nieuwe RDP-Verbinding"
        TXT_NEW_FREERDP_CONNECTION="Nieuwe FreeRDP-Verbinding"
        TXT_NEW_WEB_CONNECTION="Nieuwe Internet-Verbinding";;
     "norwegian" )
        TXT_REBOOT="Restart"
        TXT_SHUTDOWN="Slaa av"
        TXT_LOGOFF="Logoff"
        TXT_SETTINGS="Innstillinger"
        TXT_MYLBT="Mine Innstillinger"
        TXT_APPLICATIONS="Programmer"
        TXT_DEVICE="Konfigurasjon"
        TXT_UPGRADE="Upgrade"
        TXT_CONNECTIONS="Connections"
        TXT_NEW_X_CONNECTION="Ny X-Connections"
        TXT_NEW_RDP_CONNECTION="Ny RDP-Connections"
        TXT_NEW_FREERDP_CONNECTION="Ny FreeRDP-Connections"
        TXT_NEW_WEB_CONNECTION="Ny Internet-Connections";;
      * )
        TXT_REBOOT="Reboot"
        TXT_SHUTDOWN="Shutdown"
        TXT_LOGOFF="Log-Off"
        TXT_SETTINGS="Settings"
        TXT_MYLBT="My LBT Setup"
        TXT_APPLICATIONS="Applications"
        TXT_DEVICE="Device"
        TXT_UPGRADE="Upgrade"
        TXT_CONNECTIONS="My Connections"
        TXT_NEW_X_CONNECTION="New X Connection"
        TXT_NEW_RDP_CONNECTION="New RDP Connection"
        TXT_NEW_FREERDP_CONNECTION="New FreeRDP Connection"
        TXT_NEW_WEB_CONNECTION="New Internet Browser Connection";;
    esac
    # Replacement
    echo "Language: ${INI__gui__language}"
    eval "sed -i -e 's/\"Reboot\"/\"$TXT_REBOOT\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"Shutdown\"/\"$TXT_SHUTDOWN\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"Log Off\"/\"$TXT_LOGOFF\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"Settings\"/\"$TXT_SETTINGS\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"My LBT Setup\"/\"$TXT_MYLBT\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"Applications\"/\"$TXT_APPLICATIONS\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"Device\"/\"$TXT_DEVICE\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"Upgrade\"/\"$TXT_UPGRADE\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"My Connections\"/\"$TXT_CONNECTIONS\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"New X Connection\"/\"$TXT_NEW_X_CONNECTION\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"New RDP Connection\"/\"$TXT_NEW_RDP_CONNECTION\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"New FreeRDP Connection\"/\"$TXT_NEW_FREERDP_CONNECTION\"/g' /root/.icewm/menu"
    eval "sed -i -e 's/\"New Internet Browser Connection\"/\"$TXT_NEW_WEB_CONNECTION\"/g' /root/.icewm/menu"
    
    # Test if BMP login has been already changed or not
    if [ -e /usr/lib/xpclient/ctrl_alt_del_message-${INI__gui__language}.bmp ]
    then
      echo "BMP logging is already updated"
    else
      echo "Updating BMP logging to ctrl_alt_del_message-${INI__gui__language}.bmp"
      eval "cp ${SCRIPTPATH}/data/ctrl_alt_del_message-${INI__gui__language}.bmp /usr/lib/xpclient/"
      eval "cp -f /usr/lib/xpclient/ctrl_alt_del_message-${INI__gui__language}.bmp /usr/lib/xpclient/ctrl_alt_del_message.bmp"
    fi
    
    # Tuning Reboot / Halt / Log-Off
    eval "sed -i -e 's/user1_back.png xdotool key \"ctrl+alt+Delete\"/user1_back.png clearregistry 8/g' /root/.icewm/menu"
    eval "sed -i -e 's/reboot.png xdotool key \"ctrl+alt+Delete\"/reboot.png shutdown -r now/g' /root/.icewm/menu"
    eval "sed -i -e 's/ghost.png xdotool key \"ctrl+alt+Delete\"/ghost.png shutdown -h now/g' /root/.icewm/menu"
    
    # Tuning taskbar icons (removing)
    eval "sed -i -e 's/^# TaskBarShowShowDesktopButton=1/TaskBarShowShowDesktopButton=0/g' /root/.icewm/preferences"
    eval "sed -i -e 's/^# TaskBarShowWindowListMenu=1/TaskBarShowWindowListMenu=0/g' /root/.icewm/preferences"    
  fi

# Updating Splashy image for 2xxx only
  if [ ${INI__gui__updateSplashy} -a ${DEVICE_MODEL} = "2xxx" ]
  then
    echo "Updating Splashy image: ${INI__gui__updateSplashy}"
    # Test if Splashy has been already changed or not
    if [ -e /root/.script_splashy_updated ] ;
    then
      echo "Splashy update: Already done"	
    else
      eval "cp ${SCRIPTPATH}/data/background.png /etc/splashy/themes/default/" 
   	  touch /root/.script_splashy_updated
   	  echo "Splashy update: Ok"
    fi
  fi

# Hide Taskbar for 2.0.1
  if [[ ( $INI__gui__hideTaskBar = "1" && $FIRMWARE_VERSION -eq "201" ) ]]
  then
    echo "Hidding taskbar for 2.0.1"
    eval "sed -i -e 's/^# ShowTaskBar=1/ShowTaskBar=0/g' /root/.icewm/preferences"
  else
    echo "Un-hidding taskbar for 2.0.1"
    eval "sed -i -e 's/^ShowTaskBar=0/# ShowTaskBar=1/g' /root/.icewm/preferences"
  fi

# Hide Taskbar for 2.0.2 or higher (XFCE based)
  if [[ ( $INI__gui__hideTaskBar = "1" && $FIRMWARE_VERSION -ge "202" ) ]]
  then
    echo "Hidding taskbar for 2.0.2"
    if [ -e /root/.script_hide_taskbar ] ;
    then
      echo "Already hidden !"
    else
      eval "cp ${SCRIPTPATH}/data/xfce4-session-hidetaskbar.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml"
      rm -f /root/.script_show_taskbar
      touch /root/.script_hide_taskbar
      REBOOT_AFTER_CONFIG_CHANGE="yes"
      echo "Hidding done !"
    fi
  else
    echo "Un-hidding taskbar for 2.0.2"
    if [ -e /root/.script_show_taskbar ] ;
    then
      echo "Already un-hidden !"
    else
      eval "cp ${SCRIPTPATH}/data/xfce4-session-orig.xml /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml"
      rm -f /root/.script_hide_taskbar
      touch /root/.script_show_taskbar
      REBOOT_AFTER_CONFIG_CHANGE="yes"
      echo "Un-hidding done !"
    fi
  fi

# Hide X Connection
  if [ ${INI__gui__hideXConnection} = "1" -a ${FIRMWARE_VERSION} -eq "201" ]
  then
    echo "Hidding X Connection"
    eval "sed -i -e 's/ prog \"$TXT_NEW_X_CONNECTION\"/#prog \"$TXT_NEW_X_CONNECTION\"/g' /root/.icewm/menu"
  else
    eval "sed -i -e 's/#prog \"$TXT_NEW_X_CONNECTION\"/ prog \"$TXT_NEW_X_CONNECTION\"/g' /root/.icewm/menu"
  fi

# Hide Web Connection
# For 2.0.1
  if [ ${INI__gui__hideWebConnection} = "1" -a ${FIRMWARE_VERSION} -eq "201" ]
  then
    echo "Hidding Web Connection"
    eval "sed -i -e 's/ prog \"$TXT_NEW_WEB_CONNECTION\"/#prog \"$TXT_NEW_WEB_CONNECTION\"/g' /root/.icewm/menu"
  else
    eval "sed -i -e 's/#prog \"$TXT_NEW_WEB_CONNECTION\"/ prog \"$TXT_NEW_WEB_CONNECTION\"/g' /root/.icewm/menu"
  fi

# For 2.0.2 or higher (XFCE based)
  if [ ${INI__gui__hideWebConnection} = "1" -a ${FIRMWARE_VERSION} -ge "202" ]
  then
    echo "Hidding Web Connection"
    eval "rm -f /usr/share/applications/xffox.desktop"
  fi

# Hide RDP Connection
  if [ ${INI__gui__hideRdpConnection} = "1" -a ${FIRMWARE_VERSION} -eq "201" ]
  then
    echo "Hidding RDP Connection"
    eval "sed -i -e 's/ prog \"$TXT_NEW_RDP_CONNECTION\"/#prog \"$TXT_NEW_RDP_CONNECTION\"/g' /root/.icewm/menu"
  else
    eval "sed -i -e 's/#prog \"$TXT_NEW_RDP_CONNECTION\"/ prog \"$TXT_NEW_RDP_CONNECTION\"/g' /root/.icewm/menu"
  fi

# Hide Shutdown
  if [ ${INI__gui__hideShutdown} = "1" -a ${FIRMWARE_VERSION} -eq "201" ]
  then
    echo "Hidding Shutdown"
    eval "sed -i -e 's/ prog \"$TXT_SHUTDOWN\"/#prog \"$TXT_SHUTDOWN\"/g' /root/.icewm/menu"
  else
    eval "sed -i -e 's/#prog \"$TXT_SHUTDOWN\"/ prog \"$TXT_SHUTDOWN\"/g' /root/.icewm/menu"
  fi

# Hide Reboot
  if [ ${INI__gui__hideReboot} = "1" -a ${FIRMWARE_VERSION} -eq "201" ]
  then
    echo "Hidding Reboot"
    eval "sed -i -e 's/ prog \"$TXT_REBOOT\"/#prog \"$TXT_REBOOT\"/g' /root/.icewm/menu"
  else
    eval "sed -i -e 's/#prog \"$TXT_REBOOT\"/ prog \"$TXT_REBOOT\"/g' /root/.icewm/menu"
  fi

# Hide Log-Off
  if [ ${INI__gui__hideLogoff} = "1" -a ${FIRMWARE_VERSION} -eq "201" ]
  then
    echo "Hidding Log-Off"
    eval "sed -i -e 's/ prog \"$TXT_LOGOFF\"/#prog \"$TXT_LOGOFF\"/g' /root/.icewm/menu"
  else
    eval "sed -i -e 's/#prog \"$TXT_LOGOFF\"/ prog \"$TXT_LOGOFF\"/g' /root/.icewm/menu"
  fi

# Hide Log-Off
  if [ ${INI__gui__hideLogoff} = "1" -a ${FIRMWARE_VERSION} -eq "201" ]
  then
    echo "Hidding Log-Off"
    eval "sed -i -e 's/ prog \"$TXT_LOGOFF\"/#prog \"$TXT_LOGOFF\"/g' /root/.icewm/menu"
  else
    eval "sed -i -e 's/#prog \"$TXT_LOGOFF\"/ prog \"$TXT_LOGOFF\"/g' /root/.icewm/menu"
  fi

# Modifying Clock Format
  if [ ${INI__gui__clock24HFormat} = "1" -a ${FIRMWARE_VERSION} -eq "201" ]
  then
    echo "Clock Format: 24H"
    eval "sed -i -e 's/^# TimeFormat=\"%X\"/TimeFormat=\"%H:%M\"/g' /root/.icewm/preferences"
  else
    echo "Clock Format: 12H"
    eval "sed -i -e 's/TimeFormat=\"%H:%M\"/# TimeFormat=\"%X\"/g' /root/.icewm/preferences"    
  fi

# Auto-start connection based on a keyword
  if [ ${INI__gui__autoStartConnection} ]
  then
    echo "Autostarting Connection the include keyword: ${INI__gui__autoStartConnection}"
    for i in /root/Desktop/*${INI__gui__autoStartConnection}* ;
    do
      if [ -f "$i" ]
      then
        CONNECTION=`cat "$i" | grep Exec | sed 's/Exec=//' | sed 's/\%f//' | sed '1!d'`
        echo "Connection found to autostart : $i = $CONNECTION"
        eval "${CONNECTION} &";
      fi;
    done;
  fi

# Hidding Cursor feature / TODO : Test with 2.0.2
  if [ ${INI__gui__hideCursor} = "1" ]
  then
    echo "Hide cursor: ${INI__gui__hideCursor}"
    # Test if cursor is already hidden or not
    if [ -e /root/.script_hide_cursor ] ;
    then
      echo "Hide Cursor: Already done"	
    else
      eval "tar zxvf ${SCRIPTPATH}/data/cursors.tar.gz -C /root/" 
   	  touch /root/.script_hide_cursor
   	  echo "Hide Cursor: Ok"
    fi
  fi

# ############################################
# FIREFOX SETTINGS
# ############################################

  # Checking if Firefox is installed or not
  if [ -e /root/.mozilla/firefox/cj9p78ab.default/prefs.js ] ;
  then
    echo "Firefox is installed"
    # open New Windows In New Tab
    if [ ${INI__firefox__openNewWindowsInNewTab} = "0" ]
    then
      echo "Disabling Firefox: Open New Window In New Tab"
      awk '/link.open_newwindow/{f=1}END{ if (!f) {print "user_pref(\"browser.link.open_newwindow\", 2);"}}1' /root/.mozilla/firefox/cj9p78ab.default/prefs.js > tmp && mv tmp /root/.mozilla/firefox/cj9p78ab.default/prefs.js
    else
      eval "sed -i -e '/link.open_newwindow/d' /root/.mozilla/firefox/cj9p78ab.default/prefs.js"
    fi
  
    # open New Windows In New Tab
    if [ ${INI__firefox__alwaysShowTaskbar} = "0" ]
    then
      echo "Disabling Firefox: Always Show Taskbar"
      awk '/tabs.autoHide/{f=1}END{ if (!f) {print "user_pref(\"browser.tabs.autoHide\", true);"}}1' /root/.mozilla/firefox/cj9p78ab.default/prefs.js > tmp && mv tmp /root/.mozilla/firefox/cj9p78ab.default/prefs.js
    else
      eval "sed -i -e '/tabs.autoHide/d' /root/.mozilla/firefox/cj9p78ab.default/prefs.js"
    fi
  
    # Disable Resume From Crash feature in Firefox
    if [ ${INI__firefox__disableResumeFromCrash} = "1" ]
    then
      echo "Disabling Firefox: Resume From Crash"
      awk '/resume_from_crash/{f=1}END{ if (!f) {print "user_pref(\"browser.sessionstore.resume_from_crash\", false);"}}1' /root/.mozilla/firefox/cj9p78ab.default/prefs.js > tmp && mv tmp /root/.mozilla/firefox/cj9p78ab.default/prefs.js
    else
      eval "sed -i -e '/resume_from_crash/d' /root/.mozilla/firefox/cj9p78ab.default/prefs.js"
    fi
  
    # Install r-kiosk extension to lock web browser
    if [ ${INI__firefox__kiosk} = "1" ]
    then
      if [ -e /usr/share/mozilla/extensions/\{ec8030f7-c20a-464f-9b0e-13a3a9e97384\}/\{4D498D0A-05AD-4fdb-97B5-8A0AABC1FC5B\}/install.rdf ]
      then
      	echo "Firefox Kiosk Mode: Already activated"
      else
      	eval "dpkg -i ${SCRIPTPATH}/data/r-kiosk-chippc-1.0.0.deb"
      	echo "Firefox Kiosk Mode: Activated"
      fi
    else
      if [ -e /usr/share/mozilla/extensions/\{ec8030f7-c20a-464f-9b0e-13a3a9e97384\}/\{4D498D0A-05AD-4fdb-97B5-8A0AABC1FC5B\}/install.rdf ]
      then
      	eval "dpkg -r r-kiosk-chippc"      	
      	echo "Firefox Kiosk Mode: Un-installed"
      fi
    fi    

    # Updating SSL Certicates to Firefox
    if [ ${INI__firefox__pushCertificate} ]
    then
      echo "Pushing SSL Certificates to Firefox: ${INI__firefox__pushCertificate}"
      if [ -e /root/.script_firefox_certs_updated ]
      then
      	echo "Certificates are already updated."
      else
      	eval "cp -f ${SCRIPTPATH}/certs/cert8.db /root/.mozilla/firefox/cj9p78ab.default/"
      	eval "touch /root/.script_firefox_certs_updated"
      	echo "Certificates has been updated !"
      fi
    fi

  else
    echo "Firefox not installed"
  fi

# ############################################
# CITRIX SETTINGS
# ############################################
  if [ -e /root/.ICAClient/wfclient.ini ] 
  then
    # ICA is installed
    echo "ICA Client is installed"

    # Modification of ZLDiskCacheSize in wfclient.ini
    if [ ${INI__citrix__ZLDiskCacheSize} ]
    then
      echo "Modifying Citrix ZLDiskCacheSize: ${INI__citrix__ZLDiskCacheSize}"
      eval "sed -i -e '/ZLDiskCacheSize/d' /root/.ICAClient/wfclient.ini"
      eval "echo 'ZLDiskCacheSize=${INI__citrix__ZLDiskCacheSize}'>>/root/.ICAClient/wfclient.ini"    
    fi
  
    # Adding USB to Serial support in wfclient.ini
    if [ ${INI__citrix__addComPortUSB} ];
    then
      echo "Adding Citrix USB to Serial: ${INI__citrix__addComPortUSB}"
      eval "sed -i -e '/ComPort1/d' /root/.ICAClient/wfclient.ini"
      eval "sed -i -e '/ComPort2/d' /root/.ICAClient/wfclient.ini"
      eval "sed -i -e '/WFClient/a \
ComPort2=\/dev\/ttyUSB1' /root/.ICAClient/wfclient.ini"
      eval "sed -i -e '/WFClient/a \
ComPort1=\/dev\/ttyUSB0' /root/.ICAClient/wfclient.ini"
      eval "sed -i -e '/LastComPortNum/c \
LastComPortNum=2' /root/.ICAClient/wfclient.ini"
    fi

    # Updating SSL Certicates to Citrix Client
    if [ ${INI__citrix__pushCertificate} ]
    then
      echo "Pushing SSL Certificates to Citrix Client: ${INI__citrix__pushCertificate}"
      if [ -e /root/.script_citrix_certs_updated ]
      then
      	echo "Certificates are already updated."
      else
      	eval "cp -f ${SCRIPTPATH}/certs/* /usr/lib/chippc/doc/plugins/xicap/keystore/cacerts/"
      	eval "touch /root/.script_citrix_certs_updated"
      	echo "Certificates has been updated !"
      fi
    fi

    # Cleaning PNAgent Icons on desktop during boot
    if [ ${INI__citrix__cleanPNAIcons} ]
    then
      echo "Cleaning PNA Icons on Desktop: ${INI__citrix__cleanPNAIcons}"
      eval "grep -rlI 'pnagent' /root/Desktop | xargs -I{} rm -v {}"
    fi

    # Fixing XDMAllowed at every boot
    if [[ ( $INI__citrix__fixCDMAllowed = "1" ) ]]
    then
      echo "Fixing CDMAllowed to off: ${INI__citrix__fixCDMAllowed}"
      eval "sed -i -e 's/CDMAllowed=On/CDMAllowed=Off/g' /root/.ICAClient/appsrv.ini"
      if [ -e /root/.script_citrix_fixcdmallowed_updated ]
      then
      	echo "startsession.sh is already updated."
      else
        eval "sed -i -e '7a sed -i -e \"s/CDMAllowed=On/CDMAllowed=Off/g\" /root/.ICAClient/appsrv.ini' /usr/lib/chippc/scripts/startsession.sh"
      	eval "touch /root/.script_citrix_fixcdmallowed_updated"
      	echo "startsession.sh is now updated."
      fi
    fi

# Applying a custom wfclient.ini
    if [ ${INI__citrix__customWfclientIni} ]
    then
      echo "Pushing SSL Certificates to Citrix Client: ${INI__citrix__customWfclientIni}"
      if [ -e /root/.script_citrix_custom_wfclient_ini ]
      then
        echo "Custom wfclient.ini is already updated."
      else
        eval "cp -f ${SCRIPTPATH}/data/wfclient.ini /root/.ICAClient/"
        eval "touch /root/.script_citrix_custom_wfclient_ini"
        echo "Custom wfclient.ini has been updated !"
      fi
    fi
 
   else
    echo "ICA Client not installed"
  fi

# ############################################
# FREERDP SETTINGS
# ############################################

    # Updating SSL Certicates to FreeRDP Client
    if [ ${INI__freerdp__pushCertificate} ]
    then
      echo "Pushing SSL Certificates to FreeRDP Client: ${INI__freerdp__pushCertificate}"
      if [ -e /root/.script_freerdp_certs_updated ]
      then
      	echo "Certificates are already updated."
      else
        eval "mkdir -p /root/.freerdp/certs/"
      	eval "cp -f ${SCRIPTPATH}/certs/* /root/.freerdp/certs/"
      	eval "touch /root/.script_freerdp_certs_updated"
      	echo "Certificates has been updated !"
      fi
    fi

    # Updating SSL Certicates to FreeRDP Client
    if [ ${INI__freerdp__addUsbRedirection} = "1" ]
    then
      echo "Enabling USB Driver redirection in FreeRDP (bug fix for 1.00.05) : ${INI__freerdp__addUsbRedirection}"
      if [ -e /root/.script_freerdp_usbredirection_updated ]
      then
      	echo "USB Redirection has been already added."
      else
        eval "mv /usr/local/bin/xfreerdp /usr/local/bin/xfreerdp-old"
      	eval "echo '#!/bin/bash' > /usr/local/bin/xfreerdp"
      	eval 'echo "/usr/bin/xfreerdp --plugin rdpdr --data disk:usbdrive:/media/rdpusb -- \$*" >> /usr/local/bin/xfreerdp'
      	eval "chmod +x /usr/local/bin/xfreerdp"
      	eval "touch /root/.script_freerdp_usbredirection_updated"
      	echo "USB Redirection has been added !"
      fi
    fi

# ############################################
# RDESKTOP SETTINGS
# ############################################

    # Updating US Internationnal Keyboard to add Euro sign
    if [ ${INI__rdesktop__usKbFix} ]
    then
      echo "Update keymap to fix US Int Kb in rdesktop: ${INI__rdesktop__usKbFix}"
      if [ -e /root/.script_rdesktop_uskbfix_updated ]
      then
      	echo "Keymaps are already updated."
      else
        eval "echo 'EuroSign 0x06 altgr' >> /usr/share/rdesktop/keymaps/us-intl"
      	eval "touch /root/.script_rdesktop_uskbfix_updated"
      	echo "Keymap has been updated !"
      fi
    fi

# ############################################
# SECMAKER IID PLUGIN
# ############################################

    # Fixing libz.so.1 lib in iid.conf
    if [ ${INI__iid__iidZipFix} ]
    then
      # Checking if SecMaker iid is installed or not
  	  if [ -e /etc/iid.conf ] ;
  	  then
        echo "Secmaker iid is installed"
        echo "Fixing libz.so.1 in iid.conf: ${INI__iid__iidZipFix}"
        if [ -e /root/.script_iid_zipfix_updated ]
        then
      	  echo "Fix is already deployed."
        else
          eval "cp ${SCRIPTPATH}/data/iid.conf /etc/"
      	  eval "touch /root/.script_iid_zipfix_updated"
      	  echo "iid fix has been updated !"
        fi
      else
        echo "Secmaker iid isn't installed !"
      fi
    fi

# ############################################
# OPEN DEVICE SETTINGS (Need for Open Kernel LXD : MANDATORY)
# ############################################

    # Updating FreeRDP Client
    if [ ${INI__opendevice__updateFreeRDP} = "1" -a ${DEVICE_MODEL} = "8xxx" ]
    then
      echo "Updating FreeRDP Client: ${INI__opendevice__updateFreeRDP}"
      if [ -e /usr/bin/xfreerdp ]
      then
      	if dpkg-query -W freerdp-chippc ;
      	then
      		echo "Already installed"
      	else
      		eval "dpkg -i --force-all ${SCRIPTPATH}/data/freerdp-*.deb"
      		echo "FreeRDP has been installed/updated."
      	fi
      else
      	echo "Chip PC FreeRDP Plugin isn't installed before... Need to have it installed before !"
      fi
    fi

    # Updating Firefox
    if [ ${INI__opendevice__updateFirefox} = "1" -a ${DEVICE_MODEL} = "8xxx" ]
    then
      echo "Updating Firefox : ${INI__opendevice__updateFirefox}"
      if [ -e /usr/lib/firefox-3.6.3/firefox ]
      then
      	if dpkg-query -W firefox ;
      	then
      		echo "Already installed"
      	else
	      	eval "dpkg -i --force-all ${SCRIPTPATH}/data/firefox*.deb"
    	  	echo "Firefox has been installed/updated."
    	fi
      else
      	echo "Chip PC Firefox Plugins isn't installed before... Need to have it installed before !"
      fi
    fi

    # Updating Chrome
    if [ ${INI__opendevice__updateChrome} = "1" -a ${DEVICE_MODEL} = "8xxx" ]
    then
      echo "Updating Chrome : ${INI__opendevice__updateChrome}"
      if [ -e /usr/lib/chromium-browser/chromium-browser ]
      then
      	if dpkg-query -W chromium-browser ;
      	then
      		echo "Already installed"
      	else
	      	eval "dpkg -i --force-all ${SCRIPTPATH}/data/xdg-util*.deb"
    	  	eval "dpkg -i --force-all ${SCRIPTPATH}/data/chromium*.deb"
      		echo "Firefox has been installed/updated."
      	fi
      else
      	echo "Chip PC Chrome Plugins isn't installed before... Need to have it installed before !"
      fi
    fi

# Adding automatic Keyboard detection tool to ICA Client
  if [ ${INI__opendevice__IcaAutoKeyboard} = "1" ]
  then
    echo "ICA Automatic Keyboard: ${INI__opendevice__IcaAutoKeyboard}"
    if [ -e /root/.script_ica_auto_keyboard_done ]
    then
      echo "Patch already done !"
    else
      # Copying files
      eval "cp ${SCRIPTPATH}/data/xkb-switch/libxkbswitch.so /usr/local/lib/"
      eval "cp ${SCRIPTPATH}/data/xkb-switch/xkb-switch.bin /usr/local/bin/"
      eval "mv /usr/local/bin/xkb-switch.bin /usr/local/bin/xkb-switch"
      eval "cp ${SCRIPTPATH}/data/xkb-switch/ica_keyboard_switch.sh /usr/lib/chippc/scripts/"
      eval "chmod +x /usr/lib/chippc/scripts/ica_keyboard_switch.sh"
      eval "chmod +x /usr/local/bin/xkb-switch"
      # Modifying startsession.sh
      eval "sed -i -e '/xdotool/a \
bash /usr/lib/chippc/scripts/ica_keyboard_switch.sh' /usr/lib/chippc/scripts/startsession.sh"
   	  eval "touch /root/.script_ica_auto_keyboard_done"
      echo "Patch done."
    fi
  fi

else
  echo "Configuration file not found !"
fi

exit


if [[ ("$REBOOT_AFTER_CONFIG_CHANGE" = "yes") && ("$IP_CHANGED" = "1" || "$HOST_CHANGED" = "1" ) ]];
then
  eval "reboot" 
fi
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
# #########################################################################################
