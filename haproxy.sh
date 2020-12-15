echo "Install HAProxy 2.1"
sudo apt -y install software-properties-common
sudo add-apt-repository ppa:vbernat/haproxy-2.1 --yes
sudo apt -y update
sudo apt -y install haproxy
