$(function() {
	$("#request").click(function() {
		doSearch(1);
	});
});
function doSearch(page) {
	$("#result").empty();
	$("#result").append("<tr><td colspan='5'><div align='center'><img src='img/loading.gif' /></div></td></tr>");
		var data = {
				query:{
					simple_query_string:{
						fields: ["file_name"],
						query: "src",
						default_operator: "and"
					}
				},
				from: (page - 1) * 10,
				size: 10
				
		};

	data.query.simple_query_string.query = $("#message").val();
	var requestJson = JSON.stringify(data);

	console.log(requestJson);
	$.ajax({
		type: "POST",
		url: elasticsearchUrl,
		data: requestJson,
		success: function(data) {
			var result = "";
			for (var i = 0; i < data.hits.hits.length; i++) {
				var src = data.hits.hits[i]._source;
				result = result + "<tr>";
				result = result + "<td>" + src.dir_name + "</td>";
				result = result + "<td>";
				if (src.file_type == "0") { // 0:dir 1:file
						result = result + "<i class='folder icon'></i>";
				} else {
						result = result + "<i class='file outline icon'></i>";
				}
				result = result + src.file_name + "</td>";
				result = result + "<td>" + src.file_ext + "</td>";
				result = result + "<td>" + src.last_modified + "</td>";
				result = result + "<td>" + src.file_size + "</td>";
				result = result + "</tr>";
			}
			$("#result").empty();
			$("#result").append(result);
			$(".pagination").pagination({
				items: (data.hits.total / 10),
				displayedPages: 4,
				tagName: 'a',
				currentPage: page,
				cssStyle: 'light-theme',
				onPageClick: function(currentPageNumber) {
					doSearch(currentPageNumber);
				}
			});
		},
		error: function(XMLHttpRequest, textStatus, errorThrown) {
			alert("An error occurred on request: " + textStatus + ":\n" + errorThrown);
		}
	});
}
