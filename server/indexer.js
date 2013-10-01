exports.splitName = function (name) {
    var termSets = {};
    //for (var word in name.split()) {
    name.split(/\s+/).forEach(function(word) {
	for (var i=0; i<word.length; i++) {
	    for (var len=1; len<=3;len++) {
		var t = word.substr(i, len);
		if (t) {
		    t = t.toLowerCase();
		    termSets[t] = true;
		}
	    }
	}
	});
    var terms = [];
    for (var t in termSets) {
	terms.push(t);
    }
    return terms;
};
