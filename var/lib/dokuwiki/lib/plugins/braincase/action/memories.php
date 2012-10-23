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
if (!defined('PLUGIN_BASE')) define('PLUGIN_BASE', DOKU_PLUGIN.'braincase/');
if (!defined('AUTOBACKUP_PLUGIN')) define('AUTOBACKUP_PLUGIN', PLUGIN_BASE);
if (!defined('DOKU_PLUGIN_IMAGES')) define('DOKU_PLUGIN_IMAGES',PLUGIN_BASE.'images/');

require_once DOKU_PLUGIN.'action.php';
require_once PLUGIN_BASE.'lib/Dropbox.php';

class action_plugin_braincase_memories extends Braincase_Action_Plugin {

    private $user;

    /**
     * Register hooks from dokuwiki
     */
    public function register(Doku_Event_Handler &$controller) {

       $controller->register_hook('ACTION_ACT_PREPROCESS', 'BEFORE', $this, 'handle_action_act_preprocess');
       $controller->register_hook('TPL_CONTENT_DISPLAY', 'BEFORE', $this, 'handle_tpl_content_display');
       $controller->register_hook('TPL_ACT_UNKNOWN', 'BEFORE', $this, 'handle_tpl_act_unknown');
       $controller->register_hook('AJAX_CALL_UNKNOWN', 'BEFORE', $this, 'handle_ajax_call_unknown');   
    }

    public function handle_action_act_preprocess(Doku_Event &$event, $param) {

      switch ( $event->data ) {
          case "memories":
            if ( !is_array( $_SESSION ) ) {
              send_redirect("/doku.php?do=login");
              return;
            }
            $event->preventDefault();
            break;
          case "restore":
            if ( !is_array( $_SESSION ) ) {
              send_redirect("/doku.php?do=login");
              return;
            }
            $event->preventDefault();
            break;
          default:
            return;
            break;
        }
    }

    public function handle_ajax_call_unknown(Doku_Event &$event, $param) {
      
      $this->_set_user();

      $event->preventDefault();
      $event->stopPropagation();

      $json = new StdClass;

      switch ( $event->data ) {
        case "restore.memory":
          $json = $this->_restore_memory_from_ajax_request();
          break;
        default:
          $json->message = "Unsupported request";
          break;
      }

      echo json_encode($json);
    }

    public function handle_tpl_content_display(Doku_Event &$event, $param) {
    }

    public function handle_tpl_act_unknown(Doku_Event &$event, $param) {

      global $INPUT;

      $this->_set_user();
      
      try {
        switch ( $event->data ) {
          case "memories":
            echo "<h2>Memories</h2>";
            $this->_show_backup_options();
            $this->_show_memories();
            $event->preventDefault();
            break;
          case "restore":
            $this->_do_restore();
            $event->preventDefault();
            break;
          default:
            return;
            break;
        }
      } catch ( Exception $e ) {
        echo $e->getMessage();
      }
    }

    /**
     * Prints out the backup options
     */
    private function _show_backup_options() {

      $dropbox_status = Dropbox::status_for( $this->user );
      $dropbox_button = Dropbox::generate_button( $this->user );

      include AUTOBACKUP_PLUGIN."inc/backup_options.php"; # TODO: not this
    }

    private function _show_memories() {

      $memory_list = "/home/{$this->user}/memories.list";

      $backups = array();

      if ( file_exists($memory_list) )
        $backups = json_decode( file_get_contents( $memory_list ) );

      $current = new StdClass;
      $current->date = "Current";
      $current->source = "Dokuwiki";

      array_unshift( $backups, $current );

      include PLUGIN_BASE."inc/memories.php"; # TODO: not this
    }

    /**
     * Outputs the XHTML that starts the restore request and 
     * shows the results
     */
    private function _do_restore() {

      $username = $this->user;

      include PLUGIN_BASE."inc/restore.php"; # TODO: not this 
    }

    /**
     * Processes the restore request from the restore page
     * to do the actual restore
     */
    private function _restore_memory_from_ajax_request() {

      $this->source = $_POST['source'];
      $this->timestamp = stripslashes(trim($_POST['timestamp']));
      
      $json = new StdClass;

      // Try to extract and link the wiki
      try {

        $current_timestamp = $this->_get_current_timestamp();

        // Check if we need to do a switch
        if ( $current_timestamp != $timestamp ) {
          // Setup the dokuwiki links
          $cmd = "braincase-wiki-switcher $username $timestamp";
          exec($cmd, $out, $ret);

          if ( $ret != 0 ) {
            $out = implode("\n", $out);
            throw new Exception("Failed to switch timestamps.\n$ $cmd\n$out\nReturned $ret");
          }
        }

        $json->error = 0;
        $json->message = "Successfully restored the Dokuwiki contents from $timestamp";

      } catch ( Exception $e ) {
        $json->error = 1;
        $json->error_output = $e->getMessage();
      }

      return $json;     
    }

    private function _get_current_timestamp() {
      // get current timestamp
      $cmd = "braincase-wiki-switcher {$this->user}";
      exec($cmd, $out, $ret);
      $current_timestamp = trim($out[0]);

      // Check if we need to do a restore
      if ( $current_timestamp != $this->timestamp
        && !file_exists("/home/$username/.dokuwiki/data.{$this->timestamp}") ) {
        
        // Restore the backup requested
        $cmd = "braincase-restore {$this->user} {$this->source} {$this->timestamp} dokuwiki";
        exec($cmd, $out, $ret);
        
        if ( $ret != 0 ) {
          $out = implode("\n", $out);
          throw new Exception("Failed to restore the timestamp.\n$ $cmd\n$out\nReturned $ret");
        }
      }
    }
}

// vim:ts=4:sw=4:et: