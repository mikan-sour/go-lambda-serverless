#/bin/bash

REGION="us-east-1"
STAGE="local"
API_NAME="my-function"
DOCKER_FILE="docker-compose.yaml"
ENV_FILE="./.env"
LOCALSTACK_ENDPOINT="http://localhost:4566"
ROUTEPATH="hello"

function fail() {
    echo $2
    exit $1
}

if [[ -f $ENV_FILE ]]; then
    echo "Sourcing environment variables..."
    source $ENV_FILE
else
    fail 9 "$ENV_FILE not present..."
fi

echo "Removing old containers..."
docker-compose -f ${DOCKER_FILE} down -v --remove-orphans

echo "Building new localstack environment..."
docker-compose -f ${DOCKER_FILE} up -d

echo "Building lambda..."
GOOS=linux GOARCH=amd64 CGO_ENABLED=0  go build -o bin/main main.go \
    && zip function.zip bin/main .env

echo "Deploy serverless"
serverless deploy --stage local
[ $? == 0 ] || fail 6 "Failed: SERVERLESS / serverless deploy"

echo "Make sure you run at the endpoint above\n(endpoint: ${LOCALSTACK_ENDPOINT}/restapis/.../_user_request_/${ROUTEPATH})\n"
echo -e "\nDeployment complete"

