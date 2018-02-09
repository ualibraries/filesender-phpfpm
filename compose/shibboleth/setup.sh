#!/bin/bash

HOSTIP=$1

if [ "$HOSTIP" = "" ]; then
  HOSTIP=`hostname -I 2>&1 | perl -ne '@ip = grep( !/^(192.168|10|172.[1-3]\d)./, split(/\s/)); print join("|",@ip)'`
fi

OCTETS=`echo -n $HOSTIP | sed -e 's|\.|#|g' | perl -ne '@valid = grep(/\d+/,split(/#/)); print scalar(@valid)'`

echo "CALCULATED $HOSTIP has $OCTETS parts"

# Validate 
if [ "$OCTETS" != "4" ]; then
   echo "ERROR: was not able to use a single IP to setup with."
   echo "ERROR: Please rerun passing in the public IP to use."
   echo "ERROR: Example: ./setup.sh <your_public_ip>"
   exit 1
fi

