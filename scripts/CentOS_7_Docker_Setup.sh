#!/usr/bin/env bash
set -ex

# Work for CentOS 7

# Install and start Docker
sudo update-ca-trust
sudo yum install -y epel-release
sudo sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo
sudo yum -y update
sudo yum -y remove docker docker-common docker-selinux docker-engine
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum erase docker-engine-selinux
sudo yum -y update
sudo yum -y install docker-ce

sudo yum -y install firewalld
sudo systemctl enable firewalld
sudo service firewalld start
sudo firewall-cmd --permanent --zone=public --add-port=1194/udp

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Install some packages
sudo yum -y install python36 python36-devel python36-pip nano p7zip gcc openssl-devel

# Install Docker Compose
yes | sudo pip3.6 install docker-compose

# Setup bash configurations
mkdir -p $HOME/.bash.d/
curl --url "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash" --output "$HOME/.bash.d/git-completion.bash"
curl --url "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh" --output "$HOME/.bash.d/git-prompt.sh"

cat >> $HOME/.bash_profile << 'EOL'
source "$HOME/.bash.d/git-completion.bash"
source "$HOME/.bash.d/git-prompt.sh"

# Custom prompt
GIT_PS1_SHOWUNTRACKEDFILES=1 # affiche % en présence de fichiers non versionnes
GIT_PS1_SHOWDIRTYSTATE=1 # affiche si des changements sont intervenus
if [ `whoami` = root ]; then
    SYMBOL="#"
else
	SYMBOL="\$"
fi
PS1='\[\033[01;32m\]\u\[\033[0m\] \[\033[1;34m\]\h \[\033[1;35m\]\W\[\033[1;31m\]$(__git_ps1 " (%s)") \[\033[0m\]$SYMBOL '

alias p='pwd'
alias cc='clear'
alias c='cd ../'
alias ls='ls --color=auto'
alias grep='grep --colour=auto'
alias b='source ~/.bashrc'

# Docker aliases
alias d="docker"
alias dc='docker-compose'
alias d.rmunused="docker ps -a | grep Exit | cut -d ' ' -f 1 | xargs docker rm"
alias d.rmiuntagged="echo \"docker rmi $(docker images | grep '^<none>' | awk '{print $3}')\""
alias d.rmvolume='docker volume rm $(docker volume ls -qf dangling=true)'
EOL

source $HOME/.bash_profile

# Install Python packages used for Drive backup
yes | sudo pip3.6 install --upgrade pydrive google-auth-oauthlib pyasn1

# Allow port forwarding (needed on CentOS7)
sudo bash -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'

# Prevent yum for upgrading the docker package
sudo yum -y install yum-versionlock
sudo yum versionlock add docker-ce

echo "*******************************************************"
echo "Setup is done, you should now disconnect and reconnect."
echo "*******************************************************"
