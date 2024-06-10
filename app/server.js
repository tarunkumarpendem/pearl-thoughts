const http = require('http');

const hostname = '0.0.0.0';
const port = 3000;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/html'); // Change content type to HTML
  res.end('<html><head><style>body { background-color: lightblue; }</style></head><body><h1>Hello World!</h1><p>This is a paragraph written by me.</p></body></html>');
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});
