var crypto = require('crypto');
var model = require('../modeldef.js');
var helper = require('../helper');

var args = process.argv.slice(2);

if(args.length < 2) {
    console.info('Usage ', process.argv[0], process.argv[1], '<userId> <password>');
    process.exit(1);
}

var userId = args[0];
if (!/^[a-zA-Z\d\_]+$/.test(userId)) {
    console.error('userId can only contain the following chars: [a-zA-Z0-9\_]');
    process.exit(2);
}

function createUser() {
     var u = model.AuthUser({
	    userId: userId,
	});
     u.setPassword(args[1]);
     u.save(function (err) {
	     helper.assertNoError(err);
	     console.log('User created', u._id);
	     process.exit(0);
	 });
}

helper.connectMongodb();
model.AuthUser.findOne({userId: userId},
		       function (err, user) {
			   helper.assertNoError(err);
			   if (user) {
			       console.error('User', userId, 'already exist!');
			       process.exit(3);
			   }
			   createUser();
		       });

