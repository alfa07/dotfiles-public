#!/usr/bin/env bash

set -Eeuo pipefail
set -x

# SSH CONFIG
export SSH_ENV="$HOME/.ssh/environment"

start_ssh_agent() {
	echo "Initialising new SSH agent..."
	ssh-agent -s | sed 's/^echo/#echo/' >${SSH_ENV}
	echo succeeded
	chmod 600 ${SSH_ENV}
	. ${SSH_ENV} >/dev/null
	ssh-add -k
}

# Source SSH settings, if applicable
load_ssh_session() {
	if [ -f "${SSH_ENV}" ]; then
		. ${SSH_ENV} >/dev/null
		#ps ${SSH_AGENT_PID} doesn't work under cywgin
		ps aux ${SSH_AGENT_PID} | grep 'ssh-agent -s$' >/dev/null || {
			start_ssh_agent
		}
	else
		start_ssh_agent
	fi
}

if [[ -z ${IN_DOCKER+indocker} ]]; then
	load_ssh_session
fi

# END SSH CONFIG
#
ssh-add ~/.ssh/github
ssh-add ~/.ssh/id_ed25519

git clone git@github.com:alfa07/dotfiles4_install.git
