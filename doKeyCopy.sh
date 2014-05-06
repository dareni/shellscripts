if [[ -z "$1" ]]; then
    echo "Usage: ./doKeyCopy.sh username@host.domain"
else
    cat ~/.ssh/id_rsa.pub | ssh $1 'dd >> ~/.ssh/authorized_keys'
fi
