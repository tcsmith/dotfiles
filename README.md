
# dotfiles

The rite of passage repo for any serious *NIX user.

Make all this shit easily portable across machines mang!

## What this is

My personal development configuration, managed in Git across macOS, Ubuntu under WSL, and Windows 11.

The rules are simple:

- Git is the source of truth.
- Share configuration where practical.
- Keep real platform differences explicit.
- Prefer symlinks over duplicated config.
- Keep identity, credentials, and secrets out of the repo.
- Prefer standard tools over dotfiles frameworks.
- Don't invent abstractions until they are needed.

macOS and WSL use GNU Stow. Windows uses native symbolic links.

## Repository layout
```text
dotfiles/
├── git/
├── git-ignore/
├── git-macos/
├── git-windows/
├── git-wsl/
├── nvim/
├── powershell/
├── tmux/
└── zsh/
```
```text
git/            shared Git config
git-ignore/     global Git ignore
git-macos/      macOS Git config
git-windows/    Windows Git config
git-wsl/        WSL Git config
nvim/           shared Neovim config
powershell/     PowerShell config
tmux/           tmux config
zsh/            shared zsh config
```
Shared config stays shared. Platform packages contain only the shit that genuinely differs.

## GNU Stow

The mental model:

> Everything inside a Stow package mirrors where it should appear underneath `$HOME`.

For example:
```text
~/dotfiles/zsh/.zshrc
        ↓
~/.zshrc
```
and:
```text
~/dotfiles/nvim/.config/nvim/
        ↓
~/.config/nvim/
```
The real files live in Git. Stow creates symlinks at the paths applications expect.

From `~/dotfiles`, simulate first:
```zsh
stow --simulate --verbose zsh
```
Then do it:
```zsh
stow --verbose zsh
```
Useful operations:
```zsh
stow zsh       # create links
stow -R zsh    # restow after package structure changes
stow -D zsh    # remove Stow-owned links
```
Unstowing removes links, not the files in the repo. Ordinary edits do not require restowing.

Verify links with:
```zsh
readlink ~/.zshrc
readlink ~/.gitconfig
readlink ~/.gitconfig.local
realpath ~/.zshrc
```
The workflow is:
```text
inspect → simulate → stow → verify → test → commit
```
## Git configuration

Git config is layered so shared settings can be public while platform-specific behavior and personal identity stay separate.

`git/.gitconfig` is shared and includes:
```gitconfig
[include]
    path = ~/.gitconfig.local

[include]
    path = ~/.gitconfig.user
```
That gives us:
```text
~/.gitconfig        shared config from this repo
~/.gitconfig.local  platform-specific config from this repo
~/.gitconfig.user   personal identity, outside this repo
```
Platform packages configure things such as credential helpers without storing credentials themselves.

`~/.gitconfig.user` is deliberately not tracked:
```gitconfig
[user]
    name = Your Name
    email = you@example.com
```
On Unix-like systems:
```zsh
chmod 600 ~/.gitconfig.user
```
Verify what Git is actually using:
```zsh
git config --show-origin --get user.name
git config --show-origin --get user.email
git config --show-origin --get-all credential.helper
```
## Public repo rules

Do not commit passwords, API keys, auth tokens, SSH private keys, cloud credentials, credential databases, personal Git identity, or other secrets.

Credential-helper configuration is fine. Actual credentials are not.

Before pushing questionable changes:
```zsh
git status
git diff
git diff --staged
git ls-files
```
`.gitignore` does not protect files that are already tracked, and deleting sensitive data in a later commit does not remove it from Git history.

## Bootstrapping macOS or WSL

Clone into the expected location:
```zsh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
```
Inspect existing config before replacing anything:
```zsh
ls -l ~/.zshrc
ls -ld ~/.config/nvim
ls -l ~/.gitconfig
```
Then install packages one at a time:
```zsh
stow --simulate --verbose zsh
stow --verbose zsh

stow --simulate --verbose nvim
stow --verbose nvim
```
Typical WSL packages:
```text
git  git-ignore  git-wsl  nvim  tmux  zsh
```
Typical macOS packages:
```text
git  git-ignore  git-macos  nvim  zsh
```
Only install packages that belong on that machine.

## Stow conflicts

If Stow finds an unrelated file where it wants to create a link, it normally refuses instead of overwriting it. Good.

Don't immediately delete the file or reach for `--adopt`. Compare first:
```zsh
diff -u ~/dotfiles/zsh/.zshrc ~/.zshrc
```
Preserve anything important, move the conflict aside, simulate again, then stow.

The desired end state is one real config file in Git plus one symlink at the application's normal path—not two copies waiting to drift apart.

## Windows

Windows lives in the same repo but does not use GNU Stow. Native Windows/PowerShell symbolic links deploy the relevant packages:
```text
git  git-ignore  git-windows  nvim  powershell
```
Windows-specific config stays separate when the platform genuinely differs.

## Neovim and shells

Neovim config is shared across Windows, WSL, and macOS and lives under:
```text
nvim/.config/nvim/
```
The repo contains config, not generated state, caches, downloaded plugins, or other reproducible runtime data.

Shared zsh config lives in `zsh/.zshrc` for macOS and WSL. PowerShell config lives under `powershell/` for Windows.

## Daily workflow

Because the normal Unix config paths are symlinks, editing them edits the repo-backed files directly:
```zsh
nvim ~/.zshrc
```
Then:
```zsh
cd ~/dotfiles
git status
git diff
git add <files>
git diff --staged
git commit
git push
```
On another machine:
```zsh
cd ~/dotfiles
git status
git fetch
git log --oneline HEAD..origin/main
git pull --ff-only
```
`--ff-only` prevents an accidental merge commit if two machines diverged.

If a pull changed package structure:
```zsh
stow --simulate --verbose --restow <package>
stow --verbose --restow <package>
```
## Philosophy

Keep this shit boring.

Git tracks the real files. Stow creates the Unix links. PowerShell handles Windows. Shared config stays shared. Platform differences stay explicit. Secrets stay local.

No giant framework. No duplicated configuration without a reason. No clever abstraction until the boring solution becomes a problem.
