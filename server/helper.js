var mongoose = require('mongoose');
var fs = require('fs');

var configData = fs.readFileSync('config.json');
exports.config = JSON.parse(configData);

// Defer object
Array.prototype.pushArguments = function (args) {
    for(var i=0; i<args.length; i++) {
	this.push(args[i]);
    }
};

function Defer() {
    var defer = {};
    defer.isOK = false;
    defer.callbacks = [];
    defer.args = [];
    defer.avail = function() {
	if (defer.isOK) {
	    return;
	}
	defer.args.pushArguments(arguments);
	defer.isOK = true;
	defer.callbacks.forEach(function (cb) {
		cb.apply(null, defer.args);
	    });
	defer.callbacks = [];
    };

    defer.then = function(fn) {
	if (this.isOK) {
	    fn.apply(null, defer.args);
	} else {
	    defer.callbacks.push(fn);
	}
    };

    defer.wait = function() {
	var childDefers = [];
	childDefers.pushArguments(arguments);

	var counter = childDefers.length;
	var results = [];
	for (var i=0; i<counter; i++) {
	    results.push(null);
	}
	
	if (counter > 0) {
	    childDefers.forEach(function(c, index) {
		    c.then(function() {
			    if (arguments.length > 0) {
				var arr = [];
				arr.pushArguments(arguments);
				results[index] = arr;
			    }
			    counter--;
			    if (counter == 0) {
				defer.avail.apply(null, results);
			    }
			});
		});
	}
    };
    return defer;
}

exports.Defer = Defer;


// Multipart
var multipart_boundary = 'thisisarandomstring31274812947y32';
exports.mixed_part_head = function () {
    return '--' + multipart_boundary + '\r\n';
};

exports.mixed_part_data = function (content_type, part_data, isend) {
    var buffer = new Buffer(1024 * 1024 * 4, 'binary');
    var offset = 0;
    offset += buffer.write('Content-Type: ' + content_type + '\r\n\r\n', offset);
    offset += buffer.write(part_data, offset);
    offset += buffer.write('\r\n', offset);
    if (isend) {
	offset += buffer.write('--' + multipart_boundary + '--\r\n', offset);
    } else {
	offset += buffer.write('--' + multipart_boundary + '\r\n', offset);
    }
    var data = buffer.toString('binary', 0, offset);
    console.info('part', data);
    return data;
};

exports.boundary = function () {
    return multipart_boundary;
};

var counter = 0;
exports.newId = function (prefix) {
    if (counter > 1000) {
	counter = 0;
    }
    return prefix + '.' + (new Date().getTime()) + '.' + counter++;
};


exports.assert = function (condition) {
    if (!condition) {
	throw new Error('Assert failure!');
    }
};

exports.assertNoError = function (err) {
    if (!!err) {
	throw err;
    }
};

exports.now = function () {
    return Math.floor(new Date().getTime()/1000);
};

exports.timeStamp = function (ts) {
    return Math.floor(ts/1000);
};

exports.getUserIndex = function (fromUserId, toUserId) {
    if (fromUserId > toUserId) {
	return toUserId + ' ' + fromUserId;
    } else {
	return fromUserId + ' ' + toUserId;
    }
};

exports.getIDRangeOptions = function (query) {
    var options = {};
    if (query.max_id) {
	options.maxId = query.max_id;
    }
    if (query.since_id) {
	options.sinceId = query.since_id;
    }
    return options;
};

exports.handleIDRangeOptions = function (options) {
    options = options || {};
    var idRange = null;
    if (options.maxId) {
	if (!idRange) {
	    idRange = {};
	}
	idRange['$lt'] = new ObjectId(options.maxId);
    }

    if (options.sinceId) {
	if (!idRange) {
	    idRange = {};
	}
	idRange['$gt'] = new ObjectId(options.sinceId);
    }
    return idRange;
};

exports.forEachArgument = function(args, callback) {
    for(var i=0; i<args.length; i++) {
	callback(args[i], i);
    }
};

exports.connectMongodb = function (callback) {
    var dbConfig = exports.config.mongoDB;
    mongoose.connect(dbConfig.host, dbConfig.database, function () {
	    if (typeof callback == 'function') {
		callback();
	    }
	});
};

exports.random = {
    choice: function(candidates) {
	var index = Math.floor(Math.random() * candidates.length);
	if (typeof candidates == 'string') {
	    return candidates.substr(index, 1);
	} else {
	    return candidates[index];
	}	
    },
    sample: function (candidates, nlength) {
	var arr = [];
	for(var i=0; i<nlength; i++) {
	    var c = exports.random.choice(candidates);
	    arr.push(c);	    
	}
	if (typeof candidates == 'string') {
	    arr = arr.join('');
	}
	return arr;
    }    
};