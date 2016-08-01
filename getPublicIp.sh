# Pull the public ip address from the firewall.
# Maintained at: git@github.com:dareni/shellscripts.git

NAME=$1
PASSWORD=$2

URL=`wget 192.168.1.253 -O - | grep '<form' |awk '{print $3}'| sed 's/^........//' | sed 's/.$//'`
wget -O - --post-data 'HngLoginUserName='${NAME}'&HngLoginPassword='${PASSWORD} 192.168.1.253${URL} | grep '^<div.*WAN IP' |sed 's/^.\{60\}//' | sed 's/.\{111\}$//'


#wget 192.168.1.253 -O index.html
#URL=`grep '<form' index.html |awk '{print $3}'| sed 's/^........//' | sed 's/.$//'`


#wget --no-cookies \
#--header 'Host: 192.168.1.253' \
#--header 'Connection: keep-alive' \
#--header 'Content-Length: 48' \
#--header 'Cache-Control: max-age=0' \
#--header 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
#--header 'Origin: http://192.168.1.253' \
#--header 'Upgrade-Insecure-Requests: 1' \
#--header 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36' \
#--header 'Content-Type: application/x-www-form-urlencoded' \
#--header 'Referer: http://192.168.1.253/HngLogin.asp' \
#--header 'Accept-Encoding: gzip, deflate' \
#--header 'Accept-Language: en-GB,en-US;q=0.8,en;q=0.6' \
#-O out.html --post-data 'HngLoginUserName=&HngLoginPassword=' 192.168.1.253${URL}

#grep '^<div.*WAN IP' out.html |sed 's/^.\{60\}//' | sed 's/.\{111\}$//'

