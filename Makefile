# Makefile hello-zarf app
.DEFAULT_GOAL := docker-image

IMAGE ?= cmwylie19/hello-zarf:latest

.PHONY: binary
binary:  
	GOARCH=amd64 CGO_ENABLED=0 GOOS=linux go build -o hello-zarf ./main.go


.PHONY: docker-image
docker-image:
	docker build -t $(IMAGE) .

.PHONY: push-image
push-image: 
	docker push $(IMAGE)


all: binary docker-image push-image 
