#!/usr/bin/env bash

AwesomeGoURL4EN=https://raw.githubusercontent.com/avelino/awesome-go/master/README.md
AwesomeGoURL4CN=https://raw.githubusercontent.com/jobbole/awesome-go-cn/master/README.md

export PATH=$(go env GOPATH)/bin:$PATH

function GetList() {
    curl -s $AwesomeGoURL4EN > AwesomeGo.en.md
    curl -s $AwesomeGoURL4CN > AwesomeGo.cn.md
    awk -F'\]\(' '/^## Contents/,/^# Resources/{if(/^[ \t]*- \[.*\]\(https?:.*\)/) print $2}' AwesomeGo.en.md \
    | sed -e 's#/\?).*#"#' -e 's#^https\?://#\t_ "#' > package.list.all.txt   

    # egrep  '_ "git(hub|lab).com/[^/]*/[^/]*"' package.list.all.txt > package.list.txt
    mv package.list.all.txt package.list.txt


    echo "You are an expert in Golang language. You have been provided following URL addresses, each line correspond to one golang package's introduction or docs page. Please give the import code with blank identifier for all packages in one code chunk. You may search internet if unfamiliar pakcages for their example usage of import or list the names like I give you in seperate code chunk." > prompt.txt
    egrep  -v '_ "git(hub|lab).com/[^/]*/[^/]*"' package.list.all.txt | sed "s#_#-#" | sed 's#"##g'  >> prompt.txt

    cat prompt.txt
}

function SetupMod(){
    echo "package FakePackage" > fake.go
    echo "import (" >> fake.go
    awk -F'[="]' 'BEGIN{OFS="\""; while(getline<"found.list"){found[$1]=1}; while(getline<"replace.list"){old[$1]=$2}}; {$2=(old[$2]!="")?old[$2]:$2;if(found[$2]!=1){print}}' package.list.txt | grep -v "?" | sort -u >> fake.go
    echo ")" >> fake.go

    if [ ! -f go.mod ]; then
        go mod init FakePackage
    fi

    go clean -cache
    go clean -modcache
    
    go mod tidy 2>&1 | tee go-mod.log 

    # todo: this might fail if the package name not match declared
    # awk '/go: found/{print $3}' go-mod.log >> found.list
    # awk -F'"'  '/_/{print $2"=golang.org/x/crypto/ssh"}' fake.go  >> replace.list
}

function DockerCache(){
    rm -rf go.mod go.sum vendor
    docker run --rm -v "$PWD":/mnt -w /mnt golang:1.22 bash -c "go mod init FakePackage && go mod tidy ; tar czvf golang.tar.gz --one-file-system / && go mod vendor"
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
