#!/bin/bash
function rw {
busybox mount -o remount,rw /system
}

function ro {
busybox mount -o remount,ro /system
}

function zipalign {
	if busybox [ -z "$( busybox which zipalign )" ]; then
		echo "Error: zipalign binary missing."
		return
	fi

	START=` busybox date +%s `
	CODEPATH=(` pm list packages -f | busybox cut -d ':' -f2 | busybox cut -d '=' -f1 `);
	MAX=${#CODEPATH[*]}
	INCREMENT=5
	PROGRESS=0
	PROGRESS_BAR=""

	echo
	echo "Zipaligning..."
	echo

	busybox mount -o remount,rw /system
	
	for codepath in ${CODEPATH[*]}; do
		
		let PROGRESS++
		PERCENT=$(( $PROGRESS * 100 / $MAX))
		if busybox [ $PERCENT -eq $INCREMENT ]; then
			INCREMENT=$(( $INCREMENT + 5 ))
			PROGRESS_BAR="${PROGRESS_BAR}="
		fi
		
		echo -ne "  \r  ${PROGRESS}/${MAX} ${PERCENT}% [ ${PROGRESS_BAR}> ]"
		
		if busybox [ -e $codepath ]; then
			zipalign -c 4 $codepath
			ZIP_CHECK=$?
			case $ZIP_CHECK in
				1)
					if zipalign -f 4 $codepath /data/local/pkg.apk; then
						busybox cp -f /data/local/pkg.apk $codepath
						busybox rm -f /data/local/pkg.apk
					fi
				;;
			esac
		fi

	done
	
	busybox mount -o remount,ro /system
	sync

	STOP=` busybox date +%s `
	RUNTIME=` runtime $START $STOP `
	echo
	echo
	echo "Zipalign complete! Runtime: ${RUNTIME}"
	echo
}


rw
zipalign
ro

