#!/bin/bash

# Automated Keyboard switch for ICA Client based on xkb-switch info
# by Romain DUCHENE for Chip PC
#
# Issue with Belgium Kb... Can't differenciate "be dutch" and "be French"... Booth are giving : "be"
# Issue with Japanese Kb... Can't differenciate "jp" and "jp IME"... Booth are giving : "jp"
# Brazilian keyboard in Citrix seems to be Brazilian (ABNT2) (So, what is "Latin American" ?)
# Polish have 2 keyboards in Citrix: "Polish (Programmers)" and "Polish (214)"... Programmers seems more popular

ACTIVE_KEYBOARD=`/usr/local/bin/xkb-switch`

# Checking if ICA is installed or not
if [ -e /root/.ICAClient/wfclient.ini ] ;
then
  echo "Active Keyboard "$ACTIVE_KEYBOARD

  case $ACTIVE_KEYBOARD in
  "fr(winkeys)")
    KBD="French"
    ;;
  "us")
    KBD="US"
    ;;
  "us(intl)")
    KBD="US-International"
    ;;
  "de")
    KBD="German"
    ;;
  "ca")
    KBD="Canadian English (Multilingual)"
    ;;
  "ca(fr)")
    KBD="Canadian French"
    ;;
  "be")
    KBD="Belgian Dutch"
    ;;
  "be")
    KBD="Belgian Dutch"
    ;;
  "nl")
    KBD="Dutch"
    ;;
  "dk")
    KBD="Danish"
    ;;
  "cz")
    KBD="Czech"
    ;;
  "gb")
    KBD="British"
    ;;
  "il")
    KBD="Hebrew"
    ;;
  "gr")
    KBD="Greek"
    ;;
  "fi")
    KBD="Finnish"
    ;;
  "hu")
    KBD="Hungarian"
    ;;
  "jp")
    KBD="Japanese (JIS)"
    ;;
  "it")
    KBD="Italian"
    ;;
  "no")
    KBD="Norwegian"
    ;;
  "br")
    KBD="Brazilian (ABNT2)"
    ;;
  "pt")
    KBD="Portuguese"
    ;;
  "pl")
    KBD="Polish (Programmers)"
    ;;
  "no")
    KBD="Norwegian"
    ;;
  "ro")
    KBD="Romanian"
    ;;
  "si")
    KBD="Slovenian"
    ;;
  "sk")
    KBD="Slovak"
    ;;
  "ru(winkeys)")
    KBD="Russian"
    ;;
  "es")
    KBD="Spanish"
    ;;
  "ch(de)")
    KBD="Swiss German"
    ;;
  "ch(fr)")
    KBD="Swiss French"
    ;;
  "se")
    KBD="Swedish"
    ;;
  "tr")
    KBD="Turkish (Q)"
    ;;
  *)
    KBD="Error"
    ;;
  esac

  if [[ $KBD = "Error" ]]
  then
    echo "Error: Keyboard not found !"
  else
    echo "Citrix Keyboard to apply: "$KBD
    eval "sed -i -e 's/^KeyboardLayout.*/KeyboardLayout=$KBD/g' /root/.ICAClient/wfclient.ini"
  fi
  else
    echo "Citrix Client not installed"
fi