var mongoose = require('mongoose');
var helper = require('./helper');
var Mixed = mongoose.Schema.Types.Mixed;
var ObjectId = mongoose.Schema.Types.ObjectId;

var DateDef = {
    type: Number,
    index: 1,
    set: function (v) {return Math.round(v);}
};

var chatSessionSchema = mongoose.Schema({
        'token': String,
	'userObjectId': {type: ObjectId, index:1},
	'data': Mixed,
	'dateTouched': DateDef
    });

chatSessionSchema.index({'token': 1}, {unique: 1, sparse:1});
exports.ChatSession = mongoose.model('ChatSession', chatSessionSchema);

var chatUserSchema = mongoose.Schema({
	'userId': {type:String, index:1},
	'screenName': String,
	'dateCreated': DateDef,
	'dateModified': DateDef,
        'syncedMessageId': {type:ObjectId, default: null},
	'nameTerms': Array
    });
chatUserSchema.methods.toJSON = function () {
    return {
	'id': this.userId,
	'screen_name': this.screenName,
	'lm': this.dateModified
    }
};
chatUserSchema.index({'nameTerms':1});

exports.ChatUser = mongoose.model('ChatUser', chatUserSchema);

var chatMessageSchema = mongoose.Schema({
	'state': {type:Number, index:1},
	'fromUserId': {type:ObjectId, index:1},
	'toUserId': {type: ObjectId, index:1},
	'msgType': {type: String, default: 'text'},
	'content': String,
	'userIndex': {type: String, index: 1},
	'metadata': Object,
	'dateCreated': DateDef
    });
chatMessageSchema.pre('save', function (next) {
	var fromUserString = this.fromUserId.toString();
	var toUserString = this.toUserId.toString();
	if (fromUserString > toUserString) {
	    this.userIndex = toUserString + ' ' + fromUserString;
	} else {
	    this.userIndex = fromUserString + ' ' + toUserString;
	}
	next();
    });

chatMessageSchema.methods.getFromUser = function() {
    var d = helper.Defer();
    exports.ChatUser
           .findById(this.fromUserId,
		     function(err, user) {
			 helper.assertNoError(err);
			 d.avail(user);
		     });
    return d;
};

chatMessageSchema.methods.getToUser = function() {
    var d = helper.Defer();
    this.model('ChatMessage')
        .findById(this.toUserId,
		 function(err, user) {
		     helper.assertNoError(err);
		     d.avail(user);
		 });
    return d;
};

chatMessageSchema.methods.toJSONWithUser = function() {
    var d = {
	'id': this._id,
	'msgType': this.msgType,
	'content': this.content,
	'metadata': this.metadata,
	'date_created': helper.timeStamp(this._id.getTimestamp()),
    };
    var msg = this;
    helper.forEachArgument(arguments, function(user) {
	    if (msg.toUserId.equals(user._id)) {
		d.to_user = !!user?user.toJSON(): null;
	    } else if (msg.fromUserId.equals(user._id)){
		d.from_user = !!user?user.toJSON(): null;
	    } else {
		console.warn('illegal', user._id);
	    }
	});
    return d;    
};

exports.ChatMessage = mongoose.model('ChatMessage', chatMessageSchema);
exports.ChatMessage.stateSent = 0;
exports.ChatMessage.stateSynced = 1;
