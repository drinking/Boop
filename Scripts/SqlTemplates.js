/**
	{
		"api":1,
		"name":"SQLTemplates",
		"description":"Generate Template with Mustache",
		"author":"Drinking",
		"icon":"collapse",
		"tags":"sql template"
	}
**/

"use strict";
const P = require('@boop/parsimmon')
const { render } = require('@boop/mustache')

const templates = [
{ title: "Bean", subTitle: "To Java Bean",template: `
{{#meta}}
{{#params}}
   /**
   * {{comment}}
   */
   private {{type}} {{#as}}{{as}}{{/as}}{{^as}}{{name}}{{/as}};   
{{/params}}
{{/meta}}`
},

{ title: "Request", subTitle: "To SPI defines and annotations", template: `
{{#meta}}
/** 
 * {{comment}}
{{#params}}
 * @param {{#as}}{{as}}{{/as}}{{^as}}{{name}}{{/as}} {{comment}}
{{/params}}
 * @return
 * @author drinking
 * @since {{time}}
 * @version v1
 * @summary {{comment}}
 */
{{/meta}}
{{#meta}}
@RequestMapping(value = "", method = RequestMethod.GET)
void name (@RequestHeader(XHeaders.LOGIN_USER_ID) long loginUserId,
{{#params}}
	@RequestParam(value = "{{#as}}{{as}}{{/as}}{{^as}}{{name}}{{/as}}", required = false, defaultValue = "{{defaults}}") {{type}} {{#as}}{{as}}{{/as}}{{^as}}{{name}}{{/as}}{{comma}}
{{/params}});
{{/meta}}`
},

{ title: "Annotation", subTitle: "To Java annotations", template :`
{{#meta}}
   /** 
    * {{comment}}
   {{#params}}
    * @param {{#as}}{{as}}{{/as}}{{^as}}{{name}}{{/as}} {{comment}}
   {{/params}}
    * @return
    * @author drinking
    * @since {{time}}
    * @version v1
    * @summary {{comment}}
    */
{{/meta}}`
},

{ title: "Mapper", subTitle: "To database mapper", template : `
{{#meta}}
Map<String, Object> param = MapSugar.paramMap(
	{{#params}}
	"{{name}}", {{#as}}{{as}}{{/as}}{{^as}}{{name}}{{/as}}{{comma}}
	{{/params}}
);
{{/meta}}`
},

{ title: "Insertion", subTitle: "Insertion method and mapper", template: `	
public int insert({{#meta}}{{#params}} {{type}} {{name}}{{comma}}{{/params}}{{/meta}}) {
	return sqlSessionCommon.insert(st("insert"),
			MapSugar.paramMap({{#meta}}{{#params}} "{{#as}}{{as}}{{/as}}{{^as}}{{name}}{{/as}}", {{#as}}{{as}}{{/as}}{{^as}}{{name}}{{/as}}{{comma}} {{/params}}{{/meta}}));
}
	
{{#meta}}
<insert id="insert" parameterType="map">
	INSERT INTO {{{tableName}}} ({{#params}}{{name}}{{comma}}{{/params}})
	VALUES ({{#params}}#{{=<% %>=}}{<%={{ }}=%>{{#as}}{{as}}{{/as}}{{^as}}{{name}}{{/as}}{{=<% %>=}}}<%={{ }}=%>{{comma}}{{/params}})
</insert>
{{/meta}}`
},

{ title: "Update", subTitle: "Update method and mapper", template: `
public int update({{#meta}}{{#params}} {{type}} {{name}}{{comma}}{{/params}}{{/meta}}) {
	return sqlSessionCommon.update(st("update"),
			MapSugar.paramMap({{#meta}}{{#params}} "{{name}}", {{name}}{{comma}} {{/params}}{{/meta}}));
}
	
{{#meta}}
<update id="update" parameterType="map">
	UPDATE {{{tableName}}}
	set
{{#params}}
	{{name}} = #{{=<% %>=}}{<%={{ }}=%>{{#as}}{{as}}{{/as}}{{^as}}{{name}}{{/as}}{{=<% %>=}}}<%={{ }}=%>{{comma}}
{{/params}}
	where id = #{id}
</update>
{{/meta}}
`
},

{ title: "SEL&DEL", subTitle: "Select and delete SQL", template: `
{{#meta}}
select {{#params}}{{name}} {{#as}} as {{as}} {{/as}}{{comma}}{{/params}} from {{tableName}}
{{#params}}
	{{name}} = #{ {{name}} }  {{#comma}} and {{/comma}}
{{/params}}
{{/meta}}	

public void delete({{#meta}}{{#params}} {{type}} {{name}}{{comma}}{{/params}}{{/meta}}) {
	sqlSessionCommon.delete(st("delete"),
			MapSugar.paramMap({{#meta}}{{#params}} "{{name}}", {{name}}{{comma}} {{/params}}{{/meta}}));
}

<delete id="delete" parameterType="map">
{{#meta}}
delete from {{tableName}}
where
{{#params}}
	{{name}} = #{ {{name}} } {{#comma}} and {{/comma}}
{{/params}}
{{/meta}}
</delete>

`
},

{ title: "CURL", subTitle: "CURL Request format", template: `
{{#meta}}
curl '{{=<% %>=}}{{host}}<%={{ }}=%>/path/?{{#params}}{{#as}}{{as}}{{/as}}{{^as}}{{name}}{{/as}}={{defaults}}&{{/params}}'
	-H 'Connection: keep-alive' \
	-H 'Accept: application/json, text/plain, */*' \
	-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36' \
	-H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8' \
	--compressed \
	--insecure
{{/meta}}	
`}
]

