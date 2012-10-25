<?php
/**
 * DokuWiki Plugin autobackup (Action Component)
 *
 * @license GPL 2 http://www.gnu.org/licenses/gpl-2.0.html
 * @author  Robert McLeod <hamstar@telescum.co.nz>
 */

// must be run within Dokuwiki
if (!defined('DOKU_INC')) die();

if (!defined('DOKU_LF')) define('DOKU_LF', "\n");
if (!defined('DOKU_TAB')) define('DOKU_TAB', "\t");
if (!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');

// Custom constants
if (!defined('DOKU_DATA')) define('DOKU_DATA', "/var/lib/dokuwiki/data/");
if (!defined('AUTOBACKUP_PLUGIN')) define('AUTOBACKUP_PLUGIN', DOKU_PLUGIN.'braincase/');
if (!defined('PLUGIN_BASE')) define('PLUGIN_BASE', DOKU_PLUGIN.'braincase/');
if (!defined('DOKU_PLUGIN_IMAGES')) define('DOKU_PLUGIN_IMAGES',PLUGIN_BASE.'images/');

require_once DOKU_PLUGIN.'action.php';

class action_plugin_braincase_dropbox extends DokuWiki_Action_Plugin {

    private $user;

	public function __construct() {

		global $INFO;

		if ( isset( $INFO['client'] ) && is_string( $INFO['client']) )
      		$this->user = $INFO['client'];

		require_once PLUGIN_BASE.'lib/Dropbox.php';
	}

    /**
     * Register hooks from dokuwiki
     */
    public function register(Doku_Event_Handler &$controller) {

       $controller->register_hook('AJAX_CALL_UNKNOWN', 'BEFORE', $this, 'handle_ajax_call_unknown');   
    }

	public function handle_ajax_call_unknown(Doku_Event &$event, $param) {

      $event->preventDefault();

      $json = new StdClass;

      switch ( $event->data ) {
        case "dropbox.enable":
          $json->message = Dropbox::enable_for( $this->user );
          break;
        case "dropbox.disable":
          $json->message = Dropbox::disable_for( $this->user );
          break;
        default:
          return;//$json->message = "Unsupported request";
          break;
      }

      echo json_encode($json);
    }

}