# ----------------------------------------------------------------------------------------------------------------

# Check for the first argument
if [ -z $1 ] ; then
  echo -e "This sript requires exactly ONE non-empty argument: BASE_URL" >&2
  exit 1
fi

if [ `echo "$1" | grep -c -e 'thetrove.net' ` -eq 0 ] ; then
  echo -e "The URL is mean to point to the 'thetrove.net'" >&2
  exit 1
fi

# ----------------------------------------------------------------------------------------------------------------

rm -f wget_log

# ----------------------------------------------------------------------------------------------------------------

urldecode ()
{
 echo `python -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])" "$1"`
 return 0;
}

# ----------------------------------------------------------------------------------------------------------------

download_from_thetrove ()
{
 BASE_URL="$1"

 if [ -z "$BASE_URL" ] ; then
   echo -e "This FUNCTION requires exactly ONE non-empty argument: BASE_URL" >&2
   return 1
 fi

 SHORT_BASE_URL=`echo -e "$BASE_URL" | sed -En "s;(.*)/index.html;\1;p"`
 DIR_STRUCTURE=`echo -e "$SHORT_BASE_URL" | sed -En "s;https://thetrove.net/(.*);\1;p"`
 DIR_STRUCTURE=`urldecode "$DIR_STRUCTURE"`
 PARSED_WEBPAGE=`curl "$BASE_URL" 2>/dev/null | grep -e 'class="litem ' | grep -v -e '../index.html'`
 PARSED_DIRLIST=`echo "$PARSED_WEBPAGE" | grep -e 'class="litem dir'   | sed -En "s/.*href='(.*)'.*/\1/p"`
 PARSED_FILELIST=`echo "$PARSED_WEBPAGE" | grep -e 'class="litem file' | sed -En "s/.*href='\.(.*)'.*/\1/p"`

 if [ -n $PARSED_FILELIST ] ; then
   # Download the files now
   mkdir -p "$DIR_STRUCTURE"
   for i in $PARSED_FILELIST ; do
     DECODED_FILE=`urldecode "$i"`;
     echo -e " \tDOWNLOADING \t$DIR_STRUCTURE$DECODED_FILE"
     wget "$SHORT_BASE_URL$i" -O "$DIR_STRUCTURE$DECODED_FILE" -a wget_log;
   done
 fi


 if [ -n $PARSED_DIRLIST ] ; then
   # Recurse to sub-directories
   for i in $PARSED_DIRLIST ; do
     echo -e " DESCENDING TO \t\t" `urldecode "$DIR_STRUCTURE$i"`
     download_from_thetrove "$SHORT_BASE_URL/$i/index.html"
   done
 fi

 return 0;
}

# ----------------------------------------------------------------------------------------------------------------

download_from_thetrove $1

tree > tree
