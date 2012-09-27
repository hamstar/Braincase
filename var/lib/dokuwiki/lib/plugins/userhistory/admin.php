<?php
if(!defined('DOKU_INC')) die();
if(!defined('DOKU_PLUGIN')) define('DOKU_PLUGIN',DOKU_INC.'lib/plugins/');

require_once(DOKU_PLUGIN.'admin.php');
 
/**
 * All DokuWiki plugins to extend the admin function
 * need to inherit from this class
 */
class admin_plugin_userhistory extends DokuWiki_Admin_Plugin {

	function admin_plugin_userhistory() {
        $this->setupLocale();
	}
 
    /**
     * return some info
     */
    function getInfo(){
      return array(
        'author' => 'Ondra Zara',
        'email'  => 'o.z.fw@seznam.cz',
        'date'   => '2007-01-16',
        'name'   => 'User History',
        'desc'   => 'View page changelog per user',
        'url'    => 'http://wiki.splitbrain.org/plugin:userhistory',
      );
    }
 
    /**
     * return sort order for position in admin menu
     */
    function getMenuSort() {
      return 999;
    }

    /**
     * handle user request
     */
    function handle() {
    }
 
    /**
     * output appropriate html
     */
	function _userList() {
		global $auth;
		global $ID;
		
        $user_list = $auth->retrieveUsers();
		
        echo($this->locale_xhtml('list'));
	
		ptln('<div class="level2">');
		ptln('<ul>');
		foreach ($user_list as $key => $value) {
			$nick = $key;
			$name = $value['name'];
			$href = wl($ID).(strpos(wl($ID),'?')?'&amp;':'?').'do=admin&amp;page='.$this->getPluginName().'&amp;user='.hsc($nick);
			ptln('<li><a href="'.$href.'">'.$nick.' - '.$name.'</li>');
		}
		ptln('</ul>');
		ptln('</div>');
	}	
	
	function _getChanges($user) {
		global $conf;
		
		function globr($dir, $pattern) {
			$files = glob($dir.'/'.$pattern);
			foreach (glob($dir.'/*', GLOB_ONLYDIR) as $subdir) {
				$subfiles = globr($subdir, $pattern);
				$files = array_merge($files, $subfiles);
			}
			return $files;
		}

		$changes = array();
		$alllist = globr($conf['metadir'],'*.changes');
		$skip = array('_comments.changes','_dokuwiki.changes');
		
		for ($i=0;$i<count($alllist);$i++) {
			$fullname = $alllist[$i];
			$filepart = basename($fullname);
			if (in_array($filepart,$skip)) { continue; } 
			
			$f = file($fullname);
			for ($j=0;$j<count($f);$j++) {
				$line = $f[$j];
				$change = parseChangelogLine($line);
				if ($change['user'] == $user) { $changes[] = $change; }
			} /* for all lines */
		} /* for all files */
	
		function cmp($a,$b) {
			$time1 = $a['date'];
			$time2 = $b['date'];
			if ($time1 == $time2) { return 0; }
			return ($time1 < $time2 ? 1 : -1);
		}
		
		uasort($changes,'cmp');
	
		return $changes;
	}
	
	function _userHistory($user) {
		global $conf;
		global $ID;
		
		$href = wl($ID).(strpos(wl($ID),'?')?'&amp;':'?').'do=admin&amp;page='.$this->getPluginName();
		ptln('<p><a href="'.$href.'">['.$this->lang['back'].']</a></p>');

			ptln('<h2>'.$user.'</h2>');
		ptln('<div class="level2">');
		ptln('<ul>');

		$changes = $this->_getChanges($user);
		foreach($changes as $change){
			$date = date($conf['dformat'],$change['date']);
			ptln($change['type']==='e' ? '<li class="minor">' : '<li>');
			ptln('<div class="li">');

			ptln($date.' ');

			ptln('<a href="'.wl($change['id'],"do=diff&rev=".$change['date']).'">');
			$p = array();
			$p['src']    = DOKU_BASE.'lib/images/diff.png';
			$p['width']  = 15;
			$p['height'] = 11;
			$p['title']  = $lang['diff'];
			$p['alt']    = $lang['diff'];
			$att = buildAttributes($p);
			ptln("<img $att />");
			ptln('</a> ');

			ptln('<a href="'.wl($change['id'],"do=revisions").'">');
			$p = array();
			$p['src']    = DOKU_BASE.'lib/images/history.png';
			$p['width']  = 12;
			$p['height'] = 14;
			$p['title']  = $lang['btn_revs'];
			$p['alt']    = $lang['btn_revs'];
			$att = buildAttributes($p);
			ptln("<img $att />");
			ptln('</a> ');

			ptln(html_wikilink(':'.$change['id'],$conf['useheading'] ? NULL : $change['id']));
			ptln(' &ndash; '.hsc($change['sum']));


			ptln('</div>');
			ptln('</li>');
		}
		ptln('</ul>');
	
		ptln('</div>');
	}
	 
    function html() {
		echo($this->locale_xhtml('intro'));
		
		if (isset($_REQUEST['user'])) {
			$this->_userHistory($_REQUEST['user']);	
		} else {
			$this->_userList();	
		}
	}
 
}