#!/bin/bash
if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
	  if [[ "${TRAVIS_BRANCH}" == "${TRUNK_BRANCH}" && "${BUILD_REQUIRES_MAINTENANCE}" == "0" || "${TRAVIS_BRANCH}" == "${MAINTENANCE_BRANCH}" ]]; then
## install kubectl
			curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
			chmod +x ./kubectl
			sudo mv ./kubectl /usr/local/bin/kubectl
## Install helm
			curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
			chmod 700 get_helm.sh
			./get_helm.sh
# Credentials to GCE
			gcloud auth  activate-service-account  --key-file=$TRAVIS_BUILD_DIR/eHealth-eef414faa06b.json
			gcloud container clusters get-credentials dev --zone europe-west1-d --project ehealth-162117
#get helm charts
			git clone https://$GITHUB_TOKEN@github.com/edenlabllc/ehealth.charts.git
			cd ehealth.charts
#get version and project name
			PROJECT_NAME=$(sed -n 's/.*app: :\([^, ]*\).*/\1/pg' "$TRAVIS_BUILD_DIR/mix.exs")
			PROJECT_VERSION=$(sed -n 's/.*@version "\([^"]*\)".*/\1/pg' "$TRAVIS_BUILD_DIR/mix.exs")
			#PROJECT_VERSION="0.1.261"
			sed -i'' -e "1,10s/tag:.*/tag: \"$PROJECT_VERSION\"/g" "report/values.yaml"
			helm init --upgrade
			sleep 15
			helm upgrade  -f report/values.yaml $Chart report
			cd $TRAVIS_BUILD_DIR/bin
			./wait-for-deployment.sh api $Chart 180
   				if [ "$?" -eq 0 ]; then
     				kubectl get pod -n$Chart | grep api 
     				cd $TRAVIS_BUILD_DIR/ehealth.charts && git add . && sudo  git commit -m "Bump $Chart api to $PROJECT_VERSION" && sudo git pull && sudo git push
     				exit 0;
   				else 
   	 				kubectl logs $(sudo kubectl get pod -n$Chart | awk '{ print $1 }' | grep api) -n$Chart 
   	 				helm rollback $Chart  $(($(helm ls | grep $Chart | awk '{ print $2 }') -1)) 
   	 				exit 1;
   				fi;
 		fi;
fi;