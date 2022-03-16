#!/bin/bash
# AppleJack, an open source basic troubleshooting utility for Mac OS X
# Copyright (c) 2002-10 Kristofer Widholm, The Apotek
# $Id: applejack.sh,v 1.144 2010/07/11 04:39:16 kwidholm Exp $
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or -at your
# option- any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
# You can reach The Apotek at http://www.theapotek.com
#

########################################################################
#	START OF APPLEJACK CONFIGURATION ############# CONSTANTS ###########
########################################################################
VERSION="1.6"
REVISION=`echo '$Revision: 1.144 $' | sed 's/\\$//g' 2> /dev/null`
DEEP=0	#	Set deep mode to 0 [off], unless specified at runtime
DEFAULTDELAY=3	#	How long should the default delay be
CANCELTIME=10	#	How many seconds should the user have to cancel automatic tasks?
DRL=9	#	Disk Repair Limit: How many times should disk repair repeat before aborting [auto mode], or posting a notice [manual mode]?
BANNER="\033[4m                              AppleJack                               \033[0m"
GOODBYE="*********************** GOODBYE FROM APPLEJACK ***********************"
LOGFILE="/private/var/log/AppleJack.log"	#	Where does the AppleJack log go?
# Set up a good path--from /etc/rc
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/libexec:/System/Library/CoreServices;export PATH

# standard exit code for usage error [from C, /usr/include/sysexits.h]
EX_OK=0 # successful termination
EX_ERR=1 # general error
EX_USAGE=64	# user error
EX_SOFTWARE=70	# internal software error
EX_OSERR=71	# system error [e.g., can't fork]

#	Formatting shortcut codes
#	Bold: \033[1m	Underline: \033[4m	Magenta: \033[35m	Yellow: \033[33m	Red: \033[31m
# These must be defined with double quotes to be filtered correctly
bE="\033[31m*** "	#	Start formatting for "errors"
eE=" ***\033[0m"	#	End of format for errors.
bH="\033[35m\033[1m\033[4m"	#	Color code for key highlights
eH="\033[0m"	#	End of color code for key highlights
bK="\033[35m\033[1m"	#	Color code for key entry
eK="\033[0m"	#	End of formatting for key entry
bW="\033[33m"	#	formatting for "warnings"
eW="!\033[0m"	#	End of formatting for warnings.
bS="\033[1m"	#	Begin strong
eS="\033[0m"	#	End strong
bPar='('	#	Parentheses in strings confuse some text editors.
ePar=')'
TASKNAMES=( [0]="${bH}a${eH}uto pilot" [1]="repair ${bH}d${eH}isks" [2]="repair ${bH}p${eH}ermissions" [3]="cleanup ${bH}c${eH}ache files" [4]="validate pre${bH}f${eH}erence files"  [5]="clean up ${bH}v${eH}irtual memory" [6]="${bH}q${eH}uit" )
TASKCODES=( a d p c f v q )
TASKCODESUC=( A D P C F V Q )
TASKS=( [0]='AUTO=1;selectNext' [1]='repairDisks' [2]='fixPermissions' [3]='cacheCleanup' [4]='validatePreferences' [5]='cleanupVM' [6]='quitScript' )
xTASKNAMES=( [0]="deep clean ${bH}c${eH}ache files" [1]="${bH}v${eH}erify hard drives ${bPar}S.M.A.R.T. Check${ePar}" [2]="test ${bH}m${eH}emory" [3]="${bH}b${eH}less system folder" [4]="disable ${bH}a${eH}uto login" [5]="disable ${bH}l${eH}ogin items for a user" [6]="${bH}r${eH}estore NetInfo database from backup (Mac OS X Tiger only)" [7]="disable system con${bH}f${eH}iguration files" [8]="disable NetInfo ${bH}N${eH}FS mounts (Mac OS X Tiger only)" [9]="enable new machine ${bH}s${eH}etup" [10]="${bH}q${eH}uit" )
xTASKCODES=( c v m b a l r f n s q )
xTASKCODESUC=( C V M B A L R F N S Q )
xTASKS=( [0]='xDeepCacheClean' [1]='xSmartCheck' [2]='xMemTest' [3]='xBlessDrive' [4]='xDisableAutoLogin' [5]='xDisableUserLoginItems' [6]='xRestoreNetinfoFromBackup' [7]='xDisableSysConfigFiles' [8]='xDisableNFSMounts' [9]='xEnableNewSetup' [10]='quitScript' )
#	standardize the binaries, if possible
BADENV=0
if [ -x /usr/bin/awk ];then AWK='/usr/bin/awk';else AWK='awk';BADENV=1;fi
if [ -x /usr/sbin/bless ];then BLESS='/usr/sbin/bless';else BLESS='bless';BADENV=1;fi
if [ -x /bin/chmod ];then CHMOD='/bin/chmod';else CHMOD='chmod';BADENV=1;fi
if [ -x /usr/sbin/chown ];then CHOWN='/usr/sbin/chown';else CHOWN='chown';BADENV=1;fi
if [ -x /bin/cp ];then CP='/bin/cp';else CP='cp';BADENV=1;fi
if [ -x /usr/bin/egrep ];then EGREP='/usr/bin/egrep';else EGREP='egrep';BADENV=1;fi
if [ -x /usr/bin/file ];then FILE='/usr/bin/file';else FILE='file';BADENV=1;fi
if [ -x /usr/bin/grep ];then GREP='/usr/bin/grep';else GREP='grep';BADENV=1;fi
if [ -x /usr/libexec/kextd ];then KEXTD='/usr/libexec/kextd';else KEXTD='kextd';BADENV=1;fi
if [ -x /bin/ln ];then LN='/bin/ln';else LN='ln';BADENV=1;fi
if [ -x /bin/ls ];then LS='/bin/ls';else LS='ls';BADENV=1;fi
if [ -x /bin/mkdir ];then MKDIR='/bin/mkdir';else MKDIR='mkdir';BADENV=1;fi
if [ -x /sbin/mount ];then MOUNT='/sbin/mount';else MOUNT='mount';BADENV=1;fi
if [ -x /bin/mv ];then MV='/bin/mv';else MV='mv';BADENV=1;fi
if [ -x /usr/bin/dscl ];then DSCL='/usr/bin/dscl';DSCLav=1;else DSCL='dscl';DSCLav=0;fi
if [ -x /usr/bin/plutil ];then PLUTIL='/usr/bin/plutil';else PLUTIL='plutil';BADENV=1;fi
if [ -x /bin/rm ];then RM='/bin/rm';else RM='rm';BADENV=1;fi
if [ -x /bin/rmdir ];then RMDIR='/bin/rmdir';else RMDIR='rmdir';BADENV=1;fi
if [ -x /usr/bin/sed ];then SED='/usr/bin/sed';else	SED='sed';BADENV=1;fi
if [ -x /usr/bin/tee ];then TEE='/usr/bin/tee';else	SED='tee';BADENV=1;fi

# Register the IDENTITY variable, for later use
#declare -arx IDENTITY=( `id | cut -d '=' -f 2 | cut -d ' ' -f 1 | $SED -e 's/[()]/ /g;'` )
declare -arx IDENTITY=( `id -u` `id -un` ) # Leopard id utility barfs when running id without options

########################################################################
#	END OF APPLEJACK CONFIGURATION #####################################
########################################################################

#	Make sure to clean up whenever the script is killed
trap quitScript INT

#	Thanks to "Maarten" from the Ars Technica Open Forum for providing this function.
#	checkAlias returns 1 if file is an alias; 0 if not.
#	When used like so: `if checkAlias "filename";then, the 0 signals NOT an alias, 
#	so this would evaluate to TRUE
function checkAlias() {
	local testfile="$1"
	#	To be an alias, it must be of zero file size, 
	#	have a resource fork,
	#	that contains an 'alis' resource.
	#	Old way
	#	test -s "$testfile" || test -s "$testfile/rsrc" && grep --quiet 'alis' "$testfile/rsrc" && return 1
	#	New way
	test -s "$testfile" || test -s "$testfile/..namedfork/rsrc" && grep --quiet 'alis' "$testfile/..namedfork/rsrc" && return $EX_ERR
	return 0; # Not an alias: success
}

