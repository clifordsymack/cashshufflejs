const Comms = require('./lib/comms');
comms = new Comms("http://localhost:8080")

comms.checkProtocol()

console.log(comms)
