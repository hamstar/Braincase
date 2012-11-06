<?php

class action_plugin_braincase extends DokuWiki_Action_Plugin {
	
	function register(&$controller) {

		$controller->register_hook("MAIL_MESSAGE_SEND", "BEFORE", $this, "handle_mail_message_send");
	}

	function handle_mail_message_send(&$event) {

		switch ( $event->data['subject'] ){
			case "Your DokuWiki password":
				$event->preventDefault(); // stop the email from sending
				$this->_save_email_data( $event->data );
				break;
		}
	}

	private function _save_email_data( $data ) {

		// Find the log from the email content
		$login = preg_match("@Login\s+:\s+(.*)@", $data["body"], $m)
		  ? $m[1]
		  : "unknown-".mktime();

		// Set the filename and save the email in json format
		$file = "/var/lib/braincase/mailq/$login.txt";
		file_put_contents( $file, json_encode( $data ) );
		
		// Set perms
		chmod($file, 700); // only let the owner see this
		chgrp($file, "root"); // set the group first so we still have permission...
		chown($file, "root"); // ... to set the owner
	}
}