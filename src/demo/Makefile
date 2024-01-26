all:
	docker build -t aspnetapp .
	docker run --rm -it -p 8000:8080 -e ASPNETCORE_HTTP_PORTS=8080 aspnetapp
