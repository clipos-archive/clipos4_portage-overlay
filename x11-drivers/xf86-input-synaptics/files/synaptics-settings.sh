#!/bin/sh
# synaptics-settings.sh : configure synaptics driver parameters
# from a CLIP USER session
# Copyright (c) 2011 DGSIC
# Author: Florent Chabaud <clipos@ssi.gouv.fr>
# Distributed under the terms of the GNU General Public License
# version 2.

/usr/local/bin/synclient -l >& /dev/null 
if [[ $? -ne 0 ]]; then 
	[[ "${1}" == "init" ]] \
		|| Xdialog --no-cancel --wrap --left --title "Pas de touchpad avancé" --msgbox "Aucun touchpad avancé (Synaptics, ALPS/2, ...) n'a été détecté sur le système.\nLes fonctionnalités avancées ne peuvent pas être configurées." 0 0
	exit 1
fi

# teste la presence de la souris
mouse_plugged=0

test_if_mouse_plugged() {
	if xinput -list | grep -i --quiet mouse; then
		mouse_plugged=1
	fi
	echo ${mouse_plugged}
}



get_conf() {
	local scroll="Scroll"
	local circular="Circular"
	local multi="Multi"
	local coast="Coast"
	local tap="Touchpad"

	if [[ "${defact}" == "off" ]]; then
		# Make these options unavailable
		scroll=""
		circular=""
		multi=""
		coast=""
		tap=""
	fi
	conf="$(/usr/local/bin/Xdialog --stdout --item-help --no-tags --title "Configuration du pavé tactile dans mounts" --checklist "Configuration avancée du pavé tactile (touchpad)" 400x300 3 \
"TouchActive" "Activation du touchpad" "${defact}" "Permet de activer ou desactiver le touchpad." \
"${tap}" "Tapotement" "${deftap}" "Permet de désactiver le défilement et l'émulation du bouton de la souris quand on tape sur le pavé tactile." \
"${scroll}" "Défilement latéral" "${defaut}" "Le défilement lateral permet d'utiliser les bords du pavé tactile pour déplacer les ascenseurs des fenêtres." \
"${circular}" "Défilement circulaire" "${defcirc}" "Le défilement circulaire permet de faire défiler les ascenseurs d'une fenêtre en décrivant des cercles sur le pavé tactile." \
"${coast}" "Défilement inertiel" "${defcoast}" "Le défilement inertiel provoque la poursuite du défilement après le retrait du doigt du pavé tactile." \
"${multi}" "Défilement par double trace" "${defmulti}" "Le défilement par double trace permet, sur certains matériels, de faire défiler les ascenseurs en utilisant deux doigts au lieu d'un sur le pointeur intégré." \
)"
	[[ $? -ne 0 ]] && exit 0
}

CONFIG="/home/user/.synaptics"

conf="TouchActive"
deftap="$(/usr/local/bin/synclient -l | grep TouchpadOff | cut -f2 -d"=")"
[[ $((${deftap}+0)) -eq 0 ]] && deftap="on" && conf="${conf}/Touchpad"
defaut="$(/usr/local/bin/synclient -l | grep VertEdgeScroll | cut -f2 -d"=")"
[[ $((${defaut}+0)) -ne 0 ]] && defaut="on" && conf="${conf}/Scroll"
defcirc="$(/usr/local/bin/synclient -l | grep CircularScrolling | cut -f2 -d"=")"
[[ $((${defcirc}+0)) -ne 0 ]] && defcirc="on" && conf="${conf}/Circular"
defmulti="$(/usr/local/bin/synclient -l | grep VertTwoFingerScroll | cut -f2 -d"=")"
[[ $((${defmulti}+0)) -ne 0 ]] && defmulti="on" && conf="${conf}/Multi"
defcoast="$(/usr/local/bin/synclient -l | grep CoastingSpeed | cut -f2 -d"=")"
[[ $((${defcoast}+0)) -ne 0 ]] && defcoast="on" && conf="${conf}/Coast"

# on regarde si la souris est branchee
test_if_mouse_plugged

# On ne lit le fichier de configuration que si on est en mode init d'ouverture de session
# ce qui permet de voir la configuration courante du driver
[[ "${1}" == "init" ]] && [[ -r "${CONFIG}" ]] && conf="$(cat "${CONFIG}")"