///////////////////////////////////////////////////////////////////////

// Use the JSON standard's definition of whitespace rather than Parsimmon's.
let whitespace = P.regexp(/\s*/m);

// JSON is pretty relaxed about whitespace, so let's make it easy to ignore
// after most text.
function token(parser) {
	return parser.skip(whitespace);
}

// Several parsers are just strings with optional whitespace.
function word(str) {
	return ignoreCaseString(str).thru(token);
}

function ignoreCaseString(str) {
	return P.custom(function (success, failure) {
		return function (input, i) {
			var j = i + str.length;
			var head = input.slice(i, j);
			if (head === str | head.toLowerCase() == str) {
				return success(j, head);
			} else {
				return failure(i, str);
			}
		};
	});
}

function fieldType(type) {
	return P.seqMap(
		ignoreCaseString(type),
		P.alt(token(ignoreCaseString("(").then(P.digits).skip(ignoreCaseString(")"))), P.optWhitespace),
		P.alt(token(ignoreCaseString("(").then(P.digits).skip(word(",")).then(P.digit).skip(ignoreCaseString(")"))), P.optWhitespace),
		function (t, l, l2) {
			return t;
		})
}

function allTypes() {
	return P.alt(
		// numeric
		fieldType("tinyint"),
		fieldType("smallint"),
		fieldType("mediumint"),
		fieldType("integer"),
		fieldType("int"),
		fieldType("bigint"),
		fieldType("float"),
		fieldType("double"),
		fieldType("decimal"),
		// char
		fieldType("varchar"),
		fieldType("char"),
		fieldType("tinytext"),
		fieldType("text"),
		fieldType("mediumtext"),
		fieldType("longtext"),
		//time
		fieldType("datetime"),
		fieldType("date"),
		fieldType("time"),
		fieldType("timestamp"),
		//blob
		fieldType("tinyblob"),
		fieldType("blob"),
		fieldType("mediumblob"),
		fieldType("longblob"),
		//binary
		fieldType("binary"),
		fieldType("varbinary"),
		//boolean
		fieldType("boolean"),
		fieldType("bit")
	);
}

function toJavaType(sqlType) {
	let type = sqlType.toLowerCase();
	if (type == "tinyint" ||
		type == "smallint" ||
		type == "mediumint" ||
		type == "integer" ||
		type == "int") {
		return "int";
	} else if (type == "bigint") {
		return "long";
	} else if (type == "float") {
		return "float";
	} else if (type == "double") {
		return "double"
	} else if (type == "decimal") {
		return "BigDecimal"
	} else if (type == "varchar" ||
		type == "char" ||
		type == "tinytext" ||
		type == "text" ||
		type == "mediumtext" ||
		type == "longtext") {
		return "String";
	} else if (type == "timestamp") {
		return "Timestamp";
	} else if (type == "date" || 
		type == "datetime" ) {
		return "Date";
	} else if (type == "time") {
		return "Time";
	} else if (type == "tinyblob" ||
		type == "blob" ||
		type == "mediumblob" ||
		type == "longblob" ||
		type == "binary" ||
		type == "varbinary") {
		return "byte []"
	} else if (type == "bit" ||
		type == "boolean") {
		return "boolean";
	} else {
		return "Object";
	}
}

