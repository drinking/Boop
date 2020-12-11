/**
	{
		"api":1,
		"name":"Filter",
		"description":"Filter lines with filter condition",
		"author":"Drinking",
		"icon":"collapse",
		"tags":"filter"
	}
**/

"use strict";

function main(input) {
	input.text = input.text.split("\n").filter(word => word.includes("private"))
	.map(word => word.trim().split(" ")[2].slice(0, -1)).
	join("\n");
}


