<?php

class action_plugin_braincase extends DokuWiki_Action_Plugin {
	
	function register(&$controller) {

		$controller->register_hook("MAIL_MESSAGE_SEND", "BEFORE", $this, "handle_mail_message_send");
	}

	function handle_mail_message_send(&$event) {

		switch ( $event->data['subject'] ){
			case "Your DokuWiki password":
				$event->preventDefault();
				$this->_save_email_data( $event->data );
				break;
		}
	}

	private function _save_email_data( $data ) {

		preg_match("@Login\s+:\s+(.*)@", $data["body"], $m);
		$login = $m[1];
		$file = DOKU_DATA . "pages/braincase/mailq/$login.txt";
		file_put_contents( $file, json_encode( $data ) );
	}

}