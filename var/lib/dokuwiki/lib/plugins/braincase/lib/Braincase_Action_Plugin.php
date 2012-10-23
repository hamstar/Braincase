<?php

class Braincase_Action_Plugin extends DokuWiki_Action_Plugin {
	
	function __construct() {
		parent::__construct();
	}

	protected function _set_user() {

      if ( !is_array( $_SESSION ) ) {
        $this->user = "unknown";
        return false;
      }

      $session = reset($_SESSION);
      $this->user = $session["auth"]["user"];
    }
}