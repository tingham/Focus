package main

import (
	"log"
    "regexp"
	"net/http"
    "io/ioutil"
    "github.com/elazarl/goproxy"
    "os"
)

func main() {

    var templateFilePath string
    if len(os.Args) == 1 {
        templateFilePath = "./template.html"
    } else if len(os.Args) == 2 {
        templateFilePath = os.Args[1]
    } else {
        panic("Unknown number of arguments. Please enter a template file")
    }

    content, err := ioutil.ReadFile(templateFilePath)
    if err != nil {
        panic(err)
    }

    var htmlStr string = string(content)

	proxy := goproxy.NewProxyHttpServer()
    proxy.OnRequest(goproxy.ReqHostMatches(regexp.MustCompile("^.*$"))).HandleConnect(goproxy.AlwaysMitm)
    proxy.OnRequest().DoFunc(func(req *http.Request, ctx *goproxy.ProxyCtx) (*http.Request, *http.Response) {
        return req, goproxy.NewResponse(req, goproxy.ContentTypeHtml, http.StatusForbidden, htmlStr)
    })

	log.Fatalln(http.ListenAndServe(":8401", proxy))
}
