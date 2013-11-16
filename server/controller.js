var fs = require('fs');
var im = require('imagemagick');

var mongoose = require('mongoose');
var uuid = require('node-uuid');
var crypto = require('crypto');
var modeldef = require('./modeldef');
var helper = require('./helper');
var tick = require('./tick');
var indexer = require('./indexer');

var ObjectId = mongoose.Types.ObjectId;

function writeFile(file, surfix) {
    var defer = helper.Defer();
    fs.readFile(file.path, function(err, data) {
	    helper.assertNoError(err);
	    var md5sum = crypto.createHash('md5');
	    md5sum.update(data);
	    var hex = md5sum.digest('hex');
	    var fileName = hex + surfix;
	    var absName = helper.config.uploadDir + '/' + fileName;
	    console.info('absName', absName, file.path);
	    fs.writeFile(absName, data, function(err) {
		    helper.assertNoError(err);
		    defer.avail(fileName, null);
		});
	});
    return defer;
}

function writeAudio(file, surfix, duration) {
    var defer = helper.Defer();
    var d  = writeFile(file, surfix);
    d.then(function (fileName, _) {
	    var metadata = {'duration': duration};
	    defer.avail(fileName, metadata);
	});
    return defer;
}

function writeImage(file, surfix) {
    var defer = helper.Defer();
    var d  = writeFile(file, surfix);
    d.then(function (fileName, _) {
	    im.readMetadata(file.path, function (err, metadata) {
		    helper.assertNoError(err);
		    defer.avail(fileName, metadata);  
		});
	});
    return defer;
}

// TODO using screenName
exports.findUsersByName = function (screenName) {
    var defer = helper.Defer();
    modeldef.ChatUser.find({
	    screenName:screenName
		}, {}, {limit: 5},
	function (err, users) {
	    helper.assertNoError(err);
	    defer.avail(users);
	});
    return defer;
};

exports.registerUser = function (userId, screenName) {
    var fd = helper.Defer();
    var defer = exports.findOrCreateUser(userId, userId);
    defer.then(function(user, created) {
	    var d1 = exports.findOrCreateSession(user);
	    d1.then(function (session) {
		    console.info(session);
		    var resObj = {token: session.token};
		    //resObj.url = 'http://' + req.headers.host;
		    fd.avail(resObj);
		});
	    if (created) {
		var d2 = exports.findOrCreateUser('assist', 'Assistant');
		d2.then(function(assist, created) {
			exports.postMessage(
					    assist,
					    user,
					    'text', 'Hello!');
		    });
	    }
	});
    return fd;
};

exports.findOrCreateUser = function (userId, screenName) {
    var defer = helper.Defer();
    var d = exports.getUser(userId);
    d.then(function (user) {
	    if (user) {
		if (!!screenName && user.screenName != screenName) {
		    user.screenName = screenName;
		    user.nameTerms = indexer.splitName(screenName);
		    user.save();
		}
		defer.avail(user, false);
	    } else {
		screenName = screenName || userId;
		user = modeldef.ChatUser({
			userId: userId,
			screenName: screenName,
			dateCreated: helper.now(),
			dateModified: helper.now(),
			nameTerms: indexer.splitName(screenName),
		        syncedMessageId: new ObjectId()
		    });
		user.save(function (err) {
			helper.assertNoError(err);
			defer.avail(user, true);
		    });
	    }
	});
    return defer;
};

exports.findOrCreateSession = function (user) {
    var defer = helper.Defer();
    
    modeldef.ChatSession.collection.findAndModify({
	    userObjectId: user._id
	}, {},{
	    '$set': {
		dateTouched: helper.now(),
		    }
	}, {upsert: true, 'new': true},
	function(err, session) {
	    helper.assertNoError(err);
	    session = new modeldef.ChatSession(session);

	    if (!session.token) {
		session.token = uuid.v4();
		modeldef.ChatSession.update({_id: session._id},
					    {token: session.token}, {},
					    function (err, num) {
						helper.assertNoError(err);					    });
	    }
	    defer.avail(session);
	});
    return defer;
};

