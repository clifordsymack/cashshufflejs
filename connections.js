//Just an example of TCP socket and TLS for using with cashshuffle server

var net = require('net');
var tls = require('tls');


const magic = "42bcc32669467873";

var client = new net.Socket();

client.connect( 8080, '127.0.0.1', function(){
    hi_msg = new Buffer(magic + "00000014" + "0a120a101a090a07736f6d656b65793a0308e807", "hex");
    console.log('connected');
    client.write(hi_msg);
});

client.on('data', function(data){
    console.log(data.toString('hex'));
    console.log('<<DELIMITER>>');
    client.destroy();
});

client.on('close', function(data){
    console.log('closed');
});

var client2 = tls.connect(8080, "shuffle.imaginary.cash", {}, function(){
  hi_msg = new Buffer(magic + "00000014" + "0a120a101a090a07736f6d656b65793a0308e807", "hex");
  console.log("TLS connected");
  if(client2.authorized){
    client2.write(hi_msg)
  } else {
    console.log("Connection not authorized")
  }
});

client2.on('data', function(data){
  console.log(data.toString('hex'));
  console.log("<<DELIMITER>>");
  client2.end();
})

client2.on('close', function(){
  console.log("TLS ended");
})
