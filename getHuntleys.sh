#!/usr/bin/bash
if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5" ]; then
    echo Usage: getHuntleys.sh [output dir] [YEAR] [email] [password] [accountname]
    exit -1;
else
    OPDIR="$1"
    YEAR="$2" 
    EMAIL="$3"
    PASSWORD="$4"
    NAME="$5"
    TMPDIR=${OPDIR}/tmp
fi

SITE="http://www.morningstar.com.au"
mkdir -p $TMPDIR
COOKIES=$TMPDIR/cookies.txt
rm -f $COOKIES
touch $COOKIES
FINAL=$TMPDIR/final.txt

doLogin() {
  wget -qO- \
           --server-response \
           --keep-session-cookies \
           --save-cookies $COOKIES \
           --header='Host: www.morningstar.com.au' \
           --header='https://www.morningstar.com.au/Security/Login' \
           --post-data 'UserName='${EMAIL}'&Password='${PASSWORD}'&LoginSubmit=Login' https://www.morningstar.com.au/Security/Login > /dev/null

  echo Login posted. Checking...

  WELCOME=`wget -qO- \
           --server-response \
           --load-cookies $COOKIES \
           --keep-session-cookies \
           --save-cookies $COOKIES \
           'https://www.morningstar.com.au/Common/IframeHeader?ControllerToInject=About&ReqPath=About.mvc/Fsg&introad' \
  |xmllint --html --recover -  \
  |xmllint --html  -xpath "//span [@class='welcome']/text()" -`

  SITE_USER=`echo $WELCOME | awk '{print $2}'`
}

doGetFiles() {
   wget -O- \
            --server-response \
            --load-cookies $COOKIES \
            --keep-session-cookies \
            --save-cookies $COOKIES \
            https://www.morningstar.com.au/Stocks/YMW/Archive/${YEAR} \
   |xmllint --html --recover -  \
   |xmllint --html  -xpath  "//table [@id='ProfileTable']/tbody/tr/td[2]/text()|//table [@id='ProfileTable']/tbody/tr/td[5]/a/@href" - \
   | sed -e 's/.$//' -e '/^$/d' -e 's/^ *//' -e 's/YMW //' -e 's/^href="//' -e 's/"$//' \
   | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/:/g' -e 's/:\(..\):/\n\1:/g' > $FINAL
}

doLoginValidate() {
   doLogin;
   if [ "${SITE_USER}" != "${NAME}" ]; then
       doLogin;
       if [ "${SITE_USER}" != "${NAME}" ]; then
           echo Could not login.
           exit;
       fi
   fi
}

doLoginValidate;
echo Logged in ok.
doGetFiles &> /dev/null

if [[ ! -d $OPDIR/${YEAR} ]]; then
    mkdir $OPDIR/${YEAR}
fi

for LINE in `cat $FINAL`
do
   wknum=`echo $LINE | awk -F: '{print $1}'`
   DOC=`echo $LINE | awk -F: '{print $2}'`
   ver=$wknum
   #ver=`printf "%2d" $wknum`
   filename=${YEAR}YMW${ver}.pdf
   if [[ -w $OPDIR/${YEAR} ]]; then
      if [[ ! -e $OPDIR/${YEAR}/${filename}1 ]]; then
      echo get the file $OPDIR/${YEAR}/${filename}
        echo $OPDIR/${YEAR}/${filename}
        echo $LINE
        wget -O $OPDIR/${YEAR}/${filename} \
           --load-cookies ${COOKIES} \
           --keep-session-cookies \
           --save-cookies ${COOKIES} \
           "${SITE}$DOC"
      fi
   else
      echo Can not write to ${YEAR} dir.
   fi
   #if file is empty remove it.
   if [[ ! -a ${YEAR}/${filename} ]]; then
      echo ${YEAR}/${filename} does not exist.  
   else
      declare -i pdfSize=`du -B 1 ./${YEAR}/${filename} |awk '{print $1}'`
      if [[ ${pdfSize} -lt 20 ]]; then
        rm ${YEAR}/${filename}
      fi
   fi;
done;

echo Do Logout..
wget -O- \
  --server-response \
  --load-cookies $COOKIES \
  --keep-session-cookies \
  --save-cookies $COOKIES \
https://www.morningstar.com.au/Security/LogOut > /dev/null
