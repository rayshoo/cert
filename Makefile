.DEFAULT_GOAL := all

OUTPUT_DIR := gen/

ROOT_ENCRYPT_BIT := 4096
ROOT_INSECURE := false
ROOT_PASSPHRASE := qwfp
ROOT_CERT := root
ROOT_DAYS := 365
ROOT_COUNTRY := KO
ROOT_STATE := Seoul
ROOT_LOCALITY := Songpa-gu
ROOT_ORGANIZATION := rayshoo
ROOT_COMMON_NAME := dragonz.dev
ROOT_EMAIL_ADDRESS := fire@dragonz.dev
ROOT_PKCS12_FRIENDLY_NAME := "root dragonz.dev"
ROOT_PKCS12_PASSPHRASE := qwfp

SUB_ENCRYPT_BIT := 4096
SUB_INSECURE := false
SUB_PASSPHRASE := arst
SUB_CERT := client
SUB_DAYS := 365
SUB_COUNTRY := KO
SUB_STATE := Seoul
SUB_LOCALITY := Songpa-gu
SUB_ORGANIZATION := rayshoo
SUB_COMMON_NAME := localhost
SUB_EMAIL_ADDRESS := fire@dragonz.dev
SUB_PKCS12_FRIENDLY_NAME := server localhost
SUB_PKCS12_PASSPHRASE := arst


ca-key:
	if [ ${ROOT_INSECURE} == "true" ]; then \
	openssl genrsa -out ${OUTPUT_DIR}${ROOT_CERT}.key ${ROOT_ENCRYPT_BIT}; \
  else \
	openssl genrsa -aes256 -passout pass:${ROOT_PASSPHRASE} -out ${OUTPUT_DIR}${ROOT_CERT}.key ${ROOT_ENCRYPT_BIT}; \
	fi
.PHONY:ca-key

ca-pub:
	openssl rsa -in ${OUTPUT_DIR}${ROOT_CERT}.key -pubout -out ${OUTPUT_DIR}${ROOT_CERT}.pub -outform PEM -passin pass:${ROOT_PASSPHRASE}
.PHONY:ca-pub

ca-crt:
	openssl req -x509 -new -key ${OUTPUT_DIR}${ROOT_CERT}.key -sha256 -days ${ROOT_DAYS} -out ${OUTPUT_DIR}${ROOT_CERT}.crt \
	-subj /C=${ROOT_COUNTRY}/ST=${ROOT_STATE}/L=${ROOT_LOCALITY}/O=${ROOT_ORGANIZATION}/CN=${ROOT_COMMON_NAME}/emailAddress=${ROOT_EMAIL_ADDRESS} -passin pass:${ROOT_PASSPHRASE}
.PHONY:ca-key

ca-crt-with-key:
	openssl req -x509 -nodes -newkey rsa:${ROOT_ENCRYPT_BIT} -keyout ${OUTPUT_DIR}${ROOT_CERT}.key -out ${OUTPUT_DIR}${ROOT_CERT}.crt -days ${ROOT_DAYS} \
	-subj /C=${ROOT_COUNTRY}/ST=${ROOT_STATE}/L=${ROOT_LOCALITY}/O=${ROOT_ORGANIZATION}/CN=${ROOT_COMMON_NAME}/emailAddress=${ROOT_EMAIL_ADDRESS}
.PHONY:ca-crt-with-key

ca-der:
	openssl x509 -outform der -in ${OUTPUT_DIR}${ROOT_CERT}.crt -out ${OUTPUT_DIR}${ROOT_CERT}.der
.PHONY:ca-der

ca-txt:
	openssl x509 -in ${OUTPUT_DIR}${ROOT_CERT}.crt -text -out ${OUTPUT_DIR}${ROOT_CERT}.crt.txt
.PHONY:ca-txt

sub-key:
	if [ ${SUB_INSECURE} == "true" ]; then \
	openssl genrsa -out ${OUTPUT_DIR}${SUB_CERT}.key ${SUB_ENCRYPT_BIT}; \
	else \
	openssl genrsa -aes256 -passout pass:${SUB_PASSPHRASE} -out ${OUTPUT_DIR}${SUB_CERT}.key ${SUB_ENCRYPT_BIT}; \
	fi
