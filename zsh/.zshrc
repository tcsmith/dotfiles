# PATH
export PATH="$HOME/.local/bin:/snap/bin:$PATH"

# Completion
autoload -Uz compinit
compinit

# Aliases
alias tavish=stow

# Keybinds
bindkey '\e' kill-whole-line

# Plugins
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Prompt
eval "$(starship init zsh)"
