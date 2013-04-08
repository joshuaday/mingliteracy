(function ($) {
	var leftPanel, rightPanel, fillRightPanel;

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

	function printMode() {
		var column = leftPanel;
		// print-mode
		var nw = window.open(null, "pmode", "location=no", null);
		nw.document.write("<html><head><title>Print</title></head><body>" + column.html() + "</body></html>");
		nw.focus();
	}
	
	function statCompute() {
		var div = create(div);

		var stats = { }
		for (i = 0; i < digest.documents.length; i++) {
			var A = digest.documents[i];
			var cross = { }
			stats[A.tags.title] = cross;
			for (j = 0; j < digest.documents.length; j++) {
				var B = digest.documents[j];
				var cell = {
					unique_chars: 0,
					known_chars: 0
				}
				cross[B.tags.title] = cell;
				for (k in A.histogram) {
					cell.unique_chars++;
					if (B.histogram[k]) {
						cell.known_chars++;
					} else {
					}
				}
			}
		}
		console.dir(stats);

		return div;
	}
	
	var previousTarget;
	function setTarget(target) {
		if (previousTarget != target) {
			if (previousTarget) {
				$(previousTarget).removeClass("reference");
			}
			if (target && $(target).hasClass("zh")) {
				$(target).addClass("reference");
				fillRightPanel($(target).text());
			}

			previousTarget = target;
		}
	}

	function enterChar(e) {
		setTarget(e.target);
	}
	
	function exitChar(e) {
		setTarget(null);
	}
	
	
	var currentHistogram = { };
	
	function resetHistograms() {
		currentHistogram = { }
		
		var i;
		for (i = 0; i < digest.documents.length; i++) {
			var doc = digest.documents[i];
			
			if (doc.rerender) {
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
		// this function used to do more, but the wider variety of styling proved to be overwhelming in practice
		var histogram = getActiveHistogram(ch);
		if (histogram.sources == 0) {
			return "glyph-unknown";
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
	
		doc.infodiv = create("DIV", "source-info",
			togglebutton, includebutton,
			(doc.tags.title || doc.filename),
			create("SPAN", null, "&#12288;&#12288;&#12288;"),
			(doc.tags.author || "")
		);
		
		if (doc.isPrimer) {
			doc.infodiv.addClass(doc.isIncluded ? "primer-included" : "primer-excluded");
		}
		
		return doc.infodiv;
		
		function populateSourceText() {
			doc.textdiv = create("DIV", "source-text");
			
			var segment = [ ];
			var text = doc.tags.body || "";
			for (j = 0; j < text.length; j++) {
				var ch = text.substr(j, 1);
				
				segment.push("<span class='zh ", getCssClass(ch), "'>", ch, "</span><wbr>");
			}
			
			
			doc.textdiv.html(segment.join(""));
			
			doc.textdiv.mousemove(enterChar);
			doc.textdiv.hover(enterChar, exitChar);

			doc.div.append(doc.textdiv);
		}
		
		function rerender() {
			if (doc.textdiv) {
				doc.textdiv.remove();
				doc.textdiv = null;
			}
			if (doc.isExpanded) {
				populateSourceText();
			}
		}
		
		function setExpanded(v) {
			if (!!v === !!doc.isExpanded) return;
			doc.isExpanded = !!v;
			
			if (doc.isExpanded) {
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
		}
		
		function setIncluded(v) {
			if (!doc.isPrimer) return;

			if (!!v === !!doc.isIncluded) return;
			doc.isIncluded = !!v;
			
			if (doc.isIncluded) {
				includebutton.text("exclude");
				doc.infodiv.addClass("primer-included").removeClass("primer-excluded");
			} else {
				includebutton.text("include");
				doc.infodiv.addClass("primer-excluded").removeClass("primer-included");
			}
						
			resetHistograms();
		}
		
		function toggleVisibility(e) {
			setExpanded(!doc.isExpanded);
		}
		
		function toggleInclusion(e) {
			setIncluded(!doc.isIncluded);
		}
	}

	function infoMode() {
		// this is the initial mode, in which 
		fillRightPanel = function(ch) {
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
							infobox.append((doc.tags.title || doc.filename) + "<br>");
						}
					}				
				} else {
					infobox.append(
						"Appears "
						+ (histogram.count == 2 ? "twice " : (histogram.count + " times "))
						+ "in selected primers.<br>");
					
					var i;
					for (i = 0; i < digest.documents.length; i++) {
						var doc = digest.documents[i];
						if (doc.isIncluded && doc.histogram[ch]) {
							infobox.append(doc.histogram[ch] + " in " + (doc.tags.title || doc.filename) + "<br>");
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
			} else {
				rightPanel.empty();
			}
		}
		fillRightPanel();
	}
	function statsMode() {
		fillRightPanel = function(ch) {
			rightPanel.empty();
		}

		fillRightPanel();
	}

	function rightHandToolBar() {
		var div = create("DIV", "toolbar");
		
		div.append(
			create("DIV", "button-text", "info").click(infoMode),
			create("DIV", "button-text", "stats").click(statsMode),
			create("DIV", "button-text", "print").click(printMode)
		);

		return div;
	}

	$().ready(function() {
		// $(".text").addClass("unknown");
		// console.log($(".text").text());
		
		var centercolumn = create("DIV");
		centercolumn.addClass("center-column");
		
		leftPanel = create("DIV", "left-panel");
		var rightColumn = create("DIV", "right-panel");
		
		centercolumn.append(leftPanel);
		centercolumn.append(rightColumn);

		rightPanel = create("DIV", "right-main");
		rightColumn.append(rightHandToolBar(), rightPanel);
		
		//console.dir(digest.documents);
		//console.dir(unihan);

		var labelsSeen = { }
		function addLabel(text) {
			if (!labelsSeen[text]) {
				leftPanel.append($("<div class='section-header'>" + text + "</div>"));
				labelsSeen[text] = true;
			}
		}
		
		var i;
		for (i = 0; i < digest.documents.length; i++) {
			var doc = digest.documents[i];
			
			doc.div = create("DIV", "source", createInfoDiv(doc));
			
			if (doc.isPrimer) {
				addLabel("Primers");
				doc.setIncluded(true);
			} else {
				addLabel("Steles");
				doc.setExpanded(true);
			}
			
			leftPanel.append(doc.div);
			
			// console.log("Visiting: " + i);
		}

		leftPanel.append(statCompute());
		infoMode();
		
		$("body").append(centercolumn);
	});
})(jQuery)
