var helper = require('./helper');
var model = require('./modeldef');
var controller = require('./controller');

exports.serve = function(app) {
    app.post('/auth/login', function (req, res) {
	    var userId = req.body.user_id;
	    var password = req.body.password;

	    model.AuthUser.findOne({userId: userId},
				   function (err, user) {
				       helper.assertNoError(err);
				       if (user && user.checkPassword(password)) {
					   var defer = controller.registerUser(userId, userId);
					   defer.then(function (resObj){
						   resObj.url = 'http://' + req.headers.host;
						   res.send(resObj);
					       });
				       } else {
					   res.status(401).send({'message': 'User auth error!'});
				       }
				   });
	});
};

