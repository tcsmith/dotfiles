# PATH
export PATH="$HOME/.local/bin:$PATH"

case "$(uname -s)" in
  Linux)
    export PATH="/snap/bin:$PATH"
    ;;
  Darwin)
    export PATH="/opt/homebrew/bin:/opt/homebrew/opt/llvm/bin:$PATH"
    export PATH="$HOME/.mtplx/bin:$PATH"
    ;;
esac

# Completion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

# Aliases
alias tavish=stow
alias ls="ls --color"
alias ll="ls -la"

# Keybinds
bindkey '\e' kill-whole-line

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
