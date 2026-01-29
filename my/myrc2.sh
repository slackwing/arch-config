export EDITOR="nvim"
export SXIVA_DATA="$HOME/src/minutes/data/"

alias system_update='sudo pacman -Syu'
alias mirror_update='sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist'
alias update_pacman='sudo pacman -Syy'

alias h='history'
alias hc='nvim ~/.config/hypr/hyprland.conf'
alias hcd='cd ~/.config/hypr/'
alias myrc='nvim ~/.config/my/myrc2.sh ; source ~/.config/my/myrc2.sh'
alias mycd='cd ~/.config/my/'
alias keyc='sudo nvim /etc/keyd/default.conf'
alias keycd='cd /etc/keyd/'
alias keyr='sudo systemctl restart keyd'
alias catkeyc='cat /etc/keyd/default.conf'
alias logout='hyprctl dispatch exit'
alias waycd='cd ~/.config/waybar'
alias wayr='pkill waybar; nohup waybar >/dev/null 2>&1 &'
alias audiols='pactl list short sinks'
alias audiocd='pactl set-default-sink'
alias hf='hyprpm enable hyprfocus && hyprpm reload -n'
alias algocd='cd /home/slackwing/src/darkfeather/0g.algo-celes'
alias myrc2='nvim /home/slackwing/src/feathers/tooling/snapshots/.myrc'
alias mkv2webm='ffmpeg -i recording.mkv -c:v libvpx-vp9 -pix_fmt yuv420p -c:a libopus -b:a 128k out.webm'
alias nv='nvim'
alias nvc='nvim ~/.config/nvim/'
alias nvcd='cd ~/.config/nvim/'
alias tmuxc='nvim ~/.config/tmux/tmux.conf'
alias tmuxcd='cd ~/.config/tmux'
alias wifils='nmcli device wifi list'
wificd() {
    nmcli device wifi connect $1 password $2
}
alias wallpaper='pkill hyprpaper ; hyprpaper & ; disown'
alias updatepacman='sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist; sudo pacman -Syyu'
alias last='nvim /home/slackwing/src/minutes/last'
alias ssha='ssh-add ~/.ssh/id_ed25519_gcp_202512'
tmux_panic() {
    tmux -L main-namespace list-panes -a -F '#S:#W.#P pid=#{pane_pid} cmd=#{pane_current_command} path=#{pane_current_path}'
}
alias minutes='cd ~/src/minutes/data/'

# Git

alias gdrop='git checkout --' # as opposed to stashing; supply argument "." for all or specific files
alias guncommit='git reset --soft HEAD~1'
alias gunstage='git restore --staged .' # undo all added to stage (preserve)
gb() {
    # https://stackoverflow.com/a/44529712/925913
    git for-each-ref --sort=-committerdate refs/heads --format='%(authordate:short) %(color:red)%(objectname:short) %(color:yellow)%(refname:short)%(color:reset) (%(color:green)%(committerdate:relative)%(color:reset))' | head -n 10
}
alias g-='git checkout -'
alias gm='git checkout "$(git symbolic-ref refs/remotes/origin/HEAD | cut -d'/' -f4)"'
alias gl='git log --pretty=format:"%h %an %ar - %s" | head -n 10'

# Server

alias ws_ssh='ssh -i ~/.ssh/id_ed25519_gcp_202512 acheong87@35.243.192.242'

# Website

export SRC="$HOME/src"

# Navigating to feathers or a worktree.

alias gworktree='echo "git worktree add (-b <new-branch> <$SRC/worktree-<name>|<$SRC/worktree-<name> <existing-branch>)"'

alias feathers='echo "WARN: Leaving any worktree!\n"; cd $SRC/feathers'

worktree() {
    cd "$SRC/worktree-$1"
}

alias worktrees='ls -d $SRC/worktree-* | xargs -n 1 basename | sort'

# Navigating to relative subpaths.

alias html="cd foundry/website/html/"

# Global shortcuts.

alias journal="worktree journal ; html"

# Updating the server (safely).

currentDirIs() {
    current_dir_name=$(basename "$PWD")
    if [[ "$current_dir_name" == "$1" ]]; then
        return 0
    else
        return 1
    fi
}

require_git_branch() {
    local required="$1"
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || {
        echo "Not in a git repository." >&2
        return 1
    }
    if [[ "$branch" != "$required" ]]; then
        echo "Must be on branch '$required' (currently on '$branch')." >&2
        return 1
    fi
}

website_sync() {
    if [[ $# -lt 2 ]]; then
        echo "Error: Less than 2 arguments supplied." >&2
        return 1
    fi
    if [[ -n "${3:-}" ]]; then
        require_git_branch "$3" || return 1
    fi
    if currentDirIs "html"; then
        echo "\nUploading $PWD/$1 to <remote>/$2 ...\n"
        rsync -avOc \
            --delete \
            --delete-delay \
            --filter='P .staging/' \
            --filter='P shared/assets/' \
            --filter='P **/wordpress/' \
            --itemize-changes \
            --protect-args \
            $1 "acheong87@35.243.192.242:/var/www/html/$2"
    else
        echo "Must be in html/ directory; currently in $PWD."
    fi
}

dashboard_sync() {
    if currentDirIs "feathers"; then
        rsync -av0c \
            --delete \
            --delete-delay \
            --filter='P **/.env' \
            --exclude='__pycache__' \
            --exclude='*.pyc' \
            --exclude='.git' \
            --itemize-changes \
            --protect-args \
            11.sxiv/dashboard/ \
            "acheong87@35.243.192.242:/var/www/dashboard/"
    else
        echo "Must be in feathers/ directory; currently in $PWD."
    fi
}

# Convenience.

alias ws_prod='website_sync . . master'
alias ws_stag='website_sync . .staging/'
alias wsj_prod='website_sync journal/ journal/ master'
alias wsj_stag='website_sync journal/ .staging/journal/ ___journal'
