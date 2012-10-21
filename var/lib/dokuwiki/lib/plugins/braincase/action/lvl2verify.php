<?php

class action_braincase_lvl2verify_plugin extends Dokuwiki_Action_Plugin {
	
	private $user;
	private $basename;
	private $tmp;

	function register( &$controller ) {

		$controller->register_hook("TPL_CONTENT_UNKNOWN", "BEFORE", $this, "handle_tpl_content_unknown");
		$controller->register_hook("TPL_ACT_PREPROCESS", "BEFORE", $this, "handle_act_preprocess");
	}

	function handle_act_preprocess( &$e ) {

		switch ( $e->data ) {
			case "verify.archives":
				$this->preventDefault();
				break;
		}
	}

	function handle_tpl_content_unknown( &$e ) {

		global $INFO;

		$this->user = $INFO['client'];
		$this->basename = "/home/{$this->user}/backups";
		$this->tmp = "/home/{$this->user}/backups/tmp";

		switch ( $e->data ) {
			case "verify.archives":
				$this->_verify_archives();
				$this->preventDefault();
				break;
		}
	}

	/**
	 * High level method that verifies the archives given in POST
	 * Called when url is like: 
	 *   doku.php?do=verify.archives&a1=2012.12.15.12.30.02&a0=2012.11.15.12.30.02
	 */
	private function _verify_archives() {

		try {

			// Get the archives from post
			$a0 = urldecode( $_POST['a0'] );
			$a1 = urldecode( $_POST['a1'] );

			// Verify and diff them
			$this->_verify_access( $a0 );
			$this->_verify_access( $a1 );
			$htmldiff $this->_diff_archives( $a0, $a1 );

			$this->_print_report( $diff );

		} catch (Exception $e) {
			
			msg( $e->message, "error" );
		}
	}

	/**
	 * Verifies that the current dokuwiki user has access to the files
	 * Throws exception if there are problems
	 *
	 * @param string $filename the file to check
	 * @return void
	 */
	private function _verify_access( $filename ) {

		# check files are in the local backup folder
		$basename_length = count($this->basename)
		$_basename = substr( $a0, 0, $basename_length );

		if ( $this->basename != $_basename )
			throw new Exception("Illegal file $a0");

		if ( !is_readable( $filename ) )
			throw new Exception("Cannot read $a0");
	}

	/**
	 * Diffs the archives against each other
	 * Extracts the contents and generates MD5SUM of the files
	 * Diffs the MD5SUMs to find out if anything changed/added/removed
	 * @param string $a0 the first archive
	 * @param string $a0 the second archive
	 * @return string html version of the diff
	 */
	private function _diff_archives( $a0, $a1 ) {

		if ( !file_exists($a0) )
			throw new Exception("Could not find the file $a0");

		if ( !file_exists($a1) )
			throw new Exception("Could not find the file $a0");

		$a0md5 = `md5sum $a0`;
		$a1md5 = `md5sum $a1`;

		$a0path = "{$this->tmp}/$a0md5.verify";
		$a1path = "{$this->tmp}/$a1md5.verify";

		$this->_extract_archive( $a0, $a0path );
		$this->_extract_archive( $a1, $a1path );

		$a0sums = $this->_recursive_md5sum( $a0path );
		$a1sums = $this->_recursive_md5sum( $a1path );

		file_put_contents( "{this->tmp}/$a0md5.sums", implode( "\n", $a0sums ) );
		file_put_contents( "{this->tmp}/$a1md5.sums", implode( "\n", $a1sums ) );

		$diff = $this->_diff_files( "{this->tmp}/$a0md5.sums", "{this->tmp}/$a1md5.sums" );
		return $this->_process_diff( $diff );
	}

	/**
	 * Extracts the archives to their own folder in the temp folder
	 * Deletes any existing folders
	 *
	 * @param string $tar the tar to extract
	 * @param string $path the path to extract to
	 */
	private function _extract_archive( $tar, $path ) {

		if ( !file_exists($tar) )
			throw new Exception("Could not find the tar $tar");

		# Delete and recreate the folder
		if ( is_dir($path) )
			array_map('unlink', glob("$path/*"));

		mkdir($path);

		# Check we have the path
		if ( !is_dir( $path )
			throw new Exception("Could not create the folder $path");

		# This command ensures only the needed files ever hit the disk
		$cmd = "tar --to-stdout --strip-components=2 -xf $tar daily_backup/archives/home.tar.gz | "
	          ."tar --strip-components=2 -x -C $path 2>&1";

	    exec( $cmd, $out, $ret );

	    # Throw an exception if need be
	    if ( $ret != 0 )
	    	throw new Exception("Failed to extract archive, tar gave return status $ret:\n".implode("\n", $out));
	}

	/**
	 * Recurses through the given path and returns and MD5SUM
	 * of all the files below that folder
	 *
	 * @param string $path folder to recurse for files to MD5SUM
	 * @return array of files and their MD5SUMs
	 */
	private function _recursive_md5sum( $path ) {

		if ( !is_dir( $path ) )
			throw new Exception("Could not find the path $path");

		# This recursively prints out md5sums of all files in $path
		$cmd = "find $path -type f -exec md5sum {} \; 2>&1";
		exec( $cmd, $sums, $ret );

		if ( $ret != 0 )
			throw new Exception("Finding files to MD5SUM failed: ".implode("\n", $sums));

		if ( count( $sums ) == 0 )
			throw new Exception("No files to MD5SUM");
		
		return $sums;
	}

	/**
	 * Diffs two files together
	 *
	 * @param string $f0 the first file
	 * @param string $f1 the second file
	 */
	private function _diff_files( $f0, $f1 ) {

		if ( !file_exists($f0) )
			throw new Exception("Couldn't find $f0");

		if ( !file_exists($f1) )
			throw new Exception("Couldn't find $f1");

		$cmd = "diff -cC 9999 $f0 $f1 2>&1";
		exec( $cmd, $out, $ret );

		if ( $ret != 0 )
			throw new Exception("Diffing files failed: ".implode("\n", $out));

		return implode("\n", $out);
	}

	/**
	 * Processes the diff file to add HTML to it
	 *
	 * @param string $diff the diff text
	 * @param string the diff HTML
	 */
	private function _process_diff( $diff ) {

		# grab only the second half
		$diff = explode("----", $diff );
		$diff = $diff[ count( $diff ) ];

		# Drop the first line
		$diff = explode("\n", $diff)
		unset($diff[0]);
		
		# Add HTML elements
		foreach ( $diff as &$line ) {

			switch ( substr( $line, 0, 1 ) ) {
				case "!":
					$class = "changed";
					break;
				case "+":
					$class = "added";
					break;
				case "-":
					$class = "removed";
					break;
				default:
					$class = "";
					break;
			}

			$line = "<li class=\"diff-line $class\">$line</li>";
		}

		$diff = implode("\n", $diff);

		return "<ul class=\"diff\">\n\t$diff\n</ul>";
	}
}