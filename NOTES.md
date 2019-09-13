# Extracting INI section

From https://stackoverflow.com/questions/21347695/how-to-read-config-files-with-section-in-bash-shell:

	sed -n '1,/rsync_exclude/d;/\[/,$d;/^$/d;p' config.file > $tmp_file

Explanation:

	* The 1,/rsync_exclude/d excludes all lines up to the rsync_exclude section entry
	* The /\[/,$d excludes everything from the start of the next section to the end of the file
	* The /^$/d excludes empty lines (this is optional)

All of the above extracts the relevant section from the config.


# Getting current GIT tag/branch

https://stackoverflow.com/questions/6245570/how-to-get-the-current-branch-name-in-git

See the comment with "For my own reference (but it might be useful to others) I made an overview of most (basic command line) techniques mentioned in this thread, each applied to several use cases: HEAD is (pointing at):"

## git describe --all

    local branch: heads/master
    remote tracking branch (in sync): heads/master (note: not remotes/origin/master)
    remote tracking branch (not in sync): remotes/origin/feature-foo
    tag: v1.2.3
    submodule: remotes/origin/HEAD
    general detached head: v1.0.6-5-g2393761

# use RELEASE.local

Add line
	
	include $(TOP)/../RELEASE.local

to EPICS module $(TOP)/configure/RELEASE file.


