# Spacewalk Errata Import


Spacewalk CEFS and OVAL reporting data import script. This script imports data from https://cefs.steve-meier.de website and loads it into your spacewalk server.

## SYNOPSIS

**spacewalk-errata-import.sh -u [UID] -p [PASSWORD] -s [FQDN] [OPTION]... **

**  -o, --output... [directory]**

   Output directory where the downloaded data will be stored.

**  -u, --userid... [userid]"**

   Spacewalk administrative user id used to import the data.
   [Mandatory]

**  -p, --password... [password]**

  Spacewalk administrative user id password for the user id
  to import the data. [Mandatory]

**  -s, --spacewalk-server... [FQDN]**

  Spacewalk server Fully Qualified Domain Name
  Example: spacewalk.mydomain.com [Mandatory]

**  -h, --help**

  Display this help and exit.

**  -v, --verbose**

  Show all output to standard out.

**  -d, --delete-old-files**

  Delete all previously downloaded files.

