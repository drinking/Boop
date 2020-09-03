/**
	{
		"api":1,
		"name":"Join Lines With Separator",
		"description":"Joins all lines without any delimiter.",
		"author":"Drinking",
		"icon":"collapse",
		"tags":"join",
		"argsTint":"seperator like , | / ..."
	}
**/

function main(input) {
	input.text = input.text.replace(/\n/g, input.args);
}