function allAttributes() {
	return P.alt(word("not null"),
		word("null"),
		word("auto_increment"),
		word("primary key"),
		word("unique"),
		word("binary"),
		word("unsigned"));
}

function optional(name) {
	return P.alt(token(word(name)), P.optWhitespace);
}

function argumentValue(name) {
	return P.alt(
		P.seqMap(word(name), token(word("null")), function (a, b) {
			return b;
		}),
		P.seqMap(word(name), token(P.digit), function (a, b) {
			return b;
		}),
		word(name).skip(ignoreCaseString("'")).then(P.takeWhile(function (x) { return x !== "'"; })).skip(ignoreCaseString("'")).skip(whitespace),
		P.seqMap(word(name), optional("current_timestamp"), optional("on"), optional("update"), optional("current_timestamp"),
			function (a, b, c, d, e) {
				if (e) {
					return [b, c, d, e].join(" ");
				} else {
					return b;
				}
			}),
		P.optWhitespace);
}

function tableComment() {
	return P.custom(function (success, failure) {
		return function (input, i) {
			const newStr = input.slice().toLowerCase();
			var index = newStr.lastIndexOf("comment");
			var lastBracket = input.lastIndexOf(")");
			if (index > 0 && index > lastBracket) {
				var substr = input.substr(index);
				var r = P.takeWhile(function (x) {
					return x !== "'";
				}).then(token(P.regexp(/'((?:\\.|.)*?)'/))).skip(P.all).tryParse(substr);
				r = r.slice(1, -1);
				return success(input.length, r);
			}
			return success(input.length, "");
		};
	});
}

let SQLParser = P.createLanguage({
	value: r =>
		P.seqMap(r.create, r.name, word("("), r.fields, tableComment(),
			function (create, tableName, ignore1, fields, comment) {
				let time = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
				return {
					tableName: tableName,
					params: fields,
					comment: comment,
					time: time
				}
			}).desc("sql"),
	create: () => token(word("create").skip(word("table"))).thru(
		parser => whitespace.then(parser)
		).desc("create"),
	comma: () => word(","),
	name: () =>
		token(P.regexp(/[a-z|A-Z|_]+/)
			.wrap(P.alt(ignoreCaseString("`"), P.optWhitespace), P.alt(ignoreCaseString("`"), P.optWhitespace)))
			.desc("name"),
	fields: r =>
		P.seqMap(r.name, r.type, P.alt(r.attributes.trim(P.optWhitespace).many(), P.optWhitespace),
			argumentValue("default"),
			argumentValue("comment"),
			function (name, type, others, defaults, comment) {
				type = toJavaType(type);
				let comma = ","
				let as = ""
				if(name.includes("_")) {
					as = name.split("_").map(x => {
						return x.charAt(0).toUpperCase() + x.slice(1);
					}).join("");
					as = as.charAt(0).toLowerCase() + as.slice(1);
				}

				return { name, type, defaults, comment,comma, as}
			}).sepBy(r.comma)
			.desc("fields"),
	type: () => allTypes(),
	attributes: () => allAttributes(),
});

function main(input) {

	// args format [picked rows seperate by ,]:[selected action index]
	// e.g. 1,2,3,4:1 
	console.log(input.args)
	if (input.args) {
		var args = input.args.split(':');

		var picked = args[0].split(',');
		var meta = SQLParser.value.tryParse(input.text);
		meta.params = meta.params.filter((x, index) => {
			var i = picked.includes(index + '');
			return i;
		});
		meta.params[meta.params.length - 1].comma = "";

		var output = render(templates[args[1]].template, { meta });
		input.text = output;
		return

	}

	var meta = SQLParser.value.tryParse(input.text);
	var list = meta.params.map(param => {
		return {
			title: param.type + " " + param.name,
			subTitle: param.comment,
			extra: JSON.stringify(param)
		}
	});


	var result = {
		type: 0,
		list: list,
		title: "Then",
		nextCommand:
		{
			type: 1,
			title: "Templates",
			list: templates
		}
	};

	var str = JSON.stringify(result);
	input.text = str;

}

