/**
	{
		"api":1,
		"name":"Join By Comma",
		"description":"Joins all lines with comma.",
		"author":"Drinking",
		"icon":"collapse",
		"tags":"join"
	}
**/

function main(input) {
	input.text = input.text.replace('\n', ',');
}