exports.getUser = function (uid) {
    var defer = helper.Defer();
    modeldef.ChatUser.findOne({userId: uid},
			       function (err, user) {
				   helper.assert(!err);
				   defer.avail(user);
			       });
    return defer;
};

exports.getUserById = function (uid) {
    var defer = helper.Defer();
    modeldef.ChatUser.findById(uid,
			       function (err, user) {
				   helper.assert(!err);
				   defer.avail(user);
			       });
    return defer;
};

exports.getSession = function (token) {
    // TODO: check session touch time
    var defer = helper.Defer();
    if (!token) {
	defer.avail(null, null);
	return defer;
    }

    modeldef.ChatSession.findOne(
          {token: token},
	  function(err, session) {
	      helper.assertNoError(err);
	      if (session) {
		  var d1 = exports.getUserById(session.userObjectId);
		  d1.then(function (user) {
			  defer.avail(session, user);
		      });
	      } else {
		  defer.avail(session, null);
	      }
	  });
    return defer;
};

exports.postMessage = function (fromUser, toUser, msgType, content, extInfo) {
    var ioDefer;
    extInfo = extInfo || {};
    if (msgType == 'audio') {	
	ioDefer = writeAudio(content, '.aac', extInfo.duration||-1);
    } else if (msgType=='image') {
	ioDefer = writeImage(content, '.jpg');
    } else {
	ioDefer = helper.Defer();
	ioDefer.avail(content, null);
    }
    
    var defer = helper.Defer();
    ioDefer.then(function(c, metadata) {
	var msg = new modeldef.ChatMessage();
	msg.fromUserId = fromUser._id;
	msg.toUserId = toUser._id;
	msg.msgType = msgType;
	msg.content = c;
	msg.metadata = metadata;
	msg.state = modeldef.ChatMessage.stateSent;
	msg.save(function (err) {
	    helper.assertNoError(err);
	    defer.avail(msg);
	    tick.syncUserMessages(toUser);
	});
    });
    return defer;
};


function syncOneMessage(user) {
    var defer = helper.Defer();
    modeldef.ChatMessage.collection.findAndModify({
	    state: modeldef.ChatMessage.stateSent,
	    toUserId: user._id
	}, {_id:1},{
	    '$set': {state: modeldef.ChatMessage.stateSynced}
	}, {upsert: false, 'new': true},
	function(err, msg) {
	    helper.assertNoError(err);
	    if (msg) {
		msg = new modeldef.ChatMessage(msg);
	    }
	    defer.avail(msg);
	});
    return defer;
};

exports.addFileURL = function (host, msgjson) {
    console.info('add file url host', host);
    if (msgjson.msgType == 'image') {
	msgjson.content = 'http://' + host + '/upload/' + msgjson.content;
    } else if (msgjson.msgType == 'audio') {
	msgjson.content = 'http://' + host + '/upload/' + msgjson.content;
    }
    return msgjson;
};

exports.syncMessages = function(user, conns){
    if (!conns || conns.length <= 0) {
	return;
    }
    var d = syncOneMessage(user);
    d.then(function(msg) {
	    if (msg) {
		var d = msg.getFromUser();
		d.then(function(fromUser){
		    conns.forEach(function(conn) {
			var j = msg.toJSONWithUser(fromUser);
			var host;
			if(helper.config.staticHost) {
			    host = helper.config.staticHost;
			} else if(conn.request.headers.host){
			    host = conn.request.headers.host;
			} else {
			    console.error('connection host not found');
			}
			j = exports.addFileURL(host, j);
			conn.emit('message comes', j);
			    });
		    setTimeout(function() {
			exports.syncMessages(user, conns);
		    }, 0);
		});
	    }
	});
};
