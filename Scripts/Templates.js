/**
	{
		"api":1,
		"name":"Templates",
		"description":"Generate Template with Mustache",
		"author":"Drinking",
		"icon":"collapse",
		"tags":"template"
	}
**/

const { render } = require('@boop/mustache')

const templates = {
	"0":`
	{{#meta}}
	{{#params}}
    /**
    * {{comment}}
    */
    private {{type}} {{name}};
	{{/params}}
	{{/meta}}
	`,
	"1":`

	{{#meta}}
	/** 
	 * {{comment}}
	{{#params}}
	 * @param {{name}} {{comment}}
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
	@RequestParam(value = "{{name}}", required = false, defaultValue = "") {{type}} {{name}}{{comma}}
	{{/params}});
	{{/meta}}`,
	"2":`
	{{#meta}}
    /** 
     * {{comment}}
    {{#params}}
     * @param {{name}} {{comment}}
    {{/params}}
     * @return
     * @author drinking
     * @since {{time}}
     * @version v1
     * @summary {{comment}}
     */
	{{/meta}}`,
	"3":`
	{{#meta}}
		Map<String, Object> param = MapSugar.paramMap(
			{{#params}}
				"{{name}}", {{name}}{{comma}}
			{{/params}}
			);
	{{/meta}}`,
	"4":`
	
	public int insert({{#meta}}{{#params}} {{type}} {{name}}{{comma}}{{/params}}{{/meta}}) {
		return sqlSessionCommon.insert(st("insert"),
			MapSugar.paramMap({{#meta}}{{#params}} "{{name}}", {{name}}{{comma}} {{/params}}{{/meta}}));
	}
	
	{{#meta}}
	<insert id="insert" parameterType="map">
	INSERT INTO {{{tableName}}} ({{#params}}{{name}}{{comma}}{{/params}})
	VALUES ({{#params}}#{{=<% %>=}}{<%={{ }}=%>{{name}}{{=<% %>=}}}<%={{ }}=%>{{comma}}{{/params}})
	</insert>
	{{/meta}}`,
	"5":`
	
	public int update({{#meta}}{{#params}} {{type}} {{name}}{{comma}}{{/params}}{{/meta}}) {
		return sqlSessionCommon.update(st("update"),
			MapSugar.paramMap({{#meta}}{{#params}} "{{name}}", {{name}}{{comma}} {{/params}}{{/meta}}));
	}
	
	{{#meta}}
	<update id="update" parameterType="map">
	UPDATE {{{tableName}}}
	set
	{{#params}}
		{{name}} = #{{=<% %>=}}{<%={{ }}=%>{{name}}{{=<% %>=}}}<%={{ }}=%>{{comma}}
	{{/params}}
	where id = #{id}
	</update>
	{{/meta}}
	`
}

function main(input) {
	
	// 1,2,3,4:index
	console.log(input.args)
	if (input.args) {
		var args = input.args.split(':');
		var t = templates[args[1]];
		var includes = args[0].split(',');
		
		var output = render(t, { "meta": metaFromSql(input.text,includes)});
		input.text = output;
		return
		
	}
	
	var meta = metaFromSql(input.text);
	var list = meta.params.map ( param =>
		{
			return {
				title: param.type + " " + param.name,
				subTitle: param.comment,
				extra: JSON.stringify(param)
			}
		}
	);
	
	
	console.log(list);
	
	var result = {
		"type":0,
		"list":list,
		"title":"Pick and continue...",
		"nextCommand" :
		{
			"type":1,
			"title":"Choose a template",
			"list":[
				{"title":"Bean","subTitle":"To Java Bean"},
				{"title":"Request","subTitle":"To SPI defines and annotations"},
				{"title":"Annotation","subTitle":"To Java annotations"},
				{"title":"Mapper","subTitle":"To database mapper"},
				{"title":"Insertion","subTitle":"Insertion method and mapper"},
				{"title":"Update","subTitle":"Update method and mapper"}
			]
		}
	};
	
	var str = JSON.stringify(result);
	input.text = str;
	
}

function metaFromSql(content,includes) {

    let tableName = content.substring(content.indexOf("TABLE")+5,content.indexOf("(")).replace(" ","");
    
    var array = content.match(/`.*`.*,/g)
    if (!array) {
        throw "parse failure";
    }
    var params = array.map(x => parseParam(x)).filter((x,index) => x != null);
	
	if (includes) {
		params = params.filter((x,index) => {
			console.log(includes);
			var i = includes.includes(index+'');
			console.log(i);
			return i;
		});
	}
	
    params[params.length-1].comma = ""

    var comment;
    if (content.lastIndexOf("COMMENT") >= 0) {
        comment = content.substring(content.lastIndexOf("COMMENT"), content.length - 1);
        comment = comment.substring(comment.indexOf("'")+1,comment.lastIndexOf("'"));
    }

    return { 
        tableName:tableName,
        params: params,
        comment:comment,
        time:new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '')
    }
}

function parseParam(content) {
    var obj = {comma:","}
    var strArray = content.split(" ")
    if (strArray.length < 2) {
        return null;
    }

    obj.name = strArray[0].replace(/`/g, '')
    let typeStr = strArray[1].toLowerCase();
    if (typeStr.indexOf("int") !== -1) {
        obj.type = "int"
    } else if (typeStr.indexOf("bigint") !== -1) {
        obj.type = "long"
    } else if (typeStr.indexOf("datetime") !== -1) {
        obj.type = "Date"
    } else if (typeStr.indexOf("bit") !== -1 || typeStr.indexOf("boolean") !== -1) {
        obj.type = "boolean"
    } else if (typeStr.indexOf("char") !== -1) {
        obj.type = "String"
    } else if (typeStr.indexOf("float") !== -1) {
        obj.type = "float"
    } else if (typeStr.indexOf("double") !== -1) {
        obj.type = "double"
    }

    if (content.indexOf("COMMENT") >= 0) {
        var comment = content.substring(content.indexOf("COMMENT"), content.length - 1);
        obj.comment = comment.substring(comment.indexOf("'")+1,comment.lastIndexOf("'"));
    }
    return obj
}