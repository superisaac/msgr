var controller = require('./controller');
var userConnPool = {};

exports.emit = function(userId, directive, message) {
    var arr = userConnPool[userId];
    if (arr) {
	arr.forEach(function(conn) {
	    conn.emit(directive, message);
	});
    }
};

exports.syncUserMessages = function (user)  
{
    var arr = userConnPool[user.userId];
    if (arr && arr.length > 0) {
	console.info('sync message to', arr.length);
	controller.syncMessages(user, arr);
    }
};

function TickConnection(req, socket, user) {
    this.request = req;
    this.socket = socket;
    this.user = user;
    this.cid = socket.id;
    this.timer = null;
}

TickConnection.prototype.emit = function(directive, data) {
    console.log('emit', directive, data);
    this.socket.emit(directive, data);
};

TickConnection.prototype.addToPool = function() {
    var connList = userConnPool[this.user.userId];
    if(!connList) {
	userConnPool[this.user.userId] = [this];
    } else {
	connList.push(this);
    }
    var conn = this;
    this.timer = setInterval(function () {
	conn.emit('ping', {});
    }, 10000);
};

TickConnection.prototype.removeFromPool = function() {
    if (this.timer) {
	clearInterval(this.timer);
	this.timer = null;
    }

    var connList = userConnPool[this.user.userId];
    if (connList) {
	var i = -1;
	for(i=0;i<connList.length;i++) {
	    if (connList[i] == this) {
		break;
	    }
	}
	if (i>=0 && i<connList.length) {
	    connList.splice(i, 1);
	}
	if (connList.length == 0) {
	    delete userConnPool[this.user.userId];
	}
    }
};

exports.tickHandler = function(request, socket) {
    socket.on('login', function (token) {
	    console.info('get session by token', token);
	    var d = controller.getSession(token);
	    d.then(function (session, user) {
		    if (!user) {
			console.info('login failed');
			socket.emit('login failed', {});
			setTimeout(socket.close, 1000);
			return;
		    }
		    socket.emit('login success', user.toJSON());
		    // Login
		    var connection = new TickConnection(request,
							socket,
							user);
		    connection.addToPool();

		    socket.on('disconnect', function () {
			    console.info('remove connection');
			    connection.removeFromPool();
			});
		    // Send new messages
		    controller.syncMessages(user, [connection]);
		});
	});
};

