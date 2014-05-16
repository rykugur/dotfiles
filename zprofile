# /etc/profile

#Set our umask
umask 022

# Set our default path
PATH="/Users/dustin.jerome/.rvm/rubies/ruby-2.0.0-p481/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/Users/dustin.jerome/.rvm/bin"
export PATH

export ANT_OPTS="-Xmx1024m -Xms512m"

# Load profiles from /etc/profile.d
if test -d /etc/profile.d/; then
	for profile in /etc/profile.d/*.sh; do
		test -r "$profile" && . "$profile"
	done
	unset profile
fi

# Source global bash config
if test "$PS1" && test "$BASH" && test -r /etc/bash.bashrc; then
	. /etc/bash.bashrc
fi

# Termcap is outdated, old, and crusty, kill it.
unset TERMCAP

# Man is much better than us at figuring this out
unset MANPATH
