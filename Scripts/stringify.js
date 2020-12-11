/**
	{
		"api":1,
		"name":"Stringify",
		"description":"Stringify a JSON",
		"author":"Drinking",
		"icon":"collapse",
		"tags":"stringify"
	}
**/

"use strict";

function main(input) {
	input.text = JSON.stringify(input.text);
}


