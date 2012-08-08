(function ($) {
	var leftPanel, rightPanel;

	function create(nn, c) {
		var e = $(document.createElement(nn));
		if (c) e.addClass(c);
		
		var i;
		for (i = 2; i < arguments.length; i++) {
			if (arguments[i]) {
				e.append(arguments[i]);
			}
		}
		return e;
	}
	
	function fillRightPanel(ch) {
		var uni = unihan[ch];
		if (uni) {
			rightPanel.empty();
			
			var infobox = create("DIV", "character-infobox");
			
			var histogram = getActiveHistogram(ch);
			
			if (histogram.count == 0) {
				infobox.append("Never appears in selected primers.<br>");
			} else if (histogram.count == 1) {
				infobox.append("Appears once, in ");
				
				var i;
				for (i = 0; i < digest.documents.length; i++) {
					var doc = digest.documents[i];
					if (doc.isIncluded && doc.histogram[ch]) {
						infobox.append(doc.filename + "<br>");
					}
				}				
			} else {
				infobox.append("Appears " + getActiveHistogram(ch).count + " times in selected primers.<br>");
				
				var i;
				for (i = 0; i < digest.documents.length; i++) {
					var doc = digest.documents[i];
					if (doc.isIncluded && doc.histogram[ch]) {
						infobox.append(doc.histogram[ch] + " in " + doc.filename + "<br>");
					}
				}
			}
			
			rightPanel.append (create("DIV", "dictionary-box",
				create("DIV", "character-box", ch),
				create("DIV", "definition-box", create("SPAN", "pinyin", uni.kMandarin), 
				(uni.kTang ? create("SPAN", "tang", uni.kTang) : null),
				create("BR"),
				uni.kDefinition)
			),
				infobox
			);
		}
	}
	
	function enterChar(e) {
		$(e.target).addClass("reference");
		fillRightPanel($(e.target).text());
	}
	
	function exitChar(e) {
		$(e.target).removeClass("reference");
	}
	
	
	var currentHistogram = { };
	
	function resetHistograms() {
		currentHistogram = { }
		
		var i;
		for (i = 0; i < digest.documents.length; i++) {
			var doc = digest.documents[i];
			
			if (!doc.isPrimer && doc.rerender) {
				doc.rerender();
			}
		}
	}
	
	function getActiveHistogram(ch) {
		var histogram = currentHistogram[ch];

		if (!histogram) {
			histogram = {
				count: 0,
				sources: 0
			};
			
			currentHistogram[ch] = histogram;
			
			var localCount = 0;
			var i;
			for (i = 0; i < digest.documents.length; i++) {
				var doc = digest.documents[i];
				
				if (doc.isPrimer && doc.isIncluded && doc.histogram) {
					localCount = doc.histogram[ch];
					if (localCount) {
						histogram.count += localCount;
						histogram.sources++;
					}
				}
			}
		}
			
		return histogram;
	}
	
	function getCssClass(ch) {
		var histogram = getActiveHistogram(ch);
		if (histogram.sources == 0) {
			return "glyph-unknown";
		} else if (histogram.count < 3) {
			return "glyph-rare";
		}
	}
	
	function createInfoDiv(doc) {
		var togglebutton = create("DIV", "button-text", "show");
		var includebutton;
		
		togglebutton.click(toggleVisibility);
		
		if (doc.isPrimer) {
			includebutton = create("DIV", "button-text", "include")
			includebutton.click(toggleInclusion);
		}
		
		doc.setExpanded = setExpanded;
		doc.setIncluded = setIncluded;
		doc.rerender = rerender;
	
		doc.infodiv = create("DIV", "source-info", togglebutton, includebutton, doc.filename);
		
		if (doc.isPrimer) {
			doc.infodiv.addClass(doc.isIncluded ? "primer-included" : "primer-excluded");
		}
		
		return doc.infodiv;
		
		function populateSourceText() {
			var div = create("DIV", "source-text");
			
			doc.textdiv = div;
			
			for (j = 0; j < doc.text.length; j++) {
				var ch = doc.text.substr(j, 1);
				
				if (unihan[ch]) {
					var span = create("SPAN", getCssClass(ch));
					span.text(ch);
					span.hover(enterChar, exitChar);
					div.append(span);
					div.append(create("WBR")); // allow a word break anywhere for now
				}
			}
			
			doc.div.append(doc.textdiv);
		}
		
		function rerender() {
			if (doc.isExpanded) {
				doc.textdiv.remove();
				doc.textdiv = null;
				
				populateSourceText();
			}
		}
		
		function setExpanded(v) {
			if (!!v === !!doc.isExpanded) return;
			
			if (v) {
				if (!doc.textdiv) {
					populateSourceText();
				} else {
					doc.textdiv.show();
				}
				togglebutton.text("hide");
			} else {
				doc.textdiv.hide();
				togglebutton.text("show");
			}
			
			doc.isExpanded = !!v;
		}
		
		function setIncluded(v) {
			if (!doc.isPrimer) return;
			if (!!v === !!doc.isIncluded) return;
			
			if (v) {
				includebutton.text("exclude");
				doc.infodiv.addClass("primer-included").removeClass("primer-excluded");
			} else {
				includebutton.text("include");
				doc.infodiv.addClass("primer-excluded").removeClass("primer-included");
			}
						
			doc.isIncluded = !!v;
			resetHistograms();
		}
		
		function toggleVisibility(e) {
			setExpanded(!doc.isExpanded);
		}
		
		function toggleInclusion(e) {
			setIncluded(!doc.isIncluded);
		}
	}

	$().ready(function() {
		// $(".text").addClass("unknown");
		// console.log($(".text").text());
		
		var centercolumn = create("DIV");
		centercolumn.addClass("center-column");
		
		leftPanel = create("DIV", "left-panel");
		rightPanel = create("DIV", "right-panel");
		
		centercolumn.append(leftPanel);
		centercolumn.append(rightPanel);
		
		//console.dir(digest.documents);
		//console.dir(unihan);
		
		var i;
		for (i = 0; i < digest.documents.length; i++) {
			var doc = digest.documents[i];
			
			doc.div = create("DIV", "source", createInfoDiv(doc));
			
			if (doc.isPrimer) {
				doc.setIncluded(true);
			} else {
				doc.setExpanded(true);
			}
			
			leftPanel.append(doc.div);
			
			// console.log("Visiting: " + i);
		}
		
		$("body").append(centercolumn);
	});
})(jQuery)
