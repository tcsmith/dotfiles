# PATH
export PATH="$HOME/.local/bin:$PATH"

case "$(uname -s)" in
  Linux)
    export PATH="/snap/bin:$PATH"
    ;;
  Darwin)
    export PATH="/opt/homebrew/bin:/opt/homebrew/opt/llvm/bin:$PATH"
    export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/findutils/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"
    export PATH="/opt/homebrew/opt/gawk/libexec/gnubin:$PATH"
    export PATH="$HOME/.mtplx/bin:$PATH"
    ;;
esac

# Disable the TTYY driver's input-side XON/XOFF 
# bc that shit is annoying AF when u fat finger some keys 
# and dont know why ur hung 
stty -ixon

# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

if command -v uv &>/dev/null; then
  eval "$(uv generate-shell-completion zsh)"
fi

if command -v uvx &>/dev/null; then
  eval "$(uvx --generate-shell-completion zsh)"
fi

# run-help
if [[ "$(uname -s)" == Darwin ]]; then
    (( $+aliases[run-help] )) && unalias run-help
    autoload -Uz run-help
    HELPDIR=/usr/share/zsh/5.9/help
fi

# Aliases
alias tavish=stow
alias ls="ls --color"
alias la="ls -a"
alias ll="ls -la"
alias python="python3"
alias pip="pip3"

# Keybinds
bindkey '\e' kill-whole-line

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt append_history
setopt share_history
setopt hist_ignore_dups
setopt hist_reduce_blanks

# Plugins
case "$(uname -s)" in
  Linux)
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    ;;
  Darwin)
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    ;;
esac

# Prompt
eval "$(starship init zsh)"
