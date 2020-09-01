docker build -t httpd .

docker run -p 8080:80 httpd

docker tag httpd gcr.io/$DEVSHELL_PROJECT_ID/httpd

docker push gcr.io/$DEVSHELL_PROJECT_ID/httpd

