#!/bin/sh
echo
for cert in "$@"; do
        echo BEGIN $cert
        openssl crl2pkcs7 -nocrl -certfile "$cert" | openssl pkcs7 -print_certs -noout
        echo END $cert
        echo
done
