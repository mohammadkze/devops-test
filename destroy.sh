cd kubespray
ansible-playbook -i inventory/mycluster/inventory.ini  reset.yml -b -v --private-key=~/.ssh/id_rsa -K -u mohammad
cd ..
echo "destroy cluster"