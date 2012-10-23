<?php

/**
 * A static class that will add users to dropbox queues
 * for a cron job to read and act upon
 */
class Dropbox {
	
	public static function enable_for( $user ) {

		global $conf;

		$saved = self::_add_to_queue( 
			$user,
			$conf["autobackup"]["dropbox_enable_queue"]
		);

		return ($saved) 
		  ? "Dropbox is queued to be enabled on your account.  You will receive an email soon with further instructions."
		  : "Something went wrong, please contact your deployment manager";
	}

	public static function disable_for( $user ) {
		
		global $conf;

		$saved = self::_add_to_queue( 
			$user,
			$conf["autobackup"]["dropbox_disable_queue"]
		);

		return ($saved)
		  ? "Dropbox is queued to be disabled for your account."
		  : "Something went wrong, please contact your deployment manager";
	}

	public static function status_for( $user ) {

		global $conf;

		$enabled_users = self::_build_filename( $conf["autobackup"]["dropbox_enabled_users"] );
		$enable_queue = self::_build_filename( $conf["autobackup"]["dropbox_enable_queue"] );

		if ( `grep '$user' $enabled_users | wc -l` > 0 ) # user is enabled
        	return "enabled";

		if ( `grep '$user' $enable_queue | wc -l` > 0 ) # user queued
			return "queued";

		return "disabled";
	}

	public static function generate_button( $user ) {

		$status = self::status_for( $user );

		$status_button = '<input type="submit" value="{{value}}" class="button" id="{{id}}"{{disabled}}/>';
		$value = "???";
		$disabled = "";
		$id = "_dropbox";

		switch ( $status ) {
		case "disabled":
			$value = "Enable Dropbox" ;
			$id = "Enable$id";
			break;
		case "enabled":
			$value = "Disable Dropbox";  
			$id = "Disable$id";
			break;
		case "queued":
			$value = "Queued";
			$disabled = " disabled";
			break;
		default:
			break;
		}

		return str_replace( array(
			"{{value}}",
			"{{id}}",
			"{{disabled}}"
		), array(
			$value,
			$id,
			$disabled
		), $status_button);
	}

	private static function _add_to_queue( $user, $q ) {
		
		$fn = self::_build_filename( $q );

		if ( !file_exists( $fn ) )
			return false;

		return ( file_put_contents( $fn, "$user\n", FILE_APPEND ) !== FALSE )
		  ? true
		  : false;
	}

	private static function _build_filename( $page_id ) {

		return DOKU_INC."data/pages/".str_replace( ":", "/", $page_id );
	}
}