#!/bin/bash
set -e

sudo apt-get update
sudo apt-get install -y python make g++ gcc

cd service

################################################################
# Install dependencies
################################################################
echo 'Installing nvm (Node.js Version Manager)...'
npm config delete prefix
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
. ~/.nvm/nvm.sh

echo 'Installing Node.js 13.10...'
nvm install 13.10 1>/dev/null
npm install --progress false --loglevel error 1>/dev/null

################################################################
# Cloud Functions artifacts
################################################################
ibmcloud target -o "${CF_ORG}" -s "${CF_SPACE}"
if ! ibmcloud fn namespace get fibonacci; then
  ibmcloud fn namespace create fibonacci
fi
NAMESPACE_ID=$(ibmcloud fn namespace get fibonacci --properties | grep ID | awk '{print $2}')
ibmcloud fn property set --namespace $NAMESPACE_ID
FUNCTIONS_HOST=$(ibmcloud fn property get --apihost | awk -F '\t' '{print $3}')

# Deploy the actions
echo "Uninstall"
node deploy.js --apihost $FUNCTIONS_HOST --auth $PIPELINE_BLUEMIX_API_KEY --namespace $NAMESPACE_ID --uninstall
echo "Install"
node deploy.js --apihost $FUNCTIONS_HOST --auth $PIPELINE_BLUEMIX_API_KEY --namespace $NAMESPACE_ID --install

echo "Fibonacci service available at https://${FUNCTIONS_HOST}/api/v1/web/${NAMESPACE_ID}/default/fibonacci"
