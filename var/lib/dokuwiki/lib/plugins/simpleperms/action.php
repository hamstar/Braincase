<?php
//error_reporting(E_ERROR | E_WARNING | E_PARSE);
/**
 * Proof of concept plugin for simple per page  permissions
 * in dokuwiki
 *
 * @license    WTFPL 2 (http://sam.zoy.org/wtfpl/)
 * @author     Robert Mcleod <hamstar@telescum.co.nz>
 * @modified   Bhavic Patel <bhavic@hides.me>
 *
 */
// must be run within Dokuwiki
if (!defined('DOKU_INC'))
    die();

/**
 * All DokuWiki plugins to interfere with the event system
 * need to inherit from this class
 */
class action_plugin_simpleperms extends DokuWiki_Action_Plugin
{
    
    public static $PERMISSIONS = array("private" => -1, "other_r" => 0, "other_rw" => 1);
    public static $PERMISSIONS_DESC = array(-1 => "private", 0 => "other_r", 1 => "other_rw");
	//public static  $PERMISSIOS_DESC = array(array_flip($PERMISSIONS)); //This doesn't seem to work
	
	public static $PAGES_TO_IGNORE = array("admin", "profile"); #It will ignore these if in $ACT
	
    
   
    
    /**
     * Registers a callback function for a given event
     */
    function register(&$controller)
    {
         
        
        # Restrict access to editing page
        $controller->register_hook('ACTION_ACT_PREPROCESS', 'AFTER', $this, 'restrict_editing', array());
        
        # For checking permissions before opening
        $controller->register_hook('TPL_CONTENT_DISPLAY', 'BEFORE', $this, 'block_if_private_page', array());
        
        # Hide edit button where applicable
        $controller->register_hook('TPL_CONTENT_DISPLAY', 'BEFORE', $this, 'hide_edit_button', array());
        
        # For adding simple permissions to the edit form
        $controller->register_hook('HTML_EDITFORM_OUTPUT', 'BEFORE', $this, 'insert_dropdown', array());
        
        
        # For saving the simple permissions
        $controller->register_hook('IO_WIKIPAGE_WRITE', 'AFTER', $this, 'add_metadata', array());
        
    }
    
    
    /**
     * Insert the select element into the page
     * Added checks
     */
    function insert_dropdown(&$event, $param)
    {
        # don't add perms select if not author
        if (!$this->_user_is_creator() && $this->_page_exists())
            return;
        
        $pos = $event->data->findElementByAttribute('class', 'summary');
        
        $dropdown = $this->_generate_dropdown();
        $event->data->insertElement($pos++, $dropdown);
        
    }
    
    /**
     * Restricts editing of pages where needed
     */
    function restrict_editing(&$event, $param)
    {
        global $ACT;
        
        if ($ACT != 'save')
            return; # wat the?
        
        # Only author can edit private pages
        if ($this->_private() && !$this->_user_is_creator()) {
            $event->preventDefault();
            echo "Restriced 1";
        }
            
        
        
        # Public can edit if they have permission
        if (!$this->_public_can_edit())
        {
            $event->preventDefault();
            echo "Restriced 2";
        }
    }
    
    /**
     * Adds the simpleperm metadata to the page
     * Ensures only the author can do this
     */
    function add_metadata(&$event, $param)
    {
        global $ACT;
        global $ID;
        global $_REQUEST;
        
        
        # Check it is a save operation
        if ($ACT != "save")
            return;
        
        # don't add perms if not author
        if (!$this->_user_is_creator())
            return;
        
        # Check if the simpleperm value was given in the request
        if (!isset($_REQUEST['simpleperm']))
        return; # hmmm.. select must not have gone on the page
        
        # Generate and set the metadata
        $data = $this->_generate_metadata($_REQUEST['simpleperm']);
        p_set_metadata($ID, $data);
        
    }
    
    /**
     * Doesn't allow the page to be viewed if its private
     */
    function block_if_private_page(&$event, $param)
    {
        global $INFO;
        
		#If page doesn't exist, no need to block it.
        if (!$this->_page_exists()) {
            return;
        }
        
        # Its a private page and user not author, block access
        if ($this->_private() && !$this->_user_is_creator()) {
            $event->preventDefault();
            echo "<h1 class='sectionedit1'><a name='private' id='private'><img width='100px' height='100px' src='http://kinlane-productions.s3.amazonaws.com/api-evangelist/error.png'><strong> This is a private page</strong></a></h1>";
            
        }
        
    }
    
