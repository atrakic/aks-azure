all:
	docker build -t lb .
	docker tag lb $(REGISTRY)/$(IMAGE)
	docker push $(REGISTRY)/$(IMAGE)