#	Allows user to choose a user directory to work on
#	1. Grab usernames and ids from NetInfo filtering for user ids > 100
#	dsusers=' ';for u in `nicl . -list /users | awk '{ print $2 }'`;do uid=`nicl . -read "/users/$u" uid | sed -e 's/^uid: //'`;if [ $uid -gt 100 ];then uhome=`nicl . -read "/users/$u" home | sed -e 's/home: //'`;dsusers="${users}$uid:$u:$uhome ";fi;done;echo $dsusers
#	2. Grab usernames and ids from /etc/passwd, filtering for user ids > 100
#	pwusers=' ';for user in `cat /etc/passwd | grep -v '#' | sed -e 's/:/ /g' | awk '{ print $1":"$3":"$6 }'`;do uid=`echo $user | cut -f 2 -d ':'`;if [ $uid -gt 100 ];then pwusers="${pwusers}${user} ";fi;done;echo ":$pwusers:"
#	3. Grab usernames and ids from any other system Apple uses for storing user info that does not require higher system level operations. NA
#	4. Grab usernames and ids from the /Users folder
#	5. Condense all the info privileging the information in reverse order
#	6. Filter out any common user ids that are system user ids
#	6. Print a list of usernames, using the userids as menu selects
#	7. In the input, the user can either type in the user's id, the user's name, or an absolute path to the directory in question.
#	8. Parse user input: If it's a number, grab the associated home direcory; if it's a name, go with the username's associated home directory; if it starts with a slash, just go to that directory
function chooseUserDirectory() {
	local user
	local uid
	local uname
	local uhome
	local uc
	local ul
	local tail
	local homedir=''
	local choice
	local err=0
	local ds_command
	if [ -z "$USERLIST" ];then
		startServices
		local dsusers=''
		for uid in `$DSCL . -list /users uid 2>/dev/null | $AWK '{ print $2}'`;do 
			if [ $uid -gt 400 ];then 
				uname=`id -un $uid | $AWK '{ print $1 }'`
				uhome=`$DSCL . -read "/users/$uname" home 2>/dev/null | $AWK '{ print $2 }'`
				dsusers="${dsusers}$uid:$uname:$uhome "
			fi
		done
		if [ ! -z "$dsusers" ];then
			USERLIST="$dsusers"
		fi
		local pwusers=''
		for user in `cat /etc/passwd | $GREP -v '#' | grep -v '^_' | cut -d : -f 1,3,6`;do
			uid=`echo "$user" | cut -f 2 -d :`
			if [ $uid -gt 100 ] && echo " $USERLIST" | $GREP -v " $uid:">/dev/null;then 
				user=`echo "$uid:$user" | cut -d : -f 1,2,4`
				pwusers="${pwusers}${user} "
			fi
		done;
		if [ ! -z "$pwusers" ];then
			USERLIST="${USERLIST}$pwusers"
		fi
		local dirusers=''
		for user in `$LS -CLln /Users/ | $GREP '^d' | $EGREP -v '(Shared|Temporary)' | $AWK '{ print $3":/Users/"$9 }'`;do
			uid=`echo $user | cut -f 1 -d :`
			uhome=`echo $user | cut -f 2 -d :`
			uname=`id -nu "$uid"`
			if [ $uid -gt 100 ] && echo " $USERLIST" | $GREP -v " $uid:">/dev/null;then 
				dirusers="${dirusers}${uid}:${uname}:${uhome} "
			fi
		done
		if [ ! -z "$dirusers" ];then
			USERLIST="${USERLIST}$dirusers"
		fi
	fi
	
	echo ""	
	uc=0
	for ul in $(
		for user in $USERLIST;do
			echo $user
		done | sort -n );do
		if [ $uc -ge 3 ]; then
			echo ""
			uc=0
		fi
		uid=${ul%%:*}
		tail=${ul#*:}	# leaves us with username:/user/path
		un=${tail%%:*}
		loggit -n "[${uid}] $un	"
		let "uc=(uc+1)"
	done
	
	echo ""
	echo 'Enter the user id or user name of the user whose home folder you want '
	echo -n 'to work on. You can also just type in the path directly, if you prefer> '
	read choice
	echo ''
	# check if choice is empty
	if [ -z "$choice" ];then
		loggit "You did not enter anything. Returning to main menu."
		UD=''	# clear user directory and send them back
		return
	fi
	# check if choice is a well-formed directory path
	if echo $choice | grep -q '^/';then
		homedir="$choice"
	else
		# loop through all the users in the USERLIST and look for matches to input
		for user in $USERLIST;do
			uid=${user%%:*}
			tail=${user#*:}	# leaves us with username:/user/path
			uname=${tail%%:*}
			uhome=${tail##*:}
			if [ "$choice" == "$uid" ];then
				homedir="$uhome"
				loggit "for user $uid, the home directory is $uhome"
				break
			else 
				if [ "$choice" == "$uname" ];then
					homedir="$uhome"
					loggit "for username $uname, the home directory is $uhome"
					break
				fi
			fi
		done
	fi
	
	if [ -z "$homedir" ];then
		loggit "${bW}$choice is not a valid user id, user name, or directory. Please try again${eW}"
		err=$EX_ERR
	else
		if [ ! -d "$homedir" ];then
			loggit "${bW}$homedir does not exist. Please try again.${eW}"
			err=$EX_ERR
		fi
	fi
	if [ $err -eq $EX_ERR ];then
		echo ''
		chooseUserDirectory
	else
		UD="$homedir"
	fi
}


function countDown() {
	local count
	if [ -z "$1" ];then
		let count=$DEFAULTDELAY
	else
		count=$1
	fi
	for ((i=1; i <= count ; i++));do
		echo -n ".";
		sleep 1
	done
	echo ""
	return
}


function getUserApproval() {
		local ans
		echo ""
		echo -en "${1} [${bH}y${eH}/${bH}n${eH}]: ${bK}"
		read ans
		echo -e "${eK}"
		echo ""
		if [ "$ans" = "y" ];then
				return $EX_OK
		else
				return $EX_ERR
		fi
} 


function loggit() {
	local nls
	local string
	if [ "$1" = "-n" ];then
		nls="$1"
		string="$2"
	else
		nls=""
		string="$1"
	fi
	echo $nls -e "$string"
	if [ $WRITEABLEROOT -eq 1 ];then
		if  [ -z "$TEMPLOG" ];then
			#	file system is writable and there is nothing in the templog to write to the log
			#	filter out any formatting codes when you put the string into the log.
			echo $nls "$string" | $SED -e 's/\\033\[[0-9]*m//g' | tee -a "$LOGFILE" >/dev/null
		else
			#	file system has become writable and we must dump the templog to the log file
			string=`echo "$string" | $SED -e 's/\\\033\[[0-9]*m//g'` #	strip color codes for log
			TEMPLOG="$TEMPLOG:n:$string" #	Wish wish wish I could find a way to create a newline here
			#	If AppleJack log does not exist, or is greater than 500k, start new log
		 	if [ ! -e "$LOGFILE" ] || [ `/usr/bin/du -k "$LOGFILE" | $AWK '{ print $1 }'` -gt 500 ];then
				echo "Resetting $LOGFILE"
				echo "****************** ${D}:  NEW LOG STARTED ******************" > "$LOGFILE"
				echo "" >> "$LOGFILE"
			fi
			#	keep this on two separate lines so we can capture the line break
			echo "$TEMPLOG" | $SED -e 's/:n:/ \
/g' >> "$LOGFILE"
			#	disable temp logging for future iterations
			unset TEMPLOG
		fi
	else
		#	file system is not writeable, doing temp logging
		string=`echo "$string" | $SED -e 's/\\\033\[[0-9]*m//g'` #	strip color codes for log
		TEMPLOG="$TEMPLOG $string"
	fi
}

# Not implemented, but a way to test mounting in real time rather than with 
# a status variable such as WRITEABLEROOT
# Snow Leopard: when mounted read-only, mount reports: 
# root_device on / (hfs, local, read-only, journaled)
# when mounted read/write, it reports:
# /dev/disk0s2 on / (hfs, local, journaled) 
# of course, one can always try to touch a file, like during the init of this 
# script.
function writable() {
	mount | while read -r line; do
		hit=`echo $line | grep 'root_device' | grep 'read-only'`
		if [ ! -z "$hit" ];then
			loggit "root disk mounted read only"
			return $EX_ERR
		fi
	done
	loggit "root disk mounted read+write"
	return $EX_OK
}

function mountem() {
	if [ -z "$WRITEABLEROOT" ];then
		WRITEABLEROOT=0
	elif [ $WRITEABLEROOT -eq 1 ];then
		loggit "Root file system already mounted. Continue."
		return 0
	fi
	loggit "Let's mount the startup file system for write access..."
	if $MOUNT -vuw /;then
		WRITEABLEROOT=1
		if [ -f /etc/fstab ]; then
			loggit "Mounting local filesystems in fstab"
			$MOUNT -vat nonfs
		fi
		loggit "Done."
		loggit -n "Checking for /tmp directory: "
		if [ -d "/tmp" ];then
			loggit "/tmp directory exists."
		else
			loggit "${bW}/tmp directory does not exist${eW}"
			if [ ! -d "/private/tmp" ];then
				loggit "${bW}/private/tmp does not exist either${eW}"
				loggit -n "Creating /private/tmp: "
				$MKDIR -v "/private/tmp" | $TEE -a "$LOGFILE"
				loggit -n "Setting correct permissions: "
				$CHMOD -v 1777 "/private/tmp" | $TEE -a "$LOGFILE"
			fi
			loggit -n "Creating symbolic link from /tmp to /private/tmp: "
			$LN -sv "/private/tmp" "/tmp" | $TEE -a "$LOGFILE"
			if [ -d "/tmp" ];then
				loggit "All set."
				SANDBOX="/tmp"
				cd "$SANDBOX"
			else
				loggit "${bW}Could not create /tmp directory. Something seems to be wrong "
				loggit "with your file system. Proceed with caution${eW}"
			fi
		fi
		loggit "Done."
	else
		loggit "${bE}Root file system could not be mounted. Script must quit.			  ${eE}"
		exit $EX_OSERR
	fi
	echo ""
	return 0
}


function services() {
	if [ -z "$SERVICES" ];then
		SERVICES=0	# Start assuming services have not been loaded
	elif [ "$SERVICES" -eq 1 ];then
		loggit "- All supporting services appear to be loaded."
		return 0	# return success: services have been started
	fi
	# otherwise, check
	case "$ANIMAL" in
		4) 	
			cs="diskarbitrationd configd memberd notifyd securityd lookupd DirectoryService"
			;;
		5) 	
			cs="launchd notifyd configd syslogd distnoted DirectoryService diskarbitrationd kdcmond KernelEventAgent securityd"
			;;
		6) 	
			cs="launchd notifyd configd syslogd distnoted DirectoryService diskarbitrationd KernelEventAgent securityd"
			;;
	esac

	pss=`ps -axco command`
	m=0
	ct=0
	for c in $cs;do
		let "ct=$ct+1"
		for ps in $pss;do
			if [ "$c" = "$ps" ];then
				let "m=$m+1"
				break
			fi
		done
	done
	if [ $ct -eq $m ];then
		SERVICES=1
		loggit "- All supporting services appear to be loaded."
		return $EX_OK	# return true
	fi
	loggit "- All supporting services are not loaded."
	return $EX_ERR	# return false
}

