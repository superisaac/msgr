var helper = require('./helper');
var controller = require('./controller');
var tick = require('./tick');

function ensureUser(req, res, next) {
    var token = req.body.token || req.query.token;
    var d = controller.getSession(token);
    d.then(function (session, user) {
	if (!session || !user) {
	    res.status(401).send({message: 'Login required'});
	} else {
	    req.chatSession = session;
	    req.chatUser = user;
	    next();
	}
    });
}

exports.serve = function (app) {
    app.get('/api/v1/register', function (req, res){
	var userId = req.query.uid;
	if (!userId || !(/^[\w@\.]+$/.test(userId))) {
	    res.status(400).send({message: 'Illegal userid, userid must confirm to regexp [\\w\\.@]+'});
	    return;
	}

	var screenName = req.query.screen_name;
	console.log(screenName);
	/*if (/\s/.test(screenName)) {
	    res.status(400).send({'message': 'Illegal screen name!'});
	    return;
	}*/

	var defer = controller.findOrCreateUser(userId, screenName);
	defer.then(function(user, created) {
	    var d1 = controller.findOrCreateSession(user);
	    d1.then(function (session) {
		    var resObj = {token: session.token};
		    resObj.url = 'http://' + req.headers.host;
		    res.send(resObj);
		    //res.send(session.toJSON(user));
	    });
	    if (created) {
		var d2 = controller.findOrCreateUser('assist', 'Assistant');
		d2.then(function(assist, created) {
			controller.postMessage(
			      assist,
			      user,
			      'text', 'Hello!');
		});
	    }
	});
    });

    function fetchUser(req) {
	var defer = helper.Defer();
	if (req.params.userId == '@me') {
	    defer.avail(req.chatUser);
	} else {
	    var d = controller.getUser(req.params.userId);
	    d.then(function (user) {
		    defer.avail(user);
	    });
	}
	return defer;
    }

    app.get('/api/v1/users/:userId', ensureUser, function(req, res) {
	    var d = fetchUser(req);
	    d.then(function (user) {
		    res.send(user.toJSON());
		});
    });

    app.get('/api/v1/usersearch/', ensureUser, function(req, res) {
	    var d = controller.findUsersByName(req.query.name);
	    d.then(function (users) {
		    var arr = [];
		    users.forEach(function (u) {
			    arr.push(u.toJSON());
			});
		    res.send(arr);
		});
    });
    
    app.post('/api/v1/messages/', ensureUser, function(req, res) {
	var toUserId = req.body.uid;
	var type;
	var content;
	var extInfo = {};
	if (req.files && req.files.image) {
	    type = 'image';
	    content = req.files.image;
	} else if (req.files && req.files.audio) {
	    type = 'audio';
	    content = req.files.audio;
	    var duration = parseInt(req.body.duration);
	    if (isNaN(duration)) {
		duration = -1;
	    }
	    extInfo = {'duration': duration};
	} else {
	    type = 'text';
	    content = req.body.text;
	    if (!content) {
		res.status(400).send({'message': 'Text is empty'});
		return;
	    }
	}
	var d = controller.getUser(toUserId);
	d.then(function (user) {
	    if (!user) {
		res.status(404).send({'message': 'To user not found'});
		return;
	    }

	    var d1 = controller.postMessage(req.chatUser, user, type, content, extInfo);
	    d1.then(function (msg) {
		    var j = msg.toJSONWithUser(req.chatUser, user);
		    var host = req.headers.host;
		    j = controller.addFileURL(host, j);
		    res.send(j);
	    });
	});
    });

    /*    app.post('/api/v1/images/', ensureUser, function(req, res) {
	var toUserId = req.body.uid;
	var image = req.files.image;
	if (typeof image == 'string') {
	    image = new Buffer(image);
	}
	var d = controller.getUser(toUserId);
	d.then(function (user) {
	    if (!user) {
		res.status(404).send({'message': 'To user not found'});
		return;
	    }
	    var d1 = controller.postMessage(req.chatUser, user, 'image', image);
	    d1.then(function (msg) {
		    var j = msg.toJSONWithUser(req.chatUser, user);
		    var host = req.headers.host;
		    j = controller.addFileURL(host, j);
		    res.send(j);
	    });
	});
	}); */

};
