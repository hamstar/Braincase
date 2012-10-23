var braincase = {

	init: function () {

		this.hide_title();
		this.activate_remember_button();
		this.activate_disable_dropbox_button();
		this.activate_enable_dropbox_button();
	},

	hide_title: function () {
		jQuery("div.page h1.title").remove();
	},

	add_memories_button: function () {
		var li = jQuery("<li/>").append( 
			jQuery("<a/>")
				.addClass("action")
				.attr("href", "/doku.php?id=test:memories&do=memories")
				.text("Memories")
		);

		jQuery("div#dokuwiki__usertools ul").prepend(li);
	},

	activate_remember_button: function () {
		jQuery(".apply-backup").click(function () {
			tr = jQuery(this).parents('tr');
			timestamp = tr.find('td:first').text();
			source = tr.find('td:nth-child(2)').text();
			location.href = "/doku.php?do=restore&source="+source+"&timestamp="+timestamp;
		});
	},

	activate_disable_dropbox_button: function () {
		jQuery("#Disable_dropbox").click(function () {
			jQuery.post(
				DOKU_BASE + "lib/exe/ajax.php",
				{ call: 'dropbox.disable' },
				function (j) {
					alert(j.message);
					location.reload();
				},
				'json'
			);
		});
	},

	activate_enable_dropbox_button: function () {
		jQuery("#Enable_dropbox").click(function () {
			jQuery.post(
				DOKU_BASE + "lib/exe/ajax.php",
				{ call: 'dropbox.enable' },
				function (j) {
					alert(j.message);
					location.reload();
				},
				'json'
			);
		});
	},

	init_restore: function () {

		timestamp = jQuery("#timestamp").text();
		source = jQuery("#source").text();

		jQuery.post(
			DOKU_BASE + "lib/exe/ajax.php",
			{ 
				call: 'restore.memory', 
				source: source, 
				timestamp: timestamp
			},
			function (j) {

				jQuery("#loading-gif-div").hide();

				if ( j.error != 0 ) {
					jQuery("#restore-result").text("failed!");
					jQuery("#error-output").show().text(j.error_output);
				} else {
					jQuery("#restore-result").text("complete!");
					jQuery("#restore-message span.message").text(j.message);
					jQuery("#restore-message").show();
				}
			},
			'json'
		);
	}
};

jQuery(document).ready(function () {

	// Modify the page
	if ( location.href.match(/do=memories/) != null ) {
		braincase.init();
	}

	braincase.add_memories_button();
});