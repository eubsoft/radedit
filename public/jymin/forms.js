/**
 * Get the value of a form element.
 */
var valueOf = function (input) {
	// TODO: Make this work for select boxes and other stuff too.
	var value = input.value;
	var type = input.type;
	if (type == 'checkbox') {
		return input.checked ? value : null;
	}
	return input.value;
};
