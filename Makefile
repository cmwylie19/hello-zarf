# Makefile zarf-practice app
.DEFAULT_GOAL := docker-image

IMAGE ?= cmwylie19/zarf-practice:latest

.PHONY: binary
binary:  
	GOARCH=amd64 CGO_ENABLED=0 GOOS=linux go build -o zarf-practice ./main.go


.PHONY: docker-image
docker-image:
	docker build -t $(IMAGE) .

.PHONY: push-image
push-image: 
	docker push $(IMAGE)


all: binary docker-image push-image 