.PHONY:sub-key

sub-pub:
	openssl rsa -in ${OUTPUT_DIR}${SUB_CERT}.key -pubout -out ${OUTPUT_DIR}${SUB_CERT}.pub -outform PEM -passin pass:${SUB_PASSPHRASE}
.PHONY:sub-pub

sub-csr:
	openssl req -new -key ${OUTPUT_DIR}${SUB_CERT}.key -out ${OUTPUT_DIR}${SUB_CERT}.csr -passin pass:${SUB_PASSPHRASE} \
	-subj /C=${SUB_COUNTRY}/ST=${SUB_STATE}/L=${SUB_LOCALITY}/O=${SUB_ORGANIZATION}/CN=${SUB_COMMON_NAME}/emailAddress=${SUB_EMAIL_ADDRESS} -passin pass:${SUB_PASSPHRASE}
.PHONY:sub-csr

sub-ext:
	@echo 'authorityKeyIdentifier=keyid,issuer' > ${OUTPUT_DIR}${SUB_CERT}.ext
	@echo 'basicConstraints=CA:FALSE' >> ${OUTPUT_DIR}${SUB_CERT}.ext
	@echo 'keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment' >> ${OUTPUT_DIR}${SUB_CERT}.ext
	@echo 'subjectAltName = @alt_names' >> ${OUTPUT_DIR}${SUB_CERT}.ext
	@echo '[alt_names]' >> ${OUTPUT_DIR}${SUB_CERT}.ext
	@echo 'DNS.1 = ${SUB_COMMON_NAME}' >> ${OUTPUT_DIR}${SUB_CERT}.ext
.PHONY:sub-ext

sub-crt:
	openssl x509 -req -in ${OUTPUT_DIR}${SUB_CERT}.csr -CA ${OUTPUT_DIR}${ROOT_CERT}.crt -CAkey ${OUTPUT_DIR}${ROOT_CERT}.key -CAcreateserial \
	-out ${OUTPUT_DIR}${SUB_CERT}.crt -days ${SUB_DAYS} -sha256 -passin pass:${ROOT_PASSPHRASE} -extfile ${OUTPUT_DIR}${SUB_CERT}.ext
.PHONY:sub-crt

sub-p12:
	openssl pkcs12 -export -in ${OUTPUT_DIR}${SUB_CERT}.crt -inkey ${OUTPUT_DIR}${SUB_CERT}.key -name "${SUB_PKCS12_FRIENDLY_NAME}" -out ${OUTPUT_DIR}${SUB_CERT}.p12 -passin pass:${SUB_PASSPHRASE} -passout pass:${SUB_PKCS12_PASSPHRASE}
.PHONY:sub-p12

sub-der:
	openssl x509 -outform der -in ${OUTPUT_DIR}${SUB_CERT}.crt -out ${OUTPUT_DIR}${SUB_CERT}.der
.PHONY:sub-der

sub-txt:
	openssl req -in ${OUTPUT_DIR}${SUB_CERT}.csr -out ${OUTPUT_DIR}${SUB_CERT}.csr.txt -text
	openssl x509 -in ${OUTPUT_DIR}${SUB_CERT}.crt -text -out ${OUTPUT_DIR}${SUB_CERT}.crt.txt
.PHONY:sub-txt

clean:
	rm ${OUTPUT_DIR}*.key ${OUTPUT_DIR}*.csr ${OUTPUT_DIR}*.ext ${OUTPUT_DIR}*.srl ${OUTPUT_DIR}*.crt ${OUTPUT_DIR}*.p12 \
	${OUTPUT_DIR}*.pub ${OUTPUT_DIR}*.der ${OUTPUT_DIR}*.txt
.PHONY:clean

ca: ca-key ca-crt
.PHONY:ca

sub: sub-key sub-csr sub-ext sub-crt
.PHONY:sub

all: ca-key ca-crt sub-key sub-csr sub-ext sub-crt
.PHONY:all