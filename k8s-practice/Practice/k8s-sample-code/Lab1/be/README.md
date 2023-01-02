## Get API basic
https://viblo.asia/p/xay-dung-restful-api-don-gian-voi-nodejs-1Je5EdewlnL
https://www.tutorialspoint.com/nodejs/nodejs_restful_api.htm
https://blog.logrocket.com/setting-up-a-restful-api-with-node-js-and-postgresql-d96d6fc892d8/


docker run -d \
    --name some-postgres \
    -e POSTGRES_PASSWORD=admin \
    -e POSTGRES_USER=admin \
    -e POSTGRES_DB=users \
    -p 5432:5432 \
    postgres

docker run -d \
    --name nodejs-be \
    -e DB_USER=admin \
    -e DB_HOST=10.88.231.182 \
    -e DB_NAME=users \
    -e DB_PASSWORD=admin \
    -p 3000:3000 \
    nodejs-be
