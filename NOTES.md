From https://stackoverflow.com/questions/21347695/how-to-read-config-files-with-section-in-bash-shell:

	sed -n '1,/rsync_exclude/d;/\[/,$d;/^$/d;p' config.file > $tmp_file

Explanation:

	* The 1,/rsync_exclude/d excludes all lines up to the rsync_exclude section entry
	* The /\[/,$d excludes everything from the start of the next section to the end of the file
	* The /^$/d excludes empty lines (this is optional)

All of the above extracts the relevant section from the config.

