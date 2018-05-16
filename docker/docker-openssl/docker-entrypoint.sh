#!/bin/bash
set -e

# ************************************************************
# Options passed to the docker container to run scripts
# ************************************************************
# backup   : archives the certificate authority into the IMPORT_EXPORT_PATH
# import   : imports the certificate authority from the IMPORT_EXPORT_PATH
# generate : generates a self signed certificate authority

CMD="$1"
FILE="$2"
SSL_BASE_DIR="/etc/ssl/private"

case ${CMD} in
    backup)
        /bin/tar \
            --create \
            --preserve-permissions \
            --same-owner \
            --directory="${SSL_BASE_DIR}" \
            --file="${FILE}" \
            "."
        ;;

    extract)
        rm -rf "${SSL_BASE_DIR}/*"
        /bin/tar \
            --extract \
            --preserve-permissions \
            --preserve-order \
            --same-owner \
            --directory="${SSL_BASE_DIR}" \
            --file="${FILE}"
        ;;

    generate)
        SSL_BASE_FILES=${SSL_BASE_FILES:=apache2}
        BYTES=${BYTES:=2048}
        DAYS=${DAYS:=365}
        SUBJ=${SUBJ:="/C=??/ST=ExampleState/L=ExampleState/O=ExampleOrginization/CN=example.com"}
        # commands to generate a self signed certifacate
        for base_filename in ${SSL_BASE_FILES}
        do
            openssl req -newkey rsa:${BYTES} -x509 -days ${DAYS} -nodes \
                -keyout ${SSL_BASE_DIR}/${base_filename}.key \
                -out ${SSL_BASE_DIR}/${base_filename}.crt \
                -subj ${SUBJ}
            cp ${SSL_BASE_DIR}/${base_filename}.crt ${SSL_BASE_DIR}/${base_filename}_bundle.crt
        done
        openssl dhparam -out ${SSL_BASE_DIR}/dhparam.pem ${BYTES}
        ;;

    *)
        # run some other command in the docker container
        exec "$@"
        ;;
esac