# -----------------------------------------------------------------------------------------------------------
# pour la mise à jour correspondant à l'ajout de TouchActive et donc l'action/désactivation du Touchpad :
# si on ne trouve pas le fichier SynapticsConfigurationUpdated : on ajoute TouchActive à la configuration, on remplace Tap par Touchpad et on crée le fichier SynapticsConfigurationUpdated,
# si on trouve le fichier SynapticsConfigurationUpdated on ne fait rien
# 

CONFIG_UPDATE_MARKER="/home/user/.synapticsConfigurationUpdated"

if [[ "${1}" == "init" ]]; then 

  if [ ! -r ${CONFIG_UPDATE_MARKER} ]; then

    # si le fichier marqueur n'existe pas
    # on remplace Tap par Touchpad

    if [ -r ${CONFIG} ]; then

      ancienne_conf=`cat ${CONFIG}`

      # on supprime Tap
      if echo ${ancienne_conf} | grep --quiet "Tap"; then
	if echo ${ancienne_conf} | grep --quiet "Touchpad"; then
	  sed -i -e "s/Tap//g" ${CONFIG}
	else
	  sed -i -e "s/Tap/Touchpad/g" ${CONFIG}
	fi
      fi

      # on ajoute TouchActive
      nouv_conf=`cat ${CONFIG}`"/TouchActive"

      echo $nouv_conf > ${CONFIG}

      # remplace "//" par "/"
      sed -i -e "s/\/\//\//g" ${CONFIG}

      touch ${CONFIG_UPDATE_MARKER}

      conf="$(cat "${CONFIG}")"

    fi

  fi

fi


if [[ "${1}" != "init" ]]; then
	defact="$(/usr/local/bin/synclient -l | grep TouchpadOff | cut -f2 -d"=")"

	# si une souris est branchee et que le touchpad est desactive on propose de le reactiver
	# sinon on reactive par defaut le touchpad et on propose les options fines
	if [[ ${mouse_plugged} -ne 0 ]]; then
		if [[ $((${defact}+0)) -eq 1 ]]; then
			defact="off"
			get_conf
			# si l'utilisateur active le Touchpad on relance l'interface pour la configuration fine
			# sinon on quitte 
			if [[ "${conf}" != "TouchActive" ]]; then
				# si le Touchpad est desactive
				/usr/local/bin/synclient TouchpadOff=1
				echo "" > "${CONFIG}"
				exit 0
			fi
		fi
	fi

	defact="on"
	get_conf
fi

# on teste a nouveau la souris au cas ou son etat aurait change pendant l affichage de getconf
test_if_mouse_plugged

if echo "${conf}" | grep --quiet TouchActive; then
	/usr/local/bin/synclient TouchpadOff=2
	if echo "${conf}" | grep --quiet Touchpad; then
		/usr/local/bin/synclient TouchpadOff=0
	fi
else
	# ci dessous on desactive completement le touchpad
	# sauf si la souris n est pas branchee auquel cas on le reactive d office dans la configuration
	if [[ ${mouse_plugged} -ne 0 ]]; then 
	  	/usr/local/bin/synclient TouchpadOff=1
	else
		# si la souris est debranche on reactive le touchpad
		conf="TouchActive/${conf}"		                                                        
                /usr/local/bin/synclient TouchpadOff=2    

		# et on reactive le tapotement si il est dans les options
		if echo "${conf}" | grep --quiet Touchpad; then
			/usr/local/bin/synclient TouchpadOff=0
		fi

	fi
fi
if echo "${conf}" | grep --quiet Scroll; then
	/usr/local/bin/synclient VertEdgeScroll=1
	/usr/local/bin/synclient HorizEdgeScroll=1
else
	/usr/local/bin/synclient VertEdgeScroll=0
	/usr/local/bin/synclient HorizEdgeScroll=0
fi
if echo "${conf}" | grep --quiet Multi; then
	/usr/local/bin/synclient VertTwoFingerScroll=1
	/usr/local/bin/synclient HorizTwoFingerScroll=1
else
	/usr/local/bin/synclient VertTwoFingerScroll=0
	/usr/local/bin/synclient HorizTwoFingerScroll=0
fi
if echo "${conf}" | grep --quiet Circular; then
	/usr/local/bin/synclient CircularScrolling=1
else
	/usr/local/bin/synclient CircularScrolling=0
fi
if echo "${conf}" | grep --quiet Coast; then
	/usr/local/bin/synclient CoastingSpeed=20
else
	/usr/local/bin/synclient CoastingSpeed=0
fi

echo "${conf}" > "${CONFIG}"
exit 0


