<?php

/*
 * When this page appears in the browser a request is made over AJAX
 * to the plugin to actually do the restore.
 *
 * This page shows a loading screen, and when the AJAX request completes 
 * it shows the result of the restore.
 */

$timestamp = $_GET["timestamp"];
$source = $_GET["source"];

?>

<h1>Remember</h1>

<div style="text-align: center;" >
	<p style="font-size: large;">Restoring <span id="timestamp"><?php echo $timestamp; ?></span> from <span id="source"><?php echo $source; ?></span>... <span id="restore-result"></span></p>
	<p id="restore-message"><span class="message"></span> - <a href="<?php echo DOKU_URL;?>/doku.php?do=memories">click here</a> to return to your memories</p>
	<div id="loading-gif-div">
		<img src="<?php echo DOKU_PLUGIN_IMAGES; ?>/loading.gif" alt="restoring..."/>
	</div>
	<pre style="margin: 0px auto; display: none; text-align: left; width: 70%; background: #ddd;" id="error-output"></pre>
</div>

<script type="text/javascript">

	// Start the restore request
	jQuery(document).ready(function () {
		braincase.do_restore_request();
	});

</script>