function startServices() {
	if services; then
		return 0
	fi

	# make sure file system is mounted for read/write access
	mountem

	case "$ANIMAL" in 
		4 ) 
			loggit "Configuring minimal Tiger services..."
			(
				SafeBoot='-x'
				export -n SafeBoot

				# Create mach symbol file
				sysctl -n kern.symfile
				if [ -f /mach.sym ]; then
					ln -sf /mach.sym /mach
				else
					ln -sf /mach_kernel /mach
				fi

				echo "Configuring kernel extensions for safe boot"
				touch /private/tmp/.SafeBoot
				# $KEXTD -x
				# c=don't use repositories, -v 1 =quiet, print only errors
				# x=run in safe boot mode
				$KEXTD -c -v 1 -x

				echo "Loading basic launchd services..."
				(
					launchctl load /System/Library/LaunchDaemons/com.apple.syslogd.plist
					launchctl load /etc/mach_init.d/notifyd.plist
					wait
					syslog -c 0 -p
					# throw syslog output away from the screen
					syslog -x /dev/null >/dev/null
					wait 
					for plist in configd coreservicesd DirectoryService diskarbitrationd distnoted hdiejectd kuncd lookupd mds memberd notifyd scsid securityd translated; do
						launchctl load /etc/mach_init.d/${plist}.plist > /dev/null 2>&1 &
						wait
					done
					for plist in com.apple.KernelEventAgent com.apple.nibindd; do
						launchctl load /System/Library/LaunchDaemons/${plist}.plist > /dev/null 2>&1 &
						wait
					done
				) 2>&1>/dev/null &
				wait
			) 2>&1>/dev/null &
			wait
			;;
		5 ) 
			loggit "Configuring minimal Leopard services..."
			(
				SafeBoot='-x'
				export -n SafeBoot

				echo "Configuring kernel extensions for safe boot"
				touch /private/tmp/.SafeBoot

				# launchd is handling kextd startup in Leopard
				# but we can't configure it with the plist
				# launchctl load /System/Library/LaunchDaemons/com.apple.kextd.plist
				# $KEXTD -x
				# c=don't use repositories, v 1 =quiet, print only errors
				# x=run in safe boot mode
				$KEXTD -c -v 1 -x

				############################################################
				# Many thanks to Steve Anthony for his substantial effort in
				# figuring out the startup sequence for Leopard.
				############################################################
				echo "Loading basic launchd services..."
				(
					launchctl load /System/Library/LaunchDaemons/com.apple.notifyd.plist
					launchctl load /System/Library/LaunchDaemons/com.apple.configd.plist
					launchctl load /System/Library/LaunchDaemons/com.apple.syslogd.plist
					wait
					syslog -c 0 -p
					# throw syslog output away from the screen
					syslog -x /dev/null >/dev/null
					wait 
					for plist in  com.apple.coreservicesd com.apple.DirectoryServices com.apple.DirectoryServicesLocal com.apple.diskarbitrationd com.apple.kdcmond com.apple.distnoted com.apple.hdiejectd com.apple.notifyd com.apple.scsid com.apple.securityd com.apple.KernelEventAgent com.apple.installdb.system; do
						launchctl load /System/Library/LaunchDaemons/${plist}.plist > /dev/null 2>&1 &
						wait
					done
				) 2>&1>/dev/null &
				wait
			) 2>&1>/dev/null &
			wait
			;;
		6 ) 
			loggit "Configuring minimal Snow Leopard services..."
			(
				# Probably going overboard here with the environment variable
				# AND the flag, but I can't see the logic of how it's being read
				# down the line, so playing it safe.
				SafeBoot='-x'
				export -n SafeBoot
				
				echo "Configuring kernel extensions for safe boot"
				touch /private/tmp/.SafeBoot
				# launchctl load /System/Library/LaunchDaemons/com.apple.kextd.plist
				# launchd should be handling kextd startup in Leopard
				# but we can't configure it with the plist
				# c=don't use repositories, q=quiet, print only errors
				# x=run in safe boot mode
				$KEXTD -c -q -x
				
				############################################################
				# Many thanks to Steve Anthony for his substantial effort in
				# figuring out the startup sequence for Snow Leopard.
				############################################################
				echo "Loading basic launchd services..."
				(
					launchctl load /System/Library/LaunchDaemons/com.apple.notifyd.plist
					launchctl load /System/Library/LaunchDaemons/com.apple.configd.plist
					launchctl load /System/Library/LaunchDaemons/com.apple.syslogd.plist
					wait
					syslog -c 0 -p
					# throw syslog output away from the screen
					syslog -x /dev/null >/dev/null
					wait 
					for plist in  com.apple.kuncd com.apple.KernelEventAgent com.apple.distnoted com.apple.aslmanager com.apple.DirectoryServices com.apple.DirectoryServicesLocal com.apple.coreservicesd com.apple.diskmanagementd com.apple.securityd com.apple.diskarbitrationd com.apple.fseventsd; do
						launchctl load /System/Library/LaunchDaemons/${plist}.plist > /dev/null 2>&1 &
						wait
					done
				) 2>&1>/dev/null &
				wait
			) 2>&1>/dev/null &
			wait
			;;
		* )
			;;
	esac
	echo ""
	echo "Waiting for services to start..."
	echo ""
	sleep 15
#	loggit "Done. -${exit_status}-"
	loggit "Done."
	SERVICES=1
	loggit ""
	echo ""
	return
}


function progress() {
	local process="$1"
	local message="$2"
	local sleeptime=$3
	local mLength=`echo $message | wc -m`
	let "mLength=(mLength-1)"
	let "line=(67-mLength)"
	local dot=0
	echo -n "$message"
	sleep $sleeptime
	local ps=`ps -ax | $GREP "$process" | $GREP -v 'grep'`
	while [ ! -z "$ps" ];do
		if [ $dot -ge $line ];then
			echo ""
			echo -n "$message"
			let "dot=0"
		else
			echo -n "."
			let "dot=(dot+1)"
		fi
		sleep $sleeptime
		ps=`ps -ax | $GREP "$process" | $GREP -v 'grep'`
	done
}


function repairDisks() {
	local drc	# disk repair count
	local exit_status
	local taskDescription	# task description
	local options	# options to pass to fsck
	local redo	# redo disk repair?
	local speedup
	loggit -n "Disk repair"
	countDown
	#	set disk repair count if not passed
	if [ -z $1 ];then
		drc=0
	fi
	if [ $WRITEABLEROOT -ne 0 ];then
		loggit "${bW}Root disk has already been mounted for write access${eW}"
		echo "If you want to repair the disk, restart into single user mode and "
		taskDescription=`echo ${TASKNAMES[1]} | $SED -e 's/\\\033\[[0-9]*m//g'`
		echo "choose '$taskDescription' as your first task."
		loggit "Disk repair aborted."
	else
		#		if [ $JOURNALED -eq 1 ];then
		#			options=' -f'
		#		else
		#			options=''
		#		fi
		#		if /sbin/fsck -y${options};then
		if /sbin/fsck -y -f;then
			exit_status=$?
			#	No problems found
			loggit "Success! Either your disk had no errors, or it was repaired "
			loggit "successfully."
			echo "(If you were prompted to restart, you can ignore that for now.)"
			echo ""
			loggit "Done with disk repairs -${exit_status}-"
		else
			exit_status=$?
			let "drc=($drc+1)"
			#	Problems found
			loggit "Some errors were found that were not repaired. You should "
			loggit "attempt to repair the disk again. -${exit_status}-"
			if [ $AUTO -gt 0 ];then
				loggit -n "AppleJack will try to repair the disk again in $CANCELTIME seconds. [${bH}c${eH}ancel] ${bK}"
								#	Define different REPLY variable for different task
				read -t $CANCELTIME REPLY[$AUTO] <&1
				echo -en "${eK}"
				if [ -z "${REPLY[$AUTO]}" ];then
					#	Block auto mode from running more than DRL disk repair 
										# attempts.
					if [ $drc -ge $DRL ];then
						echo ""
						echo ""
						loggit "AppleJack has attempted $drc disk repairs without success. ${bW}Apple's "
						loggit "standard disk repair utility is having trouble making the necessary "
						loggit "repairs${eW} You might want to consider using other tools such as Disk "
						loggit "Warrior${bPar}tm${ePar} or TechTool Pro${bPar}tm${ePar}."
						redo="n"
					else
						redo="y"
					fi
				else
					redo="n"
				fi
			else
				#	Tell user to maybe give up if more than DRL attempts have been made.
				if [ -z $speedup ];then
					speedup=0
				fi
				let "manualLimit=($DRL + $speedup)" 
				if [ $drc -ge $manualLimit ];then
					echo ""
					echo -e "You have attempted $drc repairs without success. ${bW}Apple's standard disk "
					echo -e "repair utility is having trouble fixing this disk${eW} You might want to "
					echo "consider using other tools such as Disk Warrior${bPar}tm${ePar} or TechTool Pro${bPar}tm${ePar}."
					#	post warning more frequently now, but not every time
					let "speedup=(($manualLimit / 2) +1)"	
					echo ""
				fi
				if getUserApproval "Repeat disk repair?";then
					redo="y"
				else
					redo="n"
				fi
			fi
			if [ "$redo" = "y" ]; then
				repairDisks $drc
			else
				loggit "${bW}Disk repair aborted. The disk directory is not healthy${eW}"
				echo "We recommend you repair the disk before doing anything else."
				#	only do this if in auto mode
				if [ $AUTO -ne 0 ];then 
					echo -e "${bW}As a precaution, AppleJack will now exit automatic mode${eW}"
					AUTO=0
				fi
			fi
		fi 
	fi
}


