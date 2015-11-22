var express = require('express')
  , app = express()
  , http = require('http')
  , server = http.createServer(app);

server.listen(8000);
console.log("Listening on 8000...");

app.use(express.static(__dirname + '/app'));

