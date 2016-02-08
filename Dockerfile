FROM node:4

# Create folders
RUN mkdir -p /usr/src/app
RUN mkdir -p /usr/src/TMPApp

# Install coffeeScript
RUN npm install -g coffee-script

# Install project dependencies
WORKDIR /usr/src/app
COPY package.json /usr/src/app/
RUN npm install

# Compile project
COPY . /usr/src/TMPApp
RUN coffee --compile --output /usr/src/app /usr/src/TMPApp

# ADD templates
RUN mkdir -p /usr/src/app/templates
COPY templates /usr/src/app/templates

EXPOSE 3000

CMD ["npm", "start"]