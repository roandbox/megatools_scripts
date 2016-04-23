#! /bin/sh
#
# The script is files synchronization with using their size and megatools.
# Written by Rodionov Andrey <roand@inbox.ru>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

MEGASYNC='/usr/bin/megacopy'
MEGARM='/usr/bin/megarm'
MEGALS='/usr/bin/megals'

USER=""
OUSER=""
PASS=""
OPASS=""
LOCALDIR=""
REMOTEDIR=""
PROGRESS=""
while getopts "u:p:r:l:-:" optname
  do
    case "$optname" in
      "u")
        OUSER='-u'
        USER=$OPTARG
        ;;
      "p")
        OPASS='-p'
        PASS=$OPTARG
        ;;
      "r")
        REMOTEDIR=$OPTARG
        ;;
      "l")
        LOCALDIR=$OPTARG
        ;;
      "-")
        if [ "no-progress" == "$OPTARG" ];
        then
          PROGRESS="--no-progress"
        fi  
        ;;
    esac
  done

SEDLOCALDIR="${LOCALDIR//\//\\/}"
SEDREMOTEDIR="${REMOTEDIR//\//\\/}"
BACKUP_TIME=`date +%c`
hostname=`hostname`

ugid="`id -nu` `id -ng`"
date_re='\(....\)-\(..\)-\(..\) \(..:..:..\)'
date_mc='\3-\4-\2 \5'
size_re='............'
size_null='...........-'
pred='^....................... [1-9].'
pref='^....................... 0.'

SIZES_AND_FILES=`$MEGALS $OUSER $USER $OPASS $PASS --reload -lR $REMOTEDIR | sed -n "s/$pref \($size_null\) $date_re \(.*\)/0;\6/p;s/$pref \($size_re\) $date_re \(.*\)/\1;\6/p"`
MODIFY_COUNT=0
DELETE_COUNT=0
IFS=$'\n' 
for i in $SIZES_AND_FILES; do
    IFS=$';' 
    arr=($i)
    RFILENAME=${arr[1]}
    RFILESIZE=${arr[0]}
    LFILENAME=`echo $RFILENAME | sed "s/$SEDREMOTEDIR/$SEDLOCALDIR/g"`
    if [ -e "$LFILENAME" ]
    then
      LFILESIZE=$(stat -c%s "$LFILENAME")
      if [ $LFILESIZE -ne $RFILESIZE ]; 
      then
         $MEGARM "$OUSER" "$USER" "$OPASS" "$PASS" "$RFILENAME"
         MODIFY_COUNT=$[$MODIFY_COUNT+1]
      fi
    else
       $MEGARM "$OUSER" "$USER" "$OPASS" "$PASS" "$RFILENAME"
       DELETE_COUNT=$[$DELETE_COUNT+1]
    fi
done

COPY_COUNT=`($MEGASYNC $PROGRESS $OUSER $USER $OPASS $PASS --local $LOCALDIR --remote $REMOTEDIR 3>&1 1>&2 2>&3 | grep -v "ERROR: File already exists at" ) 3>&1 1>&2 2>&3 | tee /dev/tty | grep -e "^F "|wc -l`
echo "--------------------------------------------------------"
echo "  Hostname: $(hostname)"
echo "--------------------------------------------------------"
echo "  Modified: $MODIFY_COUNT file(s)"
echo "   Deleted: $DELETE_COUNT file(s)"
echo "    Copied: $COPY_COUNT file(s)"
echo "      Date: $BACKUP_TIME"
echo "--------------------------------------------------------"
