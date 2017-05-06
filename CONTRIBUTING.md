# Contributors Guidelines

## Local Development

HTTPBin.com is used in out tests suite extensively, but you can run local version using docker container:

```
docker pull citizenstig/httpbin:latest
docker run -d -p 8000:80 citizenstig/httpbin:latest
```

After doing so change `/etc/hosts` record so httpbin.com will be served from localhost:

```
sudo -s -- sh -c 'echo "127.0.0.1 httpbin.org" >> /etc/hosts'
```
