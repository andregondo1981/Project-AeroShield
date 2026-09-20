FROM alpine:latest

# Install latest security patches and updates
RUN apk update && apk upgrade && \
    apk add --no-cache ca-certificates

# Copy your web content or application files (e.g., index.html)
COPY index.html /usr/share/nginx/html/ 
# (Or whatever your web server setup requires)

EXPOSE 80

CMD ["sh", "-c", "echo 'Application ready' && sleep infinity"]