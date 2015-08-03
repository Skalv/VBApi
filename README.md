# VBApi
Node API for VBulletin


### Installation

### SSH pipe for connect to remote MYSQL

```sh
$ ssh -f user@monserveurdistant.com -L 3307:localhost:3306 -N
$ kill $(ps aux | grep ssh| grep 3307| awk '{print $2}')
```