function validatePreferences() {
	# boolean(y/n): should we check user prefs
	local checkUserPrefs
	loggit -n "Validating preference files"
	countDown
	#	Make sure disks are mounted and writable first
	mountem	
	if [ -d '/private/etc/mach_init.d' ];then
		loggit "Checking mach init preference files ${bPar}/etc/mach_init.d${ePar}: "
		prefCheck '/private/etc/mach_init.d'
		loggit "Done. -$?-"
		loggit ""
	fi
	if [ -d '/private/var/db/SystemConfiguration' ];then
		loggit "Checking system configuration files ${bPar}/var/db/SystemConfiguration${ePar}: "
		prefCheck '/private/var/db/SystemConfiguration'
		loggit "Done. -$?-"
		loggit ""
	fi
	if [ -d '/private/var/root/Library/Preferences' ];then
		loggit "Checking root preference files ${bPar}/var/root/Library/Preferences${ePar}: "
		prefCheck '/private/var/root/Library/Preferences'
		loggit "Done. -$?-"
		loggit ""
	fi
	if [ -d '/Library/Preferences' ];then
		loggit "Checking system preference files ${bPar}/Library/Preferences${ePar}: "
		prefCheck '/Library/Preferences'
		loggit "Done. -$?-"
		loggit ""
	fi
	#	Only run this option if auto mode is off.
	if [ $AUTO -eq 0 ];then
		if getUserApproval "Would you like to find and remove corrupted preference files for any specific user?";then
			checkUserPrefs="y"
		else
			checkUserPrefs="n"
			loggit "User preference files untouched."
		fi
		while [ "$checkUserPrefs" = "y" ];do
			#	This function sets the value for UD, user directory
			chooseUserDirectory
			# if UD is empty, act as if the user has changed their mind
			if [ -z "$UD" ];then
				checkUserPrefs='n'
			else
				if [ -d "$UD/Library/Preferences" ];then
					loggit "Checking the preference files in $UD/Library/Preferences"
					prefCheck "$UD/Library/Preferences"
					loggit "Done. -$?-"
				else
					loggit "${bE}$UD/Library/Preferences does not exist!${eE}"
					echo 'Skipping this task.'
				fi
				if ! getUserApproval 'Would you like to find and remove corrupted preference files for another user?'; then
					checkUserPrefs='n'
				fi
			fi
		done
	fi
}
function prefCheck() {
	local owd=`pwd`
	local folder="$1"
	local qFolder="$1 ${bPar}Corrupt${ePar}"
	local badPrefs	# list of bad preference files
	local filesMoved	# (int) how many preference files were moved?
	local tBP	# list of bad preference files (temporary)
	local bp	# name of bad preference file
	local bpDir	# path to the bad preference file
	local rVal	# (int) return value: either 0 or 1
	
	cd "$folder"

	if [ -z "$2" ];then
		badPrefs=`find . -type f \( -name "*.plist" \) -print0 | xargs -0 $PLUTIL -s`
	elif [ "$2" = "xml" ];then
		badPrefs=`find . -type f \( -name "*.plist" -o -name "*.xml" \) -print0 | xargs -0 $PLUTIL -s`
	fi
	#	This is kind of crummy to have to use the \x00 kluge, but I see no better
	# way at present
	badPrefs=`echo $badPrefs | $SED -e "s#:[^/]*#:#g" -e "s/ /\x00/g" -e "s/:/ /g"`
	if [ "$badPrefs" != "" ];then

		if [ ! -d "$qFolder" ]; then
			$MKDIR "$qFolder" #	Is there a better place for this?
			$CHMOD 777 "$qFolder" #	Don't want a user stuck with a folder they can't delete
			#	Is this a possible security problem? No, because all preferences folders
			# are already readable by everyone [except /var/root/Library/Preferences]
		fi
		filesMoved=0
		for tBP in $badPrefs;do 
			#	Convert to usable form for processing. Remove any leading dot. (Usually
			# only the first corrupt preference file will have this).
			bp=`echo $tBP | $SED -e 's/\x00/\ /g' -e 's/&/\&/g' -e 's/^\.//'`
			#	Create path at which the preference file should live.
			# TODO find a way to make this parse even if there are slashes in the filename
			bpDir=`echo $bp | $SED -e 's/\/[^\/]*$//'`; 

			#	No need to check for sym or hard links, as plutil correctly follows them
			# to the source file
			#	checkAlias returns 1 if file is an alias; 0 if not.
			if checkAlias ".$bp" ; then
				loggit "Corrupt preference file: .$bp"
				loggit "--> Moving to ${qFolder}${bpDir}"
				if [ ! -d '${qFolder}${bpDir}' ];then
					$MKDIR -p "${qFolder}${bpDir}"
				fi
				$MV ".$bp" "${qFolder}${bpDir}"
				let "filesMoved=$filesMoved+1"
			fi
		done
		echo ""
		if [ $filesMoved -lt 1 ]; then
			rVal=$EX_OK
			#	Since no corrupt files were moved, attempt to remove directory.
			#	This will fail in cases where files were moved on a previous run, in
			#	which case we just want it to fail silently, and leave the directory
			#	in place. This situation is currently only applicable in cases that 
			#	involve aliases.
			$RMDIR "$qFolder" 2>/dev/null
		elif [ $filesMoved -eq 1 ]; then
			loggit "One corrupt preference file was moved."
			rVal=$EX_ERR
		else
			loggit "$filesMoved corrupt preference files were moved."
			rVal=$EX_ERR
		fi
		#	Return to old location
		cd "$owd"
		return $rVal
	fi	
}


function cleanupVM() {
	loggit -n "Virtual memory cleanup"
	countDown
	mountem	#	Make sure disks are mounted first
	if [ ! -d "$swapdir" ];then
		loggit "The virtual memory directory $swapdir does not exist. Please "
		loggit "ensure that a correct location has been specified in /etc/rc "
		loggit "and that the virtual memory directory actually exists. "
		loggit "Virtual memory cleanup aborted."
	else
		cd "$swapdir"
		if [ $? -eq 0 ] && [ `pwd` = "$swapdir" ];then #	double check this
			loggit -n "Removing swap files: "
			$RM -vfd "${swapdir}/"swapfile* | tee -a "$LOGFILE"
			loggit "Done."
			echo ""

			# Should only be applicable to system versions >= 10.4
			if [ -d "app_profile" ];then
				cd "app_profile"
				# remove app_profile contents
				loggit -n "Removing VM working sets: "
				$RM -vf "${swapdir}/app_profile/"*
				loggit "Done."
				echo ""
			fi

			# Should only be applicable to system versions >= 10.4
			# TODO: move this to advanced mode?
			#	Only run this option if automode is off.
			if [ $AUTO -eq 0 ] && [ -e "sleepimage" ];then
				if getUserApproval "Would you like to delete your safe sleep image?";then 
					# remove sleepimage
					loggit -n "Removing the safe sleep image: "
					$RM -vf "${swapdir}/"sleepimage | tee -a "$LOGFILE"
					loggit "Done."
					echo ""
				fi
			fi
		else
			loggit "Could not change working directory to $swapdir."
			loggit "Virtual memory cleanup has been aborted."
		fi
		cd "$SANDBOX"
	fi
}


