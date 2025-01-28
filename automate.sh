#!/bin/bash

# Define variables
REMOTE_USER="mohammad"
REMOTE_HOST="nl-rv.maxtld.com"
REMOTE_PORT="3679"
REMOTE_PATH="/etc/kubernetes/admin.conf"       # Path to the admin.conf file on the remote server
LOCAL_KUBE_DIR="$HOME/.kube"                   # Local directory for kubeconfig
LOCAL_KUBE_CONFIG="$LOCAL_KUBE_DIR/admin.conf" # Local path where the config will be stored
EXTERNAL_IP="10.254.11.134"                    # The external IP of the Kubernetes API server
API_SERVER="https://$EXTERNAL_IP:6443"         # API server URL with the correct IP
SUDO_PASSWORD="use your password"              # Replace with your actual sudo password

# ssh-key set in server
ssh-copy-id -p 3679 root@nl-rv.maxtld.com

#update and upgrade server pre-install
ansible-playbook -i kubespray/inventory/mycluster/inventory.ini jobs/pre-install.ini -K

#echo "Install cluster with kubespray"
cd ./kubespray
ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml -b -v --private-key=~/.ssh/id_rsa -K -u mohammad
cd ..

#Add tunnel for kubectl connect locally
ssh -f -N -L 6443:10.254.11.134:6443 -p 3679 mohammad@nl-rv.maxtld.com

# Ensure the .kube directory exists on the local machine
mkdir -p $LOCAL_KUBE_DIR

# Temporarily adjust permissions on the remote file and copy it
echo "Adjusting permissions on the remote file and copying it locally..."
ssh -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST <<EOF
  echo "$SUDO_PASSWORD" | sudo -S chmod 644 $REMOTE_PATH
EOF

# Copy the kubeconfig file from the remote server to the local machine
scp -P $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH $LOCAL_KUBE_CONFIG

# Revert the permissions on the remote server
ssh -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST <<EOF
  echo "$SUDO_PASSWORD" | sudo -S chmod 600 $REMOTE_PATH
EOF

# Update the server URL in the kubeconfig file
#kubectl config set-cluster kubernetes --server=$API_SERVER --kubeconfig=$LOCAL_KUBE_CONFIG
echo "export KUBECONFIG=/home/mohammad/.kube/admin.conf" >>~/.bashrc
source ~/.bashrc

# Verify kubectl is working with the new configuration
echo "Verifying kubectl connection..."
#kubectl --kubeconfig=$LOCAL_KUBE_CONFIG get nodes
kubectl --kubeconfig=$LOCAL_KUBE_CONFIG get nodes

if [ $? -eq 0 ]; then
  echo "Kubectl is now configured and connected to the cluster."
else
  echo "Error: Failed to connect to the Kubernetes cluster."
  exit 1
fi

helm install wordpress-mysql-pma ./wordpress-mysql-pma

if [ $? -eq 0 ]; then
  echo "project deploy successfully."
else
  echo "Error: Failed to deploy to the Kubernetes cluster."
  exit 1
fi
