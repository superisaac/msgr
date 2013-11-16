var events = require('events');

Buffer.prototype.indexOf = function (subBuffer) {
    var subBufferLength = subBuffer.length;
    var subLength = this.length - subBufferLength;
    
    for (var i=0; i<subLength+1; i++) {
	var found = true;
	for (var j=0; j<subBufferLength; j++) {
	    if (this[i + j] != subBuffer[j]) {
		found = false;
		break;
	    }
	}
	if (found) {
	    return i;
	}
    }
    return -1;
};

var pid = 1000;
function Protocol(socket) {
    var protoId = pid++;
    var bufferSize = 0;
    var buffer = null;
    var waiting = null;
    var p = {};
    p.em = new events.EventEmitter();
    p.id = function () {return protoId;};

    p.on = function(event, fn) {
	p.em.on(event, fn);
    };
    
    p.write = function (msg) {
	socket.write(msg);
    };

    function processBuffer() {
	while(waiting&&buffer) {
	    var waited = null;
	    if (waiting.type == 'until') {
		var index = buffer.indexOf(waiting.until);
		if (index >= 0) {
		    waited = buffer.slice(0, index + waiting.until.length);
		    buffer = buffer.slice(index + waiting.until.length);
		}
	    } else if (waiting.type == 'nbytes') {
		if (buffer.length > waiting.nbytes) {
		    waited = buffer.slice(0, waiting.nbytes);
		    buffer = buffer.slice(waiting.nbytes);
		} else if (buffer.length == waiting.nbytes) {
		    waited = buffer;
		    buffer = null;
		}
	    }
	    if (waited) {
		var waitingFn = waiting.callback;
		waiting = null;
		waitingFn(waited);
	    } else {
		break;
	    }
	}
    }

    p.readUntil = function(delim, callback) {
	waiting = {type: 'until', until: delim, callback:callback};
	processBuffer();
    }

    p.readCRLF = function(callback) {
	p.readUntil([13, 10], callback);
    }

    p.readCRLFCRLF = function(callback) {
	p.readUntil([13, 10, 13, 10], callback);
    }

    p.readBytes = function(nbytes, callback) {
	waiting = {'type': 'nbytes', nbytes: nbytes, callback: callback};
	processBuffer();
    }

    socket.on('data', function (data) {
	if (buffer == null) {
	    buffer = data;
	} else {
	    buffer = Buffer.concat([buffer, data]);
	}
	processBuffer();
    });

    socket.on('close', function (data) {
	console.warn('close');
	p.em.emit('disconnect');
    });

    socket.on('error', function(e) {
	console.warn('error', e);
	p.em.emit('disconnect');
    });
    
    p.close = function () {
	p.em.emit('disconnect');
	socket.end();
    };
    return p;
}

function packetProtocol(protocol) {
    // parse chunk
    function packetLength(line) {
	var packLen = parseInt(line, 16);
	if (isNaN(packLen)) {
	    console.error('illegal packLen', line);
	    protocol.close();
	}
	protocol.readBytes(packLen, function (body) {
	    protocol.readBytes(2, function (crlf) {
		var arr = JSON.parse(body);
		protocol.em.emit(arr[0], arr[1]);
		protocol.readCRLF(packetLength);
	    });
	});
    };
    
    protocol.emit = function (directive, packet) {
	var jsonData = JSON.stringify([directive, packet]);
	var dataLength = new Number(Buffer.byteLength(jsonData, 'utf-8'));
	var data = dataLength.toString(16) + '\r\n' +  jsonData + '\r\n';
	protocol.write(data);
    };
    protocol.readCRLF(packetLength);
    return protocol;
}

exports.installConnectHandler = function (httpServer, handler) {
    function connectionHandler(request, socket, head) {
	var protocol = Protocol(socket);
	protocol = packetProtocol(protocol);
	protocol.write('HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n');
	
	handler(request, protocol);
	if (head && head.length > 0) {
	    socket.emit('data', head);
	} else {
	    socket.emit('data', new Buffer(''));
	}
    }

    httpServer.on('connect', connectionHandler);
};