function cacheCleanup() {
	local cf	# cache file
	local cleanUserCache	# (boolean) should the user cache be cleaned [y/n]
	local cachedir	# (string) user cache directory 
	local keep_going	# (boolean) continue processing directories? [0/1]

	loggit -n "Cache file cleanup"
	countDown
	mountem	#	Make sure disks are mounted first

	loggit -n "Removing system cache files: "
	#	-v option makes the rm command verbose
	if [ -d "/System/Library/Caches" ];then
		find /System/Library/Caches/* -exec $RM -Rvf {} \; 2>/dev/null | tee -a "$LOGFILE"
	fi
	if [ -d "/Library/Caches" ];then
		if [ "$DEEP" -eq "1" ]; then
			find /Library/Caches/* -exec $RM -Rvf {} \; 2>/dev/null | tee -a "$LOGFILE"
		else
			find /Library/Caches/* ! -name 'com.apple.LaunchServices*' ! -name 'com.apple.user*pictureCache.*' ! -name 'com.apple.dock.iconcache*' -exec $RM -Rvf {} \; 2>/dev/null | tee -a "$LOGFILE"
		fi
	fi
	if [ -d "/private/var/root/Library/Caches" ];then
		find "/private/var/root/Library/Caches/*" -exec $RM -Rvf {} \; 2>/dev/null | tee -a "$LOGFILE"
	fi
	for cf in "/private/var/db/volinfo.database" "/private/var/db/BootCache.playlist" "/private/var/db/prebindOnDemandBadFiles" "/System/Library/Extensions.kextcache" "/System/Library/Extensions.mkext"; do
		if [ -f "$cf" ];then
			$RM -fv "$cf" 2>/dev/null | tee -a "$LOGFILE"
		fi
	done
	loggit "Done removing system cache files."
	loggit ""
	if [ $AUTO -eq 0 ];then #	Only run this option if auto mode is off.
		if getUserApproval "Would you like to find and remove known cache files for a specific user?";then
			cleanUserCache="y"
		else
			cleanUserCache="n"
			loggit "User cache files untouched."
		fi
		while [ "$cleanUserCache" = "y" ];do
			chooseUserDirectory
			cachedir="${UD}/Library/Caches"
			if [ -d "$cachedir" ];then
				cd "$cachedir"
				if [ $? -eq 0 ] && [ `pwd` = "$cachedir" ];then	#	Double check we're in the right place
					loggit "Removing files in $cachedir:"
					if [ "$DEEP" -eq "1" ];then
						$RM -Rvf "${cachedir}/"* 2>/dev/null | tee -a "$LOGFILE"	#	Silence error output on empty directories
					else	#	Currently, the commands here are identical
						$RM -Rvf "${cachedir}/"* 2>/dev/null | tee -a "$LOGFILE"
					fi
					keep_going=1
					loggit "Done. -$?-"
				else
					loggit "Unable to switch to $cachedir for processing."
					loggit "Directory appears to be invalid."
					keep_going=0
				fi
				cd "$SANDBOX"
			else
				loggit "$cachedir does not exist or is not a valid directory."
				keep_going=0
			fi
			if ! getUserApproval "Would you like to find and remove known cache files for another user?";then
				cleanUserCache="n"
			fi
		done
	fi
	loggit "Done with cache file clean up task."
	loggit ""
}


function fixPermissions() {
	loggit -n "Permissions repair"
	countDown
	startServices	# We need to start up supporting services for this
	echo "Repairing permissions"
	echo "${bPar}Depending on operating system, disk size, and processor speed this can"
	echo "take up to 30 minutes. Please wait.${ePar}:"
	progress diskutil "+" 5 &
	diskutil repairPermissions / | tee -a "$LOGFILE"
	wait
	# TODO: Fix this exit status. This is bogus, since it's actually the result of 
	# the tee operation rather than the diskutil operation.
	loggit "Permissions have been repaired. -$?-"
}


#	Let's find out who this user is
#	id requires launchd services to be running, use whoami instead
function identityCheck() {
	if [ `whoami` != "root" ];then
		return $EX_ERR	# False [failed]
	else
		return $EX_OK	# True [success]
	fi
}


function restart() {
	loggit -n "Restarting `hostname`"
	countDown
	loggit "$GOODBYE"
	loggit ""
	(reboot &)
}


function quitScript() {
	local exeunt	# How does the user want to exit
	# If user specified automatic restart or shutdown at runtime, quit automatically.
	case "$1" in
		'restart')
			exeunt='r'
			;;
		'shutdown')
			exeunt='h'
			;;
		*)	#	Else, quit manually
			echo ""
			loggit "${eK}Exiting the script."
			echo "If you have modified the disk at all, you should restart the computer "
			echo "before continuing to work."
			echo -en "Would you like to ${bH}r${eH}estart your computer, or s${bH}h${eH}ut down? ${bK}"
			read exeunt
			echo -en "${eK}"
			;;
	esac

	# Clean up items go here
	# Turn syslog master filter off, in case startServices changed it.
	syslog -c 0 off

	case "$exeunt" in
		"r" | "R")
			restart
			exit $EX_OK
			;;
		"h" | "H")
			shutDown
			exit $EX_OK
			;;
		*) 
			loggit "$GOODBYE"
			echo "${bPar}To restart your computer from the command line, just type 'reboot'${ePar}"
			loggit ""
			exit $EX_OK
			;;
	esac
}


function selectNext()  {
	ANS="NOT_NULL" #	We set this to keep it from being null at the outset
	echo ""
	if [ -z "$AUTO" ];then #show this option only first time through.
		echo -e "$BANNER"
		echo ""
		echo "Enter the associated number or letter to select the next task."
		echo -e "It is ${bS}strongly${eS} recommended you do them in the order listed!"
		echo ""
		echo -e "[${bK}${TASKCODES[0]}${eK}] ${TASKNAMES[0]}. AppleJack will do all tasks sequentially."
		echo ""
		AUTO=0	#	and set AUTO, so it won't show again
	elif [ $AUTO -eq 0 ];then	#	Only show this if not first time, and not in auto mode.
		echo -e "$BANNER"
		echo ""
		echo "Choose the next task..."
		echo ""
	fi
	if [ $AUTO -eq 0 ];then	#	Only show menu if Auto is not running
		#	Really wish bash supported multi-dimensional arrays
		I=1
		let "TASKLIST=${#TASKS[@]}-1"
		while [ "$I" -lt "$TASKLIST" ];do	#	We want to list quit option in a separate format
			echo -e "[${bK}$I${eK}] ${TASKNAMES[$I]}"; 
			let "I=$I+1"
		done
		echo ""
#		echo -e "[${bK}X${eK}] : E${bK}x${eK}pert Tasks."
		echo ""
		echo -en "Your choice ${bPar}Just hit return to quit${ePar}: ${bK}"
		read ANS
		echo -en "${eK}"
	else	#	AUTO MODE
		ANS=$AUTO
		echo ""
		let "AUTO=$AUTO+1"	#increment AUTO
		if [ $AUTO -gt 1 ];then	#	Only give these options if returning to the menu from another task.
			if [ "$AUTO" -eq "${#TASKS[@]}" ];then	#	We're at the last item, which is quit
				# If user specified automatic restart or shutdown at runtime, quit using their choice.
				echo "AppleJack has finished.";
				quitScript "$POSTSCRIPT"
			else
				echo "AppleJack auto mode: selecting task $ANS"
				taskDescription=`echo ${TASKNAMES[$ANS]} | $SED -e 's/\\\033\[[0-9]*m//g'`
				loggit "AppleJack will ${bS}${taskDescription}${eS} in $CANCELTIME seconds. "
				echo -en "[${bH}s${eH}kip this task/${bH}q${eH}uit AppleJack]${bK} "
				read -t $CANCELTIME RESP[$AUTO] <&1	# Set different reply depending on which step is being done.
				echo -ne "${eK}"
				if [ ! -z "${RESP[$AUTO]}" ];then	# Guess I could also just reset the variable to null each time.
					case "${RESP[$AUTO]}" in
						"s" | "S")
							echo ""
							loggit "${TASKNAMES[$ANS]} skipped."
							selectNext
							;;
						*) # Set to null so we quit later.
							ANS=""
							;; 
					esac
				fi
			fi
		fi
		echo ""
	fi
	if [ ! -z "$ANS" ];then	#	If user doesn't want to quit, continue
		I=0
		let "TASKCOUNT=${#TASKNAMES[@]}"
		while [ "$I" -lt "$TASKCOUNT" ];do
			if [[ "$ANS" = "${TASKCODES[$I]}" || "$ANS" = "$I" || "$ANS" = "${TASKCODESUC[$I]}" ]];then
				eval "${TASKS[$I]}"	#	Run associated task
				selectNext
			fi
			let "I=$I+1"
		done
		#	If you're here, you're probably wanting the expert menu, or you typed a 
		# wrong key
		if [[ "$ANS" = "x"  || "$ANS" = "X" ]]; then
			expertMenu
		else
			echo "Ooops! Looks like you typed the wrong key."
			selectNext
		fi
	else	#	Let user quit, if they want to
		quitScript
	fi
}


function shutDown() {
	loggit -n "Shutting down `hostname`"
	countDown
	loggit "$GOODBYE"
	loggit ""
	(shutdown -h now &)
}


function uninstall() {
	if getUserApproval "You are about to uninstall AppleJack. Are you sure?";then
		loggit "*********************** Uninstalling AppleJack ***********************"
		mountem
		# get script name, from expanded alias, just in case it's been modified.
#		thisAJ=`echo $0 | sed -e 's#^\.##'`
		local thisAJ="$0"	# (string) location of this script
		local defaultAJ='/private/var/root/Library/Scripts/applejack.sh'	# (string) the default location of this script
		# add current working directory
		local rootProfile='/private/var/root/.profile'	# (string) location of the root profile
		local manPage='/usr/share/man/man8/applejack.8'	# (string) default location of the AppleJack man page
		local tmp='/private/tmp/applejack.install'	# location of temp file for uninstalling AppleJack
		# Set exit code to ok, to begin with
		local uEC=$EX_OK	# eventual exit code to be returned
		
		if [ -e "$thisAJ" ];then
			loggit -n "found AppleJack script. Removing: "
			$RM -fv "$thisAJ" | tee -a "$LOGFILE"
			echo ""
		else
			loggit "could not find the invoked AppleJack script ${bPar}$thisAJ${ePar}."
			loggit "will try default location ${bPar}$defaultAJ${ePar}..."
			if [ -e "$defaultAJ" ];then
				loggit -n "found! Removing: "
				$RM -fv "$defaultAJ" | tee -a "$LOGFILE"
			else
				loggit "Not found! AppleJack script could not be removed."
				uEC=$EX_USAGE	# user error
			fi
		fi

		loggit "Removing AppleJack Documentation:"
		if [ -d "/Library/Documentation/AppleJack" ];then
			cd "/Library/Documentation"
			loggit -n "-removing documentation from /Library/Documentation: "
			$RM -Rfv "AppleJack" | tee -a "$LOGFILE"
			cd "$SANDBOX"
		fi
		loggit -n "-removing AppleJack man caches: "
		find /usr/share/man -name 'applejack.*.gz' -exec $RM -v {} \; | tee -a "$LOGFILE"
		loggit ""
		loggit -n "-removing AppleJack man pages: "
		find /usr -type f \( -name 'applejack.8' -o -name 'applejack.1' \) -exec $RM -fv {} \; | tee -a "$LOGFILE"
		loggit ""
		loggit "Done."
		
		if [ -d "/Library/Receipts/AppleJack.pkg" ];then
			loggit -n "Deleting the installer receipt: "
			cd "/Library/Receipts"
			$RM -Rfv "AppleJack.pkg" | tee -a "$LOGFILE"
			cd $SANDBOX
			loggit "Done."
		fi

		if [ -f "$rootProfile" ];then
			loggit -n "Restoring the root profile: "
			$SED -e '/[aA]pple[jJ]ack/d' "$rootProfile" > "$tmp"
			$RM -fv "$rootProfile"
			$MV -v "$tmp" "$rootProfile" | tee -a "$LOGFILE"
			loggit "Done."
		fi

		if [ "$uEC" -ne "$EX_OK" ]; then
			loggit "AppleJack was not completely uninstalled. The AppleJack program could"
			loggit "not be found. Sorry."
		else 
			loggit "AppleJack is uninstalled."
		fi
		loggit "$GOODBYE"
		
		exit $uEC
	else
		loggit "Uninstall aborted. AppleJack will now quit."
		exit $EX_OK;
	fi
}

########################################################################
#	EXPERT FUNCTIONS UNDER DEVELOPMENT #################################
########################################################################
function xBlessDrive() {
	mountem	#	Make sure disks are available for r/w
	loggit "Bless Drive"
	#	countDown 5
	# sets global variable $blessthis
	if ! _xPickSystemFolder; then
		return $EX_ERR
	fi
	loggit "Blessing $blessthis"
	if getUserApproval "Would you also like to start up from $blessthis on restart?";then
    #    Set current startup disk to <disk>.
		# systemsetup -setstartupdisk <disk>
		local sb='--setBoot'
		local fb="bless and startup from"
		local fbs="blessed and can be used at restart."
	else
		local sb=''
		local fb="bless"
		local fbs="blessed"
	fi
#	local out=`$BLESS -folder9 "$os9sf" "$use9"  2>&1`
#	local out=`$BLESS --folder "$blessthis" --bootinfo --bootefi $sb --verbose`
	local out=`$BLESS --folder "$blessthis" $sb`
	local res=$?
	if [ "$res" -ne "0" ];then
		loggit "Could not $fb $blessthis because: "
		loggit "$out"
	else
		loggit "System folder $fbs. $out"
	fi
	loggit "Done."
}
function _xPickSystemFolder() {
	local folderToBless	# (string) The path of the folder we want to bless
	local device
	local nom
	local index=0
	local ANS
	local a
	local chosen
	mountem
	startServices
	echo "- Loading information for attached disk(s)..."
	# get the device names with Apple_HFS partitions, and remember them
	if [ -z "$devices" ] || [ -z "$device_names" ];then
		for device in `diskutil list | awk '/Apple_HFS/ { print $NF }'`;do
			let "index=$index+1"
			# grab the volume name in an accurate way, even if spaces or odd chars
			nom=`diskutil info $device | grep 'Volume Name:' | cut -f 2 -d ':' | sed 's/^ *//'`;
			device_names[$index]=$nom
			devices[$index]=$device
		done
	fi
	for ((a=1; a <= $index; a++));do
		echo -e "[${bK}$a${eK}]	${device_names[$a]} on ${devices[$a]}"
	done
	while [ -z "$chosen" ];do
		echo -en "Enter the number of the disk you want to bless: ${bK}"
		read ANS
		echo -en "${eK}"
		if [ -z "$ANS" ];then
			echo "Looks like you have changed your mind. Giving up."
			return $EX_USAGE
		fi
		for ((a=1; a <= $index; a++));do
			if [ "$ANS" = "$a" ];then
				chosen=$ANS
				break
			fi
		done
		if [ -z "$chosen" ];then
			echo "$ANS is not in the list of disks. Try again."
		fi
	done
	echo "You chose ${device_names[$chosen]} on ${devices[$chosen]}"
	if ! mount | $GREP "${devices[$chosen]} on" >/dev/null;then
		echo -n "/dev/${devices[$chosen]} is not mounted. Mounting..."
		# mount the device
		diskutil mount /dev/${devices[$chosen]}
		echo " Done."
	fi
	# we can't be sure there was no whitespace in the disk name beginning or end, so
	folderToBless=`$LS -d /Volumes/*/System/Library/CoreServices | grep "${device_names[$chosen]}"`
	if [ ! -d "$folderToBless" ]; then
#	if [ -d "/Volumes/${device_names[$chosen]}/System/Library/CoreServices" ];then
		echo ""
		echo "There is no system folder on ${device_names[$chosen]}. Please choose another device."
		echo ""
		if ! _xPickSystemFolder;then
			return $EX_USAGE
		fi
	fi
	blessthis="$folderToBless" # blessthis is the global variable to set
	return $EX_OK
#	(
#		IFS=$'\n'
#		index=0
#		sysfolders=()
#		echo "Searching for available system folders..."
#		sys=($(find / -maxdepth 3 -type d -name "System" 2>/dev/null ))
#		sysindex=${#sys[@]}
#		for (( i=0; i<${sysindex};i++)); do 
#			if [ -d "${sys[$i]}/Library/CoreServices" ];then
#				let "index=index+1"
#				echo "[${bK}${index}${eK}]		${sys[$i]}/Library/CoreServices"
#				sysfolders[$index]="${sys[$i]}/Library/CoreServices"
#			fi
#		done
#		echo ">${sysfolders[0]}"
#		echo ">${sysfolders[1]}"
#	)
}


