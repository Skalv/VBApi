FROM skalv/docker-node-bower-brunch

MAINTAINER Florent Boutin "fboutin76@gmail.com"

ADD . /var/www/myapp

RUN npm install

EXPOSE 3333

CMD ["npm", "start"]