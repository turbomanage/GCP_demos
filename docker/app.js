const http = require('http');
const os = require('os');

const server = http.createServer((req, res) => {
  console.log(`Request received at: ${new Date()}`);
  //setTimeout(function() {
  //}, 1000);
   //str = 'Hello from ' + os.hostname();
   str = 'loaderio-89aa8cd72a5e2924e67d074ac080bbcc';
   res.end(str);
});

console.log('Server starting…');

server.listen(8080, () => {
  console.log('Started.')
});

