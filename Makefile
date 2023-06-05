# Makefile zarf-practice app
.DEFAULT_GOAL := docker-image

IMAGE ?= cmwylie19/zarf-practice:latest

.PHONY: image/zarf-practice
binary:  
	GOARCH=amd64 CGO_ENABLED=0 GOOS=linux go build -o zarf-practice ./main.go


.PHONY: docker-image
docker-image:
	docker build -t $(IMAGE) .

.PHONY: push-image
push-image: 
	docker push $(IMAGE)

.PHONY: all