    /**
     * Hides the edit button if the user only has read perms
     */
    function hide_edit_button(&$event, $param)
    {
 
        $this->_check_metadata_exists(); # this should modify $INFO if it doesn't already have simpleperm metadata
        
        if ($this->_user_is_creator())
            return;
        if ($this->_public_can_edit())
            return;
        
		#Using JQuery to remove the edit button for now. It may be better to do it via PHP.
         $out = <<<EOF
		<script>
                     jQuery(document).ready(function(){
                        jQuery('.edit').parent("li").remove();
                        });
                    </script>
EOF;
  echo $out;
    }
    /**
     * Make sure methods that use the metadata get the right INFO[meta]
     * array after calling this on a previously unrestricted page
     */
    function _check_metadata_exists()
    {
        global $INFO;
        global $ID;
        
		#Don't insert metadata on non-existant pages.
        if (!isset($INFO['meta']['permission']) && $this->_page_exists()) {
            # Metadata not set
            $data = array(
                "permission" => self::$PERMISSIONS['private']

            );
            
            p_set_metadata($ID, $data);
            $INFO['meta'] = p_get_metadata($ID, array(), true);
        }
        
        
    }
    
    /**
     * @return true if public can edit
     */
    function _public_can_edit()
    {
        global $INFO;
        
        return ($INFO['meta']['permission'] == self::$PERMISSIONS["other_rw"]);
    }
    
    /**
     * @return true if public can read
     */
    function _public_can_read()
    {
        global $INFO;
        
        return ($INFO['meta']['permission'] == self::$PERMISSIONS["other_r"]);
    }
    
    /**
     * @return true if private
     */
    function _private()
    {
        global $INFO;
		global $ACT;
		
		if ( in_array($ACT,self::$PAGES_TO_IGNORE) ) #Shouldn't block admin page
		return;
        
        return ($INFO['meta']['permission'] == self::$PERMISSIONS["private"]);
    }
    
    /**
     * @return true if the current user is creator
     */
    function _user_is_creator()
    {
        global $INFO;
        
        return ($INFO['meta']['creator'] == $INFO['userinfo']['name']);
    }
    
    /**
     * @return true if page exists
     */
    function _page_exists()
    {
        global $INFO;
        
        return $INFO['exists'];
    }
    
    
    
    /**
     * @return the html for the dropdown permissions selection
     */
    function _generate_dropdown()
    {
        global $INFO;
        $m = $INFO['meta'];
        
        # Get Current Permission
        $perms = ((int) $m['permission']);
        
        # Set default text for each selected
        list($private_selected, $public_r_selected, $public_rw_selected) = array(
            "",
            "",
            ""
        );
        
        # Match the matrix against the 
        switch ($perms) {
            case "0":
                $public_r_selected = " selected";
                break;
            case "1":
                $public_rw_selected = " selected";
                break;
            default:
                $private_selected = " selected";
                break;
        }
        
        # note: default is private
        $out = <<<EOF
		<div class="summary" style="margin-right: 10px;">
			<span>Permissions: <select name="simpleperm">
				<option value="-1"$private_selected>Private</option>
				<option value="0"$public_r_selected> Public Readable </option>
				<option value="1"$public_rw_selected> Writeable </option>
			</select></span>
		</div>
EOF;
        
        return $out;
        
    }
    
    /**
     * @return array of metadata describing the simple permissions
     */
    function _generate_metadata( $sp )
    {
        $data = array(
            "permission" => ""
        );
        
        # set the perms
        switch ($sp) {
            case 0: # public read 
                $data["permission"] = '0';
                break;
            case 1: # public edit 
                $data["permission"] = '1';
                break;
            default: #Private
                $data["permission"] = '-1';
                break;
        }
        
        return $data;
    }
    
    /*
     * @return the Description of the permission, -1, 0 , 1
     * 
     */
    function _get_permission_desc($sp)
    {
        return self::$PERMISSIONS_DESC[$sp];
        
    }
    
    
    
    
}


?>