#	This will remove cached items at the machine and system level, with the option
# to do the same at the user level
function xDeepCacheClean() {
	echo 'Choosing this option allows you to perform a deep cache clean mode
without having to run AppleJack in auto mode. Deep cache clean differs
from the normal cache clean in that it also removes the user icon 
caches and the launch services database in /Library/Caches.
'
	if getUserApproval 'Proceed with deep cache cleaning?';then
		loggit "Deep cache clean. ${bPar}Also available in AUTO mode.${ePar}"
		DEEP=1	# global variable
		cacheCleanup
	fi
}


function xDisableAutoLogin() {
	echo 'Disabling auto login forces all users to log in before accessing their 
accounts. This can be useful if the computer crashes or hangs during 
an automatic login to a user account.'
	if getUserApproval 'Are you sure you want to disable auto login?';then 
		mountem	#	Make sure disks are available for r/w
		loggit -n "Disabling auto login"
		countDown 5
		local wasEnabled=0
		local xDAL_SUCCESS=1	# Assume error
		local eMsg=''
		local xDAL_steps
		case "$ANIMAL" in
			[4-6]* ) xDAL_steps=0
				if defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser &> /dev/null;then
					xDAL_steps=1
					wasEnabled=1
					if defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUser >>"$LOGFILE" 2>&1;then
						let "xDAL_steps=($xDAL_steps-1)"
					fi
				fi
				if defaults read /Library/Preferences/com.apple.loginwindow autoLoginUserUID &> /dev/null;then
					wasEnabled=1
					let "xDAL_steps=($xDAL_steps+1)"
					if defaults delete /Library/Preferences/com.apple.loginwindow autoLoginUserUID >>"$LOGFILE" 2>&1;then
						let "xDAL_steps=($xDAL_steps-1)"
					fi
				fi
				if [ $xDAL_steps -eq 0 ];then
					xDAL_SUCCESS=$EX_OK
				else
					eMsg='Could not delete the autoLoginUser and autoLoginUserUID keys from com.apple.loginwindow.plist'
				fi;;
			* ) echo 'uh oh. Unsupported OS version.';;
		esac
		if [ $wasEnabled -eq 0 ];then
			loggit "Auto login is not enabled. No need to disable it."
		else
			if [ $xDAL_SUCCESS -eq $EX_OK ];then
				loggit "Auto login was successfully disabled."
			else
				loggit "Error while disabling auto login: $eMsg"
			fi
			loggit "Done -$xDAL_SUCCESS-"
		fi
	else
		loggit "Disabling of auto login aborted."
		xDAL_SUCCESS=$EX_OK	#	There is no error here, just an exit code
	fi
}


function xDisableNFSMounts() {
	echo 'Sometimes a recalcitrant NFS mount in NetInfo will keep Mac OS X from
booting. If you have NFS mounts in NetInfo, and you suspect they might
be causing your computer to not boot, this option might fix that by 
moving the /mounts directory to /disabled/mounts.

(If there is enough interest, I might expand this function to also include
NFS mounts in /etc/fstab.)
'
	if getUserApproval 'Do you wish to continue?';then
		mountem root	#	Make sure disks are available for r/w
		loggit -n "Disabling NFS mounts"
		countDown 5
		local xDNFSM_result	# exit status of this function
		$DSCL -raw "$DSDB" create disabled
		$DSCL -raw "$DSDB" move mounts disabled
		local ES=$?
		if [ $ES -eq 0 ];then
			xDNFSM_result=$EX_OK
			loggit "Success! The netinfo path /mounts has been moved to /disabled/mounts."
		else
			xDNFSM_result=$EX_SOFTWARE
			loggit "Failed! Could not modify move the netinfo /mounts path to /disabled."
		fi
		loggit "Done -$xDNFSM_result-"
	fi
}


function xDisableSysConfigFiles() {
	echo '
Sometimes, the system configuration files will keep the computer from
booting. Generally, this will be the case if one or more of them are
corrupted, but it can also happen if something has been misconfigured.
Generally, AppleJack recommends you first do a preference file check
before running this routine, which will move only corrupted preference
files out of the way. This function is more blunt. It will simply rename 
the various system configuration files and directories by appending 
".old" to the file name or directory name, thus effectively silencing 
them without destroying them. You can restore the files by moving them 
back to their original name.
'
	if getUserApproval 'Would you like to disable your current system configuration files?';then
		mountem root
		loggit -n "Disabling system configuration files"
		countDown 5
		case "$ANIMAL" in
			4)
				loggit "Moving system configuration files from /Library/Preferences/SystemConfiguration to /Library/Preferences/SystemConfiguration.old";
				$MV -v /Library/Preferences/SystemConfiguration /Library/Preferences/SystemConfiguration.old | tee -a "$LOGFILE";
				$MKDIR -v -m 0755 /Library/Preferences/SystemConfiguration | tee -a "$LOGFILE"
				;;
			5)
				loggit "Moving system configuration files from /Library/Preferences/SystemConfiguration to /Library/Preferences/SystemConfiguration.old";
				$MV -v /Library/Preferences/SystemConfiguration /Library/Preferences/SystemConfiguration.old | tee -a "$LOGFILE";
				$MKDIR -v -m 0755 /Library/Preferences/SystemConfiguration | tee -a "$LOGFILE"
				;;
			6)
				loggit "Moving system configuration files from /Library/Preferences/SystemConfiguration to /Library/Preferences/SystemConfiguration.old";
				$MV -v /Library/Preferences/SystemConfiguration /Library/Preferences/SystemConfiguration.old | tee -a "$LOGFILE";
				$MKDIR -v -m 0755 /Library/Preferences/SystemConfiguration | tee -a "$LOGFILE"
				;;
			*) 
				echo "oh oh. unsupported operating system version."
				;;
		esac
		loggit 'Done.'
	fi
}


function xDisableUserLoginItems() {
	echo '
If you suspect the login items in a user account is causing the computer 
to hang or crash, you can use this function to disable the login items. 
This function will first make a backup of the 
~/Library/Preferences/loginwindow.plist file, and then delete the 
AutoLaunchedApplicationDictionary key from the original.
'
	if getUserApproval 'Do you wish to disable the login items for a user account?';then
		local xDULI_success	# the exit status of this function
		mountem root
		loggit -n "Disable login items for which user?"
		echo ""
		chooseUserDirectory	#	This function sets the value for UD, user directory
		countDown 5
		loggit "Making backup file at $UD/Library/Preferences/loginwindow.plist.old"
		$CP -vp "$UD/Library/Preferences/loginwindow.plist" "$UD/Library/Preferences/loginwindow.plist.old"
		loggit "Disabling login items in $UD"
		# First, find out the user id of the file
		# old panther/jaguar version of finding the uid of the file (no stat command)
		# local funame=`ls -l "$UD/Library/Preferences/loginwindow.plist" | awk '{ print $3 }'`
		#local fuid=`id -u "$funame"`
		fuid=`$STAT -f "%u" "$UD/Library/Preferences/loginwindow.plist"`
		# do the deed, which happens to set the file ownership to root
		if defaults delete "$UD/Library/Preferences/loginwindow" "AutoLaunchedApplicationDictionary" >>"$LOGFILE" 2>&1;then
			loggit -n 'Succesfully deleted the login items.'
			xDULI_success=$EX_OK
		else
			loggit -n 'There was an error deleting the login items.'
			xDULI_success=$EX_SOFTWARE
		fi
		# restore owner
		$CHOWN $fuid "$UD/Library/Preferences/loginwindow.plist"
		loggit " Done -$xDULI_success-"
	fi
}


function xEnableNewSetup() {
	echo '
Enabling a new system setup will remove all user account information
from NetInfo, and prepare the computer to run the initial setup program
that runs when you first buy a Mac. When you restart your computer
after running this function, you will be greeted by the Apple User Setup
program which will allow to configure your computer from scratch.

Please note: User home folders are NOT removed. You will need to remove
them manually later.
'
	if getUserApproval 'Do you wish to prepare your computer for new setup?';then
		mountem root	#	Make sure disks are available for r/w
		loggit -n "Enabling new system setup"
		countDown 5
		if [ -d "$DSDB" ];then
			loggit -n "Moving the old netinfo database out of the way: "
			$MV -v "$DSDB" "${DSDB}.old" | tee -a "$LOGFILE"
		else
			loggit "The netinfo database could not be found."
		fi
		if [ -f /private/var/db/.AppleSetupDone ]; then
			loggit -n "Moving the Apple setup file: "
			$MV -v /private/var/db/.AppleSetupDone /private/var/db/.AppleSetupDone.old | tee -a "$LOGFILE"
			if [ -f /private/var/db/.RunLanguageChooserToo ]; then
				loggit -n "Moving the language chooser flag file: "
				$MV -v /private/var/db/.RunLanguageChooserToo /private/var/db/.RunLanguageChooserToo.old | tee -a "$LOGFILE"
			fi
		else
			loggit "The Apple setup file could not be found."
		fi
		if [ -f /Library/Preferences/SystemConfiguration/preferences.plist ]; then
			loggit -n "Moving the system preferences file: "
			$MV -v /Library/Preferences/SystemConfiguration/preferences.plist /Library/Preferences/SystemConfiguration/preferences.plist.old | tee -a "$LOGFILE"
		else
			loggit "The system preferences file could not be found."
		fi
		loggit "Done. Your computer will initiate the setup process on restart."
	fi
}


# TODO: Shouldn't this be done before all services are started up?
# you could do this like this: modify /etc/rc.local to search /tmp/applejack/ 
# for any scripts. If any are found, they would be executed and then deleted. 
# For example, you could write something like this:
# /usr/local/sbin/memtest all 1 -L
# and put it in /tmp/memtest.ajscript
# Then, in rc.local or /var/root/.profile, you would do this:
# for script in /tmp/*.ajscript;do
# sh $script;done
# rm /tmp/*.ajscript
# done
function xMemTest() {
	local PATH="$PATH:/usr/local/sbin:/usr/local/bin:/Applications/memtest"
	echo '
To run the memory test, you must either have opted to install the 
memtest os x program during the AppleJack installation, or already 
have it installed in one of these locations:'
	echo "$PATH"
	echo '
AppleJack will run all available tests three times, testing all 
available memory. If you want to maximize the amount of memory tested, 
run this test before you do anything else in AppleJack. (Yeah, I suppose
it is a little late for that now, but at least now you know.)
'
	if getUserApproval 'Do you want to proceed with the memory test?';then
		# Add common install locations for memtest to the path
		local mt=`which memtest | $GREP -e '^/'`;
		local exit_status	# exit status of this function
		if [ -z "$mt" ];then 
			loggit "Could not find the required memtest program in any of these locations:"
			loggit "$PATH"
			echo ""
			echo "Are you sure it is installed?"
			exit_status=$EX_USAGE
		else
			if [ -x "$mt" ];then
				# Find out if we have a version capable of logging. Minimum version is 4.14
				local mtvers=`"$mt" -v 2>/dev/null | grep 'Memtest version' | awk '{ print $3 }'`
				local logable=`echo "$mtvers 4.14" | awk '{if ($1 >= $2) print 1; else print 0}'`
				local logopt=''
				if [ "$logable" -eq "1" ];then
					if [ $WRITEABLEROOT -ne 1 ] && getUserApproval 'If you want a log of test results, we need to mount the root drive for writing. Do you want to do this?';then
							mountem
					fi
					if [ $WRITEABLEROOT -eq 1 ];then
						logopt='-L'
					fi
				fi
#				if [ $WRITEABLEROOT -eq 1 ] && [ "$logable" -eq "1" ];then logopt='-L';else logopt='';fi
				loggit "Running memory test using $mt all 3 $logopt"
				countDown 5
				"$mt" all 3 "$logopt"
				exit_status=$?
				if [ ! -z "$logopt" ]; then cat "memtest.log" >> "$LOGFILE";$RM memtest.log;fi
				if [ "$exit_status" = "0" ];then
					loggit "Memory test was successfull. Your RAM is probably fine."
				else
					loggit "Memory test gave an error."
				fi
			else
				loggit "Found the memtest program at $mt, but it is not executable."
				exit_status=$EX_USAGE
			fi
		fi
		loggit "Done. -${exit_status}-"
	fi
}


# See Apple's documentation: http://docs.info.apple.com/article.html?artnum=107210
function xRestoreNetinfoFromBackup() {
	echo "This function is not implemented yet."
	return

	local exit_status	# exit status of this function
	mountem root	#	Make sure disk is available for r/w
	if [ -f "$DSDBdump" ];then
		# move old database out of the way
		# load backup db
		echo "loading backup db"
	else
		echo "get user approval"
#		if getUserApproval 'The old netinfo database could not be found. Would you like to create a new one?';then
#		fi
	fi


	if [ -d "$DSDB" ];then
		loggit -n "Moving the old netinfo database out of the way: "
		$MV -v "$DSDB" "${DSDB}.bad" | tee -a "$LOGFILE"
	else
		echo "something else"
	fi

	if [ ! -f "$DSDBdump" ];then
		loggit "The directory services database backup ${bPar}${DSDBdump}${ePar} could not be found!"
		loggit "AppleJack cannot continue with this procedure."
	else 
		/usr/libexec/create_nidb
	
		case "$ANIMAL" in 
			4) 
				cd /var/db/netinfo
				/usr/sbin/netinfod -s local
				# sh /etc/rc
			;;
		esac
		/usr/bin/niload -v -d -r -t / localhost/local < "$DSDBdump" | tee -a "$LOGFILE"
		exit_status=$?
		cd "$SANDBOX"	#	Get back to the sandbox if we moved away from it
		loggit "Done -${exit_status}-"
	fi
}

function xSmartCheck() {
	local index
	local status
	local disks
	# Set a warning flag to 0 - everything OK
	local ret=$EX_OK
	# First get the list of devices
	disks=($(diskutil list | $GREP ^\/))

	# now loop through each device and test to see if it's SMART enabled,
	# and verified	
	for ((index=0 ; index < ${#disks[*]} ; index++ ));	do
		echo
		echo "Results for ${disks[index]}:"
		df -h | grep ${disks[index]} | sed -e 's/  */ /' -e 's/^/    /'
		status=$(diskutil info ${disks[index]} | $AWK '/SMART/ { print $3$4 }')
		case "$status" in
			'Verified')
				loggit "     SMART Status: $status"
				;;
			'NotSupported')
				loggit '     SMART not supported on this device '
				echo '     (generally only supported on IDE hard drives)'
				;;
			*)
				# set the warning for the exit status
				loggit -e "${bW}***A SMART problem was reported with ${disks[index]}***${eW}"
				echo
				ret=$EX_ERR
				;;
		esac
	done
	echo
	if [ $ret -eq 0 ];then
		loggit "No problems were found. -$ret-"
	else
		loggit "Problems were found. Backup your data on the problematic disk(s). -$ret-"
	fi
	return $ret
}

#	Experimental development for advanced features.
function expertMenu()  {
	ANS="NOT_NULL" #	We set this to keep it from being null at the outset
	echo ""
	echo -e "\033[4m                 AppleJack EXPERT Menu                                \033[0m"
	echo "These functions are experimental at this stage. If you experience "
	echo "any problems, please file a bug report at http://sf.net/projects/applejack"
	echo ""
	echo "Choose the next task..."
	echo ""
	I=0
	let "xTASKLIST=${#xTASKS[@]}-1"
	while [ "$I" -lt "$xTASKLIST" ];do
		echo -e "[${bK}$I${eK}] ${xTASKNAMES[$I]}";
		let "I=$I+1"
	done
	echo ""
	echo ""
	echo -en "Your choice ${bPar}Just hit return to quit${ePar}: ${bK}"
	read ANS
	echo -en "${eK}"
	if [ ! -z "$ANS" ];then	#	If user doesn't want to quit, continue
		I=0
		let "xTASKCOUNT=${#xTASKNAMES[@]}"
		while [ "$I" -lt "$xTASKCOUNT" ];do
			if [[ "$ANS" = "${xTASKCODES[$I]}" || "$ANS" = "$I" || "$ANS" = "${xTASKCODESUC[$I]}" ]];then
				eval "${xTASKS[$I]}"	#	Run associated task
				expertMenu	#	Return to menu
			fi
			let "I=$I+1"
		done
		#	If you're here, you're probably typed a wrong key
		echo "Ooops! Looks like you typed the wrong key."
		expertMenu
	else	#	Let user quit, if they want to
		quitScript
	fi
}

########################################################################
#	END: EXPERT FUNCTIONS UNDER DEVELOPMENT ############################
########################################################################


########################################################################
#	START OF APPLEJACK RUNTIME #########################################
########################################################################
#	Before doing anything, let's move our working directory to the safe sandbox.
#	by running the script from the SANDBOX directory, we hope to minimize damage from any bugs.
if [ -d "/tmp" ];then
	SANDBOX="/tmp"
elif [ -d "/private/var/tmp" ]; then
	SANDBOX="/private/var/tmp"
else	#	In a pinch, we use this
	SANDBOX="/Library/Caches"
fi
cd "$SANDBOX"
#	Okay, first let's prepare for logging...
#	touching the log file helps us see if file system is writable and 
#	therefore what mode of logging to start with.
if touch "$LOGFILE" &>/dev/null; then 
	#	on success [exit status 0]
	WRITEABLEROOT=1
else
	WRITEABLEROOT=0
	TEMPLOG=
fi
#	How was script invoked?
#	Check for invocation of script with command line parameter for running
#	it automatically, for example, from another script.
showusage=0
optFeedback=
badopt=
POSTSCRIPT=
if [ ! -z "$1" ];then
	case "$1" in
		"auto" | "AUTO" )
			optFeedback="Running in automatic mode"
			AUTO=1
			if [ "$1" = "AUTO" ];then
				DEEP=1
				optFeedback="$optFeedback, deep clean on"
			fi
			if [ ! -z "$2" ];then
				#	Let's test for reboot as well as restart, for compatibility reasons
				if [ "$2" = "restart" ] || [ "$2" = "reboot" ];then
					optFeedback="$optFeedback, with automatic restart"
					POSTSCRIPT="restart"
				elif [ "$2" = "shutdown" ];then
					optFeedback="$optFeedback, with automatic shutdown"
					POSTSCRIPT="shutdown"
				else
					# incorrect options specified
					badopt="$2"
					showusage=1
				fi
			else
				POSTSCRIPT="manual"
				optFeedback="$optFeedback, with manual exit"
			fi;;
		"uninstall" )
			if identityCheck;then
				uninstall
			else
				echo -e "${bE}You are not authorized as the root user. To uninstall, use sudo ${eE}"
				echo -e "${bE}or run this script from single user mode.					   ${eE}"
				exit $EX_USAGE
			fi;;
		"version" | "--version" | "-v" ) # @todo: document this option
			echo "This is AppleJack $VERSION, $REVISION"
			echo ""
			exit $EX_OK;;
		* )
			# incorrect options specified
			showusage=1
			badopt="$1";;
	esac
fi
if [ $showusage -eq 1 ];then
	echo ''
	echo "AppleJack $VERSION, $REVISION: Invalid option '$badopt'"
	echo 'USAGE: applejack [auto|AUTO [restart|shutdown]]'
	echo 'type `man applejack` for more details'
	echo ''
	exit $EX_USAGE
fi
loggit "**********************************************************************"
loggit "* AppleJack $VERSION, $REVISION                                    *"
loggit "* Copyright (c) 2002-10 Kristofer Widholm, The Apotek                *"
echo "* - AppleJack comes with ABSOLUTELY NO WARRANTY                      *"
echo "* - This is free software, and you are welcome to redistribute it    *"
echo "*   under certain conditions, as specified in the GPL LICENSE you    *"
echo "*   read during installation of this product: www.opensource.org     *"
echo "*                                                                    *"
echo "* USAGE ${bPar}interactive${ePar}: Just run through the tasks in the menu below, *"
echo "*   in ascending order, and let AppleJack fix your machine.          *"
echo "* USAGE ${bPar}automatic mode${ePar}: To start AppleJack in auto mode, type:     *"
echo "*   'applejack auto'                                                 *"
echo "*   'applejack auto restart' (restarts computer when done)           *"
echo "*   'applejack auto shutdown' (shuts down the computer when done)    *"
echo "*   To do a deep clean of the system, use AUTO instead of auto.      *"
echo "*   Please see the man page for details: \`man applejack\`             *"
echo "*                                                                    *"
echo "* Donations gratefully accepted at http://applejack.sourceforge.net  *"
echo "**********************************************************************"
echo ""
D=`date`
loggit "$D. Gathering information..."
loggit "$optFeedback"
# 	Make sure the script is being run by root
if identityCheck;then
	loggit -n "- User ID: ${IDENTITY[0]}, NAME: ${IDENTITY[1]}"
else
	loggit "- User ID: ${IDENTITY[0]}, NAME: ${IDENTITY[1]}"
	echo -e "${bE}You are not authorized as the root user. AppleJack must quit. ${eE}"
	exit $EX_USAGE
fi
#	Okay, are we in single user mode? In the past, before, Leopard, we could count on id to behave differently in single user mode vs loaded, but now the behavior is difficult to discern. So we'll use the rather crude method of counting lines of output from ps ax. If there's less than 20 lines, we're pretty sure we're in single user mode, even after having loaded our basic services
# SUM=`id | $GREP -E '[^0]\('`	#	In single user mode, SUM should be empty.
# if [ ! -z "$SUM" ];then
process_count=`ps ax | wc -l | sed 's/ //g'` # how many processes are running?
if [ $process_count -gt 25 ]; then
	loggit ""
	loggit "${bW}!!! WARNING: You are not running AppleJack in single user mode!    !!${eW}"
	loggit "${bW}!!! Certain tasks can cause your operating system to crash.        !!${eW}"
	loggit "${bW}!!! Proceed at your own risk.                                      !!${eW}"
	echo -e "(For Single User Mode: Press and hold ${bK}command${eK} and ${bK}s${eK} immediately after restart.)"
	loggit ""
fi
#	Let's find out Mac OS X version in order to start the right services.
OSV=`sw_vers 2>/dev/null | $AWK '/ProductVersion/ { print $2 }'`
loggit "- OS Version: $OSV"
#	TODO: Look for directory services DB in standard location, and allow user to input their location if not found.

#	Check for location of swapdir
swapdir=''
if [ -e /etc/rc ];then
	vmsrc='/etc/rc'
	swapdir=`$GREP -E "^[^#]*swapdir=[/\"']" /etc/rc | $SED -e 's/"//g' -e "s/'//g" | cut -f 2 -d =`
fi
if [ "$swapdir" = "" ] && [ -e '/System/Library/LaunchDaemons/com.apple.dynamic_pager.plist' ];then
	vmsrc='dynamic_pager'
	# Register the PA variable, for getting the VM location later
	declare -arx PA=`defaults read /System/Library/LaunchDaemons/com.apple.dynamic_pager ProgramArguments`;
	swapdir="${PA[2]}";
	swapdir=`echo "$swapdir" | awk -F/ '{for (i=2; i<NF; i++) printf "/"$i}'`
fi
if [ ! "$swapdir" = "" ];then
	loggit "- According to $vmsrc, virtual memory is located at $swapdir."
else
	loggit "${bW}Unable to discover location of virtual memory directories${eW}"
	echo 'Make sure $swapdir is declared in a standard way. As a temporary'
	echo 'workaround, please enter the correct VM directory location at the '
	echo 'prompt. Or just hit return to accept the default location '
	echo -n "${bPar}/private/var/vm${ePar} instead. [enter directory]: "
	read vmDir
	if [ ! "$vmDir" = "" ];then
		swapdir="$vmDir"
		loggit "- Using $vmDir as the swap file location."
	else
		swapdir='/private/var/vm'
		loggit '- Defaulting to /private/var/vm'
	fi
fi
if [ ! -d "$swapdir" ];then
	loggit "${bW}WARNING! Swap directory $swapdir does not appear to exist. "
	echo -e "Proceed with caution${eW}"
fi
#	Check if root file system is journaled
#	(Issuing the mount command without parameters simply lists volumes)
if mount | $GREP 'on / (' | $GREP 'journal' 1>/dev/null;then 
	JOURNALED=1
	loggit "- Local root filesystem is journaled"
else 
	JOURNALED=0
fi

# OS Specific Configuration
ANIMAL=`echo $OSV | cut -f 2 -d . `
case "$ANIMAL" in
	4) 	
		# Where is the netinfo database located?
		DSDB='/private/var/db/netinfo/local.nidb'
		# Where is the netinfo database backup located?
		DSDBdump='/private/var/backups/local.nidump'
		;;
	5) 	
		# Where is the netinfo database located?
		DSDB="."
		# Where is the netinfo database backup located?
		# @todo: convert this to dscl info
		DSDBdump="/private/var/backups/local.nidump"
		;;
	6) 	
		# Where is the netinfo database located?
		DSDB="."
		# Where is the netinfo database backup located?
		# @todo: convert this to dscl info
		DSDBdump="/private/var/backups/local.nidump"
		;;
	*)
		loggit "${bW}This version of AppleJack supports only Mac OS X versions 10.4.x and"
		loggit "above. It's advisable to not use it unless you absolutely have to. For"
		loggit "Mac OS X versions prior to 10.4.x, please use AppleJack version 1.4.3${eW}"
		;;
esac


#	TODO: Output warning for bad environment
if [ $BADENV -ne 0 ];then
	loggit "${bW}WARNING: Some necessary commands could not be found in their standard locations.${eW}"
	echo 'If you have installed custom binaries or otherwise modified the'
	echo 'operating environment, you may experience problems.'
fi


########################################################################
#	APPLEJACK READY; PRESENT MENU ######################################
########################################################################
selectNext

#Script should never reach this, but just in case...
bell
exit $EX_SOFTWARE
