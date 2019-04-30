#! /bin/bash

echo "Switch to the Root directory"
cd ~

echo "Make a certs directory to store all certificates"
mkdir certs

echo "switch to the certs directory"
cd certs

echo "Create a CA, server and client keys with OpenSSL"

echo "Generate CA Private Key"
openssl genrsa -aes256 -out ca-key.pem 4096

echo "Generate CA Certificate"
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem

echo "Now that you have a CA, you can create a server key and certificate signing request (CSR)."

echo "Generate the Docker Registry Server Key"
openssl genrsa -out myregistry.nishanth.com-key.pem 4096

echo "Generate the Server Certificate"
openssl req -subj "/CN=myregistry.nishanth.com" -sha256 -new -key myregistry.nishanth.com-key.pem -out myregistry.nishanth.com.csr

echo "Since TLS connections can be made through IP address as well as DNS name, the IP addresses need to be specified when creating the certificate"
echo subjectAltName = DNS:myregistry.nishanth.com,DNS:localhost,IP:127.0.0.1 >> extfile.cnf

echo "Set the Docker daemon key’s extended usage attributes to be used only for server authentication:"
echo extendedKeyUsage = serverAuth >> extfile.cnf

echo "we’re going to sign the public key with our CA:"
echo "generate the signed certificate"
openssl x509 -req -days 365 -sha256 -in myregistry.nishanth.com.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out myregistry.nishanth.com-cert.pem -extfile extfile.cnf

echo "For client authentication, create a client key and certificate signing request"
openssl genrsa -out key.pem 4096

echo "Client Certificate CSR Request"
openssl req -subj '/CN=client' -new -key key.pem -out client.csr

echo "To make the key suitable for client authentication, create a new extensions config file"
echo extendedKeyUsage = clientAuth > extfile-client.cnf

echo "generate the signed certificate:"
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile-client.cnf

echo "After generating cert.pem and myregistry.nishanth.com-cert.csr you can safely remove the two certificate signing requests and extensions config files:"
rm -v client.csr myregistry.nishanth.com.csr extfile.cnf extfile-client.cnf

echo "protect your keys from accidental damage, remove their write permissions. To make them only readable by you"
chmod -v 0400 ca-key.pem key.pem myregistry.nishanth.com-key.pem

echo "Certificates can be world-readable, but you might want to remove write access to prevent accidental damage"
chmod -v 0444 ca.pem myregistry.nishanth.com-cert.pem cert.pem

echo "Run the docker Registry with all the necessary Certificates on port 443"

# docker run -d --restart=always --name registry -v /home/ubuntu/certs:/certs -e REGISTRY_HTTP_ADDR=0.0.0.0:443 -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/myregistry.nishanth.com-cert.pem -e REGISTRY_HTTP_TLS_KEY=/certs/myregistry.nishanth.com-key.pem -p 443:443 registry:2
