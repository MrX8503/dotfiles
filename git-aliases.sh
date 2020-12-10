#!/bin/bash

# 0 = success
# 1 = error

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
NEW_LINE=$'\n'

# function _prompt {
#     while true; do
#         read -p "$* [y/n]: " yn
#         case $yn in
#             [Yy]*) return 0  ;;
#             [Nn]*) echo -e "${RED}Aborted${NC}" ; return  1 ;;
#         esac
#     done
# }

function prompt() {
    if read -q "choice?$1 [y/n]:"; then
        echo -e "${NEW_LINE}${GREEN}Proceed${NC}"
        return 0
    else
        echo -e "${NEW_LINE}${RED}Aborted${NC}"
        return 1
    fi
}

# get current status of repo
function status() {
    if output=$(git status --porcelain) && [ -z "$output" ]; then
        return 0
    else
        git status
        return 1
    fi
}

# get current branch name
function branchName() {
    BRANCH=`git rev-parse --abbrev-ref HEAD`
    echo ${BRANCH}
}

# deny if branch is master or develop
function isBranchAllowed() {
    BRANCH=`branchName`

    if [ "${BRANCH}" = "master" ] || [ "${BRANCH}" = "develop" ]; then
        echo -e "${RED}Stop! This action is not allowed on the ${BRANCH} branch${NC}"
        echo -e "${RED}Aborted${NC}"
        return 1
    else
        return 0
    fi
}

# fetch, rebase
function gitFr() {
    isBranchAllowed || return 1
    status || return 1

    BRANCH=`branchName`
    echo -e "${YELLOW}You will update the following branch: ${GREEN}${BRANCH}${NC}"
    prompt "Would you like to continue?"

    RETURN_STATUS=$?

    if [ ${RETURN_STATUS} -eq 0 ]; then
        git fetch --prune
        git rebase origin/master
    fi

    return ${RETURN_STATUS}
}

# checkout, fetch, rebase
function gUpdate() {
    if [ ! -z "$1" ]; then
        git checkout $1
    fi

    gitFr

    RETURN_STATUS=$?

    return ${RETURN_STATUS}
}

# checkout, fetch, rebase, push
function gUpdatePush() {
    gUpdate "$@" || return 1

    echo -e "${YELLOW}Branch updated, Would you like to push it to remote?${NC}"
    prompt

    if [ $? -eq 0 ]; then
        git push --force-with-lease
    fi
}

# checkout master, pull, create and checkout new local branch
function gStartWork() {
    if [ -z "$1" ]; then
        echo -e "${YELLOW}Please provide a branch name${NC}"
        echo -e "${RED}Aborted${NC}"
    else
        git checkout master
        git pull
        git checkout -b $1
    fi
}

# new aliases -----------------

function gLog() {
    git log --graph --decorate --pretty=oneline --abbrev-commit
}

function gReset() {
    if [ ! -z "$1" ]; then
        git checkout $1
    fi

    BRANCH=`branchName`
    echo -e "${YELLOW}You will reset the following branch: ${GREEN}${BRANCH}${NC}"
    echo -e "${YELLOW}To match remote. Would you like to continue?${NC}"
    prompt

    if [ $? -eq 0 ]; then
        git reset --hard origin/${BRANCH}
    fi
}

function gUpdateSquash() {
    if [ ! -z "$1" ]; then
        git checkout $1
    fi

    isBranchAllowed || return 1
    status || return 1

    BRANCH=`branchName`
    echo -e "${YELLOW}You will update and squash the following branch: ${GREEN}${BRANCH}${NC}"
    echo -e "${YELLOW}Would you like to continue?${NC}"
    prompt

    RETURN_STATUS=$?

    if [ ${RETURN_STATUS} -eq 0 ]; then
        git fetch --prune
        git rebase -i origin/master
    fi
}
