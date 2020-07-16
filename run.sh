#!/usr/bin/env bash

AwesomeGoURL4EN=https://raw.githubusercontent.com/avelino/awesome-go/master/README.md
AwesomeGoURL4CN=https://raw.githubusercontent.com/jobbole/awesome-go-cn/master/README.md

export PATH=$(go env GOPATH)/bin:$PATH

function GetList() {
    curl -s $AwesomeGoURL4EN > AwesomeGo.en.md
    curl -s $AwesomeGoURL4CN > AwesomeGo.cn.md
    awk -F'\]\(' '/^### Contents/,/^# Resources/{if(/^[ \t]*\* \[.*\]\(https?:.*\)/) print $2}' AwesomeGo.en.md \
    | sed -e 's#/\?).*#"#' -e 's#^https\?://#\t_ "#' > package.list.txt   
}

function SetupMod(){
    echo "package FakePackage" > fake.go
    echo "import (" >> fake.go
    cat package.list.txt >> fake.go
    echo ")" >> fake.go

    if [ ! -f go.mod ]; then
        go mod init FakePackage
    fi
    
    go mod tidy | tee go-mod.log 
    # todo: this might fail if the package name not match declared
}

function ZipPackage(){
    #go mod vendor
    tar czf golang-pkgs.tar.gz -C $(go env GOPATH)/pkg/mod/cache/ ./
}

function Commit(){
    git add AwesomeGo.en.md AwesomeGo.cn.md package.list.txt fake.go go.mod
    git commit -m "pull from awesome-go on $(date);"
    rclone copy -P golang-pkgs.tar.gz remote:/golang-pkgs.tar.gz
}

$1
# GetList
# SetupMod
# ZipPackage