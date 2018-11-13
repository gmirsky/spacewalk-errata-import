#!/bin/bash
# spacewalk-errata-import.sh
# Import CEFS: CentOS Errata for Spacewalk into Spacewalk.
#
POSITIONAL=()
while [[ $# -gt 0 ]]
do
  key="$1"
  #
  case $key in
      -o|--output)
      OUTPUT="$2"
      shift # past argument
      shift # past value
      ;;
      -d|--delete-old-files)
      DELETE_OLD_FILES="YES"
      shift # past argument
      ;;
      -u|--userid)
      USERID="$2"
      shift # past argument
      shift # past value
      ;;
      -p|--password)
      PASSWORD="$2"
      shift # past argument
      shift # past value
      ;;
      -s|--spacewalk-server)
      SPACEWALK_SERVER="$2"
      shift # past argument
      shift # past value
      ;;
      -h|--help)
      HELP="YES"
      shift # past argument
      ;;
      -v|--verbose)
      VERBOSE="YES"
      shift # past argument
      ;;
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters
#
# if the help option was selected.
#
if [ "${HELP}" == "YES" ]; then
  echo
  echo -e "\e[1mNAME\e[0m"
  echo
  echo "  Spacwalk CEFS and OVAL reporting data import."
  echo "  Imports data from https://cefs.steve-meier.de"
  echo
  echo -e "\e[1mSYNOPSIS\e[0m"
  echo
  echo "  spacewalk-errata-import.sh [OPTION]... "
  echo
  echo -e "\e[1mDESCRIPTION\e[0m"
  echo
  echo "  -o, --output... [directory]"
  echo
  echo "    Output directory where the downloaded data will be stored."
  echo
  echo "  -u, --userid... [userid]"
  echo
  echo "    Spacewalk administrative user id used to import the data."
  echo "    [Mandatory]"
  echo
  echo "  -p, --password... [password]"
  echo
  echo "    Spacewalk administrative user id password for the user id"
  echo "    to import the data. [Mandatory]"
  echo
  echo "  -s, --spacewalk-server... [FQDN]"
  echo
  echo "    Spacewalk server Fully Qualified Domain Name"
  echo  "   Example: spacewalk.mydomain.com [Mandatory]"
  echo
  echo "  -h, --help"
  echo
  echo "    Display this help and exit."
  echo
  echo " -v, --verbose"
  echo
  echo "    Show all output to standard out."
  echo
  echo " -d, --delete-old-files"
  echo
  echo "    Delete all previously downloaded files."
  exit
fi
#
# Check to see if mandatory fields have been supplied, otherwise exit out
# with an error message.
#
if [ -z $USERID ]; then
  echo "ERROR: User Id must be supplied."
  exit 1
fi
#
if [ -z $PASSWORD ]; then
  echo "ERROR: User Password must be supplied."
  exit 1
fi
#
if [ -z $SPACEWALK_SERVER ]; then
  echo "ERROR: Spacewalk server FQDN must be supplied."
  exit 1
fi
#
# if OUTPUT directory was not provided then use the current directory.
#
if [ -z "${OUTPUT}" ]
then
      OUTPUT="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
else
      #CURRENT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
      #
      # if the OUTPUT directory was provided then check to see
      #
      if [ -o "${OUTPUT}" ]
      then
          # remove the trailing slashe(s) with realpath.
          OUTPUT=$(realpath -s $OUTPUT)
      else
          echo
          echo "ERROR: Directory ${OUTPUT} does not exists."
          echo "Please insure that the output parameter is correct or"
          echo "create the output directory with the proper permissions."
          echo "Aborting."
          exit 1
      fi
fi
#
if [ "${VERBOSE}" == "YES" ]; then
  echo
  echo "OUTPUT PATH"       = "${OUTPUT}"
  echo "VERBOSE"           = "${VERBOSE}"
  echo "SPACEWALK SERVER"  = "${SPACEWALK_SERVER}"
  echo "SPACEWALK USER ID" = "${USERID}"
  echo "DELETE OLD FILES"  = "${DELETE_OLD_FILES}"
  echo
fi
#
fping -c1 -t300 $SPACEWALK_SERVER 2>/dev/null 1>/dev/null
if [ "$?" = 0 ]
then
  if [ "${VERBOSE}" == "YES" ]; then
    echo "${SPACEWALK_SERVER} found"
  fi
else
  echo "ERROR: ${SPACEWALK_SERVER} was not found."
  exit 1
fi
#
# If the files exist, then delete them.
#
if [ "${DELETE_OLD_FILES}" == "YES" ]; then
  FILE="${OUTPUT}/errata.latest.xml"
  if [ -f $FILE ] ; then
    if [ "${VERBOSE}" == "YES" ]; then
      echo "Found ${FILE}, deleting..."
      echo
    fi
    rm -f $FILE
  fi
  #
  FILE="${OUTPUT}/com.redhat.rhsa-all.xml"
  if [ -f $FILE ] ; then
    if [ "${VERBOSE}" == "YES" ]; then
      echo "Found ${FILE}, deleting..."
      echo
    fi
    rm -f $FILE
  fi
fi
#
# use wget to download the errata.latest.xml file
#
ERR_FILE="${OUTPUT}/errata.latest.xml"
W_RTN=`wget --output-document=$ERR_FILE --random-wait https://cefs.steve-meier.de/errata.latest.xml`
if [[ $? -ne 0 ]]; then
 echo "wget of errata.latest.xml failed"
 echo $W_RTN
 exit 1
fi
#
# use wget to download the com.redhat.rhsa-all.xml file
#
RHSA_FILE="${OUTPUT}/com.redhat.rhsa-all.xml"
W_RTN=`wget --output-document=$RHSA_FILE --random-wait https://www.redhat.com/security/data/oval/com.redhat.rhsa-all.xml`
if [[ $? -ne 0 ]]; then
 echo "wget of com.redhat.rhsa-all.xml failed"
 echo $W_RTN
 exit 1
fi
#
# #get the lastest python script used to load the data into spacewalk from github.com
#
PL_FILE="${OUTPUT}/errata-import.pl"
W_RTN=`wget --output-document=$PL_FILE --random-wait https://github.com/stevemeier/cefs/raw/master/errata-import.pl`
if [[ $? -ne 0 ]]; then
 echo "wget of errata-import.pl failed"
 echo $W_RTN
 exit 1
fi
#
# make the errata-import.pl script executable
#
chmod 755 $PL_FILE
#
# execute errata-import.pl to upload the data to the spacewalk server
#
./$PL_FILE --server $SPACEWALK_SERVER --errata $ERR_FILE --publish --rhsa-oval $RHSA_FILE
#
