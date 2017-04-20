#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
#Print the status of all git repo subdirectories.

defaultStatus() {
    git remote update
    LOCAL=$(git rev-parse @{0})
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})


    if [ "$LOCAL" = "$REMOTE" ]; then
         STATUS="Up-to-date"
    elif [ "$LOCAL" = "$BASE" ]; then
         STATUS="Need-to-pull"
    elif [ "$REMOTE" = "$BASE" ]; then
         STATUS="Need-to-push"
    else
         STATUS="Diverged"
    fi

    DETAIL=`git status -z`

    if [ -n "$DETAIL" -o "$STATUS" != "Up-to-date" ]; then
        echo "  ::: $STATUS"
        git status -s
        echo "\n\n"
    fi
}

stashStatus() {
    git stash list
    echo "\n"
}


OLDPWD=`pwd`
CMD=""

if [ -z "$1" ]; then
    REPODIR=.
else
    if [ "$1" = "-stash" ]; then
        CMD=stash
    else
        REPODIR=$1
    fi
fi

if [ -n "$2" ]; then
    if [ "$2" = "-stash" ]; then
        CMD=stash
    else
        REPODIR=$2
    fi
fi


for gitrepo in `find $REPODIR  -name ".git" -execdir pwd \;`
do
    cd "$gitrepo"
    pwd
    if [ -z "$CMD" ]; then
        defaultStatus
    else
        stashStatus
    fi

done

cd $OLDPWD
