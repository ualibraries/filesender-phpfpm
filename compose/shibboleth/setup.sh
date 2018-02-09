#!/bin/bash

# Make sure we are running from the setup.sh directory
SHELL_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SETUP_DIR="$( cd $SHELL_SCRIPT_DIR/ && pwd )"
while [ ! -d "$SETUP_DIR/template" ]; do
    SETUP_DIR="$( cd $SETUP_DIR/.. && pwd )"
done

echo "RUNNING from directory $SETUP_DIR"
cd $SETUP_DIR

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

DEVICE=$HOSTIP
DESTDIR=shibboleth
CERT_KEY=sp-key.pem
CERT_CSR=sp-csr.pem
CERT_SIGNED=sp-cert.pem
echo "GENERATING shibboleth self-signed cert files"
echo "   $DESTDIR/$CERT_SIGNED"
echo "   $DESTDIR/$CERT_KEY"

SUBJECT="/C=FakeCountry/postalCode=FakeZip/ST=FakeState/L=FakeCity/streetAddress=FakeStreet/O=FakeOrganization/OU=FakeDepartment/CN="

# Create shib private key and csr:
openssl req -nodes -newkey rsa:2048 -keyout $DESTDIR/$CERT_KEY -subj "$SUBJECT$DEVICE" -out $DESTDIR/$CERT_CSR

# Create shib self-signed cert:
SIGNING_KEY="-signkey $DESTDIR/$CERT_KEY"
DAYS=1095   # 3 * 365

openssl x509 -req -extfile <(printf "subjectAltName=DNS:$DEVICE") -in $DESTDIR/$CERT_CSR $SIGNING_KEY -out $DESTDIR/$CERT_SIGNED -days $DAYS -sha256

DESTDIR=nginx/conf.d
CERT_KEY=nginx-ssl.key
CERT_CSR=nginx-ssl.csr
CERT_SIGNED=nginx-ssl.crt
echo "GENERATING nginx ssl self-signed cert files"
echo "   $DESTDIR/$CERT_SIGNED"
echo "   $DESTDIR/$CERT_CSR"
echo "   $DESTDIR/$CERT_KEY"

# Create nginx private key and csr:
openssl req -nodes -newkey rsa:2048 -keyout $DESTDIR/$CERT_KEY -subj "$SUBJECT$DEVICE" -out $DESTDIR/$CERT_CSR

# Create nginx self-signed cert:
SIGNING_KEY="-signkey $DESTDIR/$CERT_KEY"

openssl x509 -req -extfile <(printf "subjectAltName=DNS:$DEVICE") -in $DESTDIR/$CERT_CSR $SIGNING_KEY -out $DESTDIR/$CERT_SIGNED -days $DAYS -sha256
