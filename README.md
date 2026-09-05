# dotfiles

The rite of passage repo for any serious *NIX user.
Make all this shit easily portable across machines mang!


# Todd's Dotfiles Playbook

A practical guide to migrating an already-working macOS configuration into a small, understandable system built on Git and GNU Stow.

This is a migration guide, not a configuration framework. It does not replace, redesign, or “improve” the existing zsh or Neovim configuration. The job is to move the real files into `~/dotfiles`, let Git track them there, and let Stow place symbolic links where zsh and Neovim already expect their files.

PowerShell is intentionally out of scope. See [Future work: Windows, PowerShell, and `tavish`](#future-work-windows-powershell-and-tavish).

## The finished system

The existing configuration begins like this:

```text
~/.zshrc
~/.config/nvim/
```

After migration, the real files live here:

```text
~/dotfiles/
├── .git/
├── .gitignore
├── zsh/
│   └── .zshrc
└── nvim/
    └── .config/
        └── nvim/
            ├── init.lua
            └── ...
```

The normal application paths become symbolic links into that repository:

```text
~/.zshrc          -> ~/dotfiles/zsh/.zshrc
~/.config/nvim    -> ~/dotfiles/nvim/.config/nvim
```

The exact links Stow creates may be relative, and Stow may link a directory as a unit instead of linking every file separately. Both are normal. Stow intentionally uses relative links and tries to use as few links as possible.

The division of responsibility is simple:

| Layer | Job |
| --- | --- |
| Files in `~/dotfiles` | The real configuration data |
| Git | Records versions of those real files and exchanges commits with a remote |
| GNU Stow | Creates and removes links under the target directory |
| zsh and Neovim | Read their usual paths; neither needs to know Stow exists |

## 1. Concepts before commands

### What are dotfiles?

Dotfiles are ordinary files or directories whose names begin with a dot, such as `.zshrc`, `.gitconfig`, and `.config`. Unix-like systems conventionally treat these names as hidden in normal directory listings. Applications use many of them for per-user configuration.

They are not a special file type. `.zshrc` is still a regular text file, and `.config` is still a regular directory.

### Files, directories, and symbolic links

- A **file** contains data.
- A **directory** contains names that refer to files, directories, or links.
- A **symbolic link**, or **symlink**, is a small filesystem object that points to another path.

Opening a symlink normally opens its destination. That is why zsh can open `~/.zshrc` while the real file lives at `~/dotfiles/zsh/.zshrc`.

This is not a copy. There is one real configuration file and another path that leads to it.

### Why use a dotfiles repository?

A repository gives the configuration one known home. It becomes possible to:

- see exactly what changed;
- return to an earlier working version;
- synchronize changes between machines;
- review a new-machine setup instead of reconstructing it from memory;
- separate portable configuration from machine-specific configuration.

The repository should remain boring: normal files, small packages, Git, and symlinks.

### What Git contributes

Git tracks content and history inside `~/dotfiles`. It answers questions such as:

- What changed?
- When did it change?
- What was the last working version?
- What differs between this Mac and the remote repository?

Git does **not** put `.zshrc` in the home directory. It only tracks the copy inside the repository.

### What GNU Stow contributes

Stow manages the links between the repository and the target filesystem. It treats each top-level package directory—`zsh`, `nvim`, and later perhaps `git`—as a unit that can be linked, unlinked, or relinked.

Stow keeps no separate deployment database. It recognizes links that point into packages in the active Stow directory as links it owns. It will not delete unrelated files merely because they occupy a desired target path.

## 2. The Stow mental model

First, the simple idea:

> Everything inside a package mirrors where it should appear underneath the target directory.

For this layout:

```text
~/dotfiles/
├── zsh/
│   └── .zshrc
└── nvim/
    └── .config/
        └── nvim/
            └── init.lua
```

the three important names are:

| Stow term | In this system | Meaning |
| --- | --- | --- |
| Stow directory | `~/dotfiles` | Directory containing the packages |
| Package | `zsh` or `nvim` | One independently managed configuration tree |
| Target directory | `$HOME` | Root under which the package layout should appear |

Remove the package name from a repository path and place what remains under the target:

```text
~/dotfiles/zsh/.zshrc
             └────── relative package path: .zshrc

$HOME + .zshrc = ~/.zshrc
```

Likewise:

```text
~/dotfiles/nvim/.config/nvim/init.lua
              └──────────────────── relative package path: .config/nvim/init.lua

$HOME + .config/nvim/init.lua = ~/.config/nvim/init.lua
```

This filesystem shape is the whole trick. There is no special Neovim support and no special zsh support inside Stow.

### Default directory and target behavior

When `STOW_DIR` is not set, Stow uses the current working directory as the Stow directory. Its default target is the parent of that Stow directory.

Therefore, after:

```zsh
cd ~/dotfiles
```

this:

```zsh
stow zsh
```

uses `~/dotfiles` as the Stow directory and `$HOME` as the target. That convenient default depends on both the repository location and the current working directory.

The explicit equivalent is:

```zsh
stow --dir="$HOME/dotfiles" --target="$HOME" zsh
```

`--dir` selects the Stow directory. `--target` selects the target directory. The quoted `$HOME` is expanded by zsh while preventing spaces, if any, from splitting the path into multiple arguments.

Use explicit `--dir` and `--target` when:

- running the command from somewhere other than `~/dotfiles`;
- scripting or documenting a command whose meaning should not depend on the current directory;
- keeping the repository somewhere other than directly beneath `$HOME`;
- troubleshooting a suspected wrong-directory or wrong-target problem.

For interactive use in this repository, changing to `~/dotfiles` and using the short form is intentionally simple.

## 3. Safety rules for this migration

1. Migrate exactly one package at a time.
2. Inspect before moving anything.
3. Move the existing working configuration; do not recreate it from memory.
4. Simulate Stow before changing the target tree.
5. Use verbose output for visible confirmation.
6. Inspect the resulting link.
7. Launch the application and verify the configuration.
8. Commit the working package before continuing.
9. Do not use `stow --adopt` as a casual conflict-resolution shortcut. It changes files inside the package tree.
10. Never put a secret into the repository merely because the remote is private.

The migration below uses `mv`. Moving within the same filesystem is reversible: before Stow is run, moving the file back restores the original layout. Optional backup copies provide an additional escape hatch.

## 4. Prerequisites on macOS

The walkthrough assumes:

- the existing `~/.zshrc` works;
- the existing `~/.config/nvim/` works;
- Homebrew is installed;
- Git is installed and configured;
- commands are entered in zsh.

Check the current tools first:

```zsh
zsh --version
git --version
nvim --version
brew --version
```

Each command prints its installed version. Stop here if one of the applications whose configuration is being migrated is missing or currently broken; this guide preserves a working baseline rather than creating one.

### Install GNU Stow

```zsh
brew install stow
```

Homebrew’s official formula uses exactly this command.

Verify what was installed:

```zsh
command -v stow
stow --version
```

`command -v` asks zsh how it would resolve the command. `--version` prints the Stow version and exits.

Local authoritative help is available after installation:

```zsh
man stow
info stow
```

The full Texinfo manual may depend on the `info` reader being available; `man stow` is the immediate command reference.

## 5. Create the repository and its safety net

Git is initialized before migrating the first package so each independently verified package can be committed immediately.

### Create `~/dotfiles`

```zsh
mkdir -p ~/dotfiles
cd ~/dotfiles
pwd
```

`mkdir -p` creates the directory and does not complain if it already exists. `pwd` prints the working directory; it should end in `/dotfiles` directly under the home directory.

Inspect before proceeding:

```zsh
ls -la
```

`-l` uses a detailed listing and `-a` includes dot-prefixed names. A newly created directory should not contain unexpected files.

### Initialize Git

```zsh
git init -b main
git status
```

`-b main` names the initial branch `main`. `git status` confirms the repository and working-tree state.

If `git init -b main` reports that the repository already exists, stop and inspect it. Do not assume an existing repository is disposable.

### Create `.gitignore`

Create `~/dotfiles/.gitignore` with the following conservative starting point:

```gitignore
# macOS metadata
.DS_Store

# Editor swap and backup files
*.swp
*.swo
*~

# Common local secret files
.env
.env.*
!.env.example
*.pem
*.key
credentials*
secrets*
```

This is defense in depth, not a guarantee. A name not listed here can still contain a secret, and broad patterns can hide a file that was actually intended to be shared. Always inspect ignored files and staged changes.

Check the initial state:

```zsh
git status --short
git check-ignore -v .env 2>/dev/null
```

`git status --short` gives a compact status. `git check-ignore -v` explains which ignore rule matches `.env`. `2>/dev/null` redirects only error output to the null device; here it suppresses noise if the test path does not exist or no diagnostic is needed.

Commit the repository scaffold:

```zsh
git add .gitignore
git diff --staged
git commit -m "Initialize dotfiles repository"
```

`git add` stages the file. `git diff --staged` shows exactly what the next commit will contain. `-m` supplies the commit message directly.

## 6. Migrate the existing zsh configuration

Do not create a new `.zshrc`. The working file is the source of truth.

### 6.1 Inspect the existing file

```zsh
ls -l ~/.zshrc
file ~/.zshrc
```

The first command shows whether `.zshrc` is already a link. The second identifies its filesystem/content type.

If `ls -l` shows `->`, it is already a symlink. Resolve and understand that ownership before moving anything; see [Determine what actual file is being edited](#determine-what-actual-file-is-being-edited).

Optionally create a clearly named, temporary backup outside the repository:

```zsh
cp -p ~/.zshrc ~/.zshrc.pre-stow-backup
ls -l ~/.zshrc.pre-stow-backup
```

`cp -p` copies the file while preserving its mode and timestamps where possible. This backup is temporary and must not be added to the repository.

### 6.2 Create the package and move the real file

```zsh
mkdir -p ~/dotfiles/zsh
mv ~/.zshrc ~/dotfiles/zsh/.zshrc
```

This removes the ordinary file from `~/.zshrc` and places that same working file at `~/dotfiles/zsh/.zshrc`. Until the link is created, a newly started zsh will not see it at the normal path.

Inspect both sides immediately:

```zsh
ls -l ~/dotfiles/zsh/.zshrc
ls -l ~/.zshrc
```

The first path should exist. The second should report that it does not exist. If the first path is wrong or missing, stop. To reverse the move before stowing:

```zsh
mv ~/dotfiles/zsh/.zshrc ~/.zshrc
```

### 6.3 Simulate and then create the link

```zsh
cd ~/dotfiles
stow --simulate --verbose zsh
```

`--simulate` performs no filesystem mutations. `--verbose` prints the operations Stow proposes. Confirm that the target is the home directory and that the proposed link is `.zshrc`.

If the simulation is correct:

```zsh
stow --verbose zsh
```

This performs the link operation and prints what Stow does.

### 6.4 Inspect the link

```zsh
ls -l ~/.zshrc
readlink ~/.zshrc
```

`ls -l` shows that `.zshrc` is a symlink and displays its stored destination. `readlink` prints that stored destination alone. Stow normally creates a relative destination, so output such as `dotfiles/zsh/.zshrc` is expected.

On macOS versions that provide `realpath`, this resolves the complete path:

```zsh
command -v realpath
realpath ~/.zshrc
```

Run the second command only if the first prints a command path. `realpath` should print the canonical path ending in `/dotfiles/zsh/.zshrc`. Do not use `readlink -f` as a supposedly universal macOS command; BSD/macOS `readlink` compatibility has historically differed from GNU `readlink`.

Verify identity without modifying the file:

```zsh
cmp ~/.zshrc ~/dotfiles/zsh/.zshrc
```

`cmp` is silent when the two paths resolve to identical bytes. Its silence is meaningful but not very visible, so inspect its exit status immediately:

```zsh
print $?
```

In zsh, `$?` is the exit status of the preceding command. `0` means the contents matched.

### 6.5 Verify zsh still works

First parse the file without executing it:

```zsh
zsh -n ~/.zshrc
print $?
```

`-n` parses commands without executing them. Exit status `0` means zsh found no syntax error; it does not prove every runtime dependency exists.

Then start a fresh interactive zsh:

```zsh
exec zsh
```

`exec` replaces the current shell process with a new zsh, so there is no old shell to return to with `exit`. Confirm the expected prompt, aliases, completion, and key bindings. If replacing the current shell is undesirable, open a new terminal tab instead.

### 6.6 Commit the working package

```zsh
cd ~/dotfiles
git status --short
git add zsh/.zshrc
git diff --staged
git commit -m "Manage zsh configuration with Stow"
```

The `--` in `git diff -- zsh/.zshrc` ends Git’s option parsing and makes the remainder unambiguously a path. The staged diff is the final inspection before committing.

Only after the commit and successful zsh test should the temporary backup be removed. Deleting it is optional; if retained, keep it outside the repository and protect it like any other configuration copy.

## 7. Migrate the existing Neovim configuration

The directory shape matters: the package must contain `.config/nvim`, because the target is `$HOME` and Neovim expects `$HOME/.config/nvim` on macOS in this setup.

### 7.1 Inspect the existing directory

```zsh
ls -ld ~/.config ~/.config/nvim
find ~/.config/nvim -maxdepth 2 -type f -print
```

`ls -d` lists the directories themselves rather than their contents; `-l` shows detailed type and link information. The `find` command prints regular files no deeper than two levels below the Neovim directory. `-maxdepth 2` is supported by the GNU `find` Todd installs through Homebrew; stock BSD `find` on macOS does not provide GNU `-maxdepth`.

For a stock-macOS-only inspection, use:

```zsh
find ~/.config/nvim -type f -print
```

That may print more files, but it avoids GNU-specific options.

If `~/.config/nvim` is already a symlink, resolve it before proceeding.

An optional recursive backup can be made outside the repository:

```zsh
cp -R ~/.config/nvim ~/.config/nvim.pre-stow-backup
ls -ld ~/.config/nvim.pre-stow-backup
```

`-R` copies the directory recursively. This can be large if the existing directory improperly contains caches or downloaded plugins; inspect it first.

### 7.2 Create the package shape and move the directory

```zsh
mkdir -p ~/dotfiles/nvim/.config
mv ~/.config/nvim ~/dotfiles/nvim/.config/nvim
```

This preserves the entire working Neovim tree. The ordinary `~/.config` directory remains in place for other applications.

Inspect the source and target paths:

```zsh
ls -ld ~/dotfiles/nvim/.config/nvim
ls -ld ~/.config/nvim
```

The repository path should exist; the normal Neovim path should not. Before stowing, the reversible rollback is:

```zsh
mv ~/dotfiles/nvim/.config/nvim ~/.config/nvim
```

### 7.3 Simulate and create the Neovim link

```zsh
cd ~/dotfiles
stow --simulate --verbose nvim
```

Confirm that Stow proposes paths underneath `$HOME/.config`, not `$HOME/nvim` and not `~/dotfiles/.config`.

Then perform the operation:

```zsh
stow --verbose nvim
```

Because `~/.config` already exists, Stow normally descends into it and creates a link for `nvim`. If the target tree has a different shape, Stow may create fewer, higher-level links through its normal tree-folding behavior. Inspect the result rather than assuming its granularity.

### 7.4 Inspect Neovim ownership

```zsh
ls -ld ~/.config/nvim
readlink ~/.config/nvim
```

If available:

```zsh
realpath ~/.config/nvim
realpath ~/.config/nvim/init.lua
```

The resolved paths should lead into `~/dotfiles/nvim/.config/nvim`.

If Stow linked individual children instead of the whole `nvim` directory, `readlink ~/.config/nvim` will produce no destination because `nvim` itself is a real directory. In that case inspect a known child:

```zsh
ls -l ~/.config/nvim
readlink ~/.config/nvim/init.lua
```

Stow’s job is the resulting filesystem view, not a promise that every machine will have an identical number of symlinks.

### 7.5 Verify Neovim still works

Ask Neovim where it believes its configuration directory is:

```zsh
nvim --headless '+lua print(vim.fn.stdpath("config"))' +qa
```

`--headless` runs without the interactive UI. The quoted arguments are Ex commands: the first prints Neovim’s computed config path, and `+qa` quits all windows. The output should be `~/.config/nvim` expressed as an absolute path.

Then launch Neovim normally:

```zsh
nvim
```

Verify the same configuration, plugins, key mappings, colors, and expected health checks that worked before migration. This is not the moment to update plugins or change the config; isolate the migration from unrelated changes.

### 7.6 Commit the working package

```zsh
cd ~/dotfiles
git status --short
git add nvim
git diff --staged
git commit -m "Manage Neovim configuration with Stow"
```

At this point both applications use their old paths, both real configurations live in Git, and both package migrations have independent commits.

## 8. Understand what happens when editing a linked path

After migration, opening either of these:

```zsh
nvim ~/.zshrc
nvim ~/.config/nvim/init.lua
```

edits the repository-backed file. The operating system follows the symlink before Neovim opens the destination. There is not a second copy under `$HOME` waiting to be synchronized.

For `.zshrc`, the path traversal is:

```text
~/.zshrc
   │ symlink
   ▼
~/dotfiles/zsh/.zshrc
   │
   └── real file tracked by Git
```

For Neovim, the directory itself may be the link:

```text
~/.config/nvim/
   │ symlinked directory
   ▼
~/dotfiles/nvim/.config/nvim/
   │
   └── real files tracked by Git
```

That is why an edit made through the familiar home-directory path appears immediately in `git status` inside `~/dotfiles`.

## 9. Determine what actual file is being edited

When ownership is unclear, trace the path instead of guessing.

### A single file such as `.zshrc`

```zsh
ls -l ~/.zshrc
readlink ~/.zshrc
realpath ~/.zshrc
```

- `ls -l` distinguishes a regular file from a symlink and shows the stored target.
- `readlink` prints the immediate stored target and does not necessarily make it absolute.
- `realpath` resolves the chain to a canonical path when that command is available.

Expected final ownership:

```text
~/.zshrc -> ~/dotfiles/zsh/.zshrc
```

### A nested configuration such as Neovim

Check every useful level because a parent directory may be the link:

```zsh
ls -ld ~/.config
ls -ld ~/.config/nvim
ls -l ~/.config/nvim/init.lua
realpath ~/.config/nvim/init.lua
```

If `~/.config/nvim` is a symlink, `init.lua` can look like an ordinary file in a normal listing even though the parent directory redirects the traversal.

### Ask the application

For Neovim:

```vim
:lua print(vim.fn.stdpath("config"))
:verbose edit $MYVIMRC
```

The first prints the configured directory Neovim uses. The second opens the startup file and, through `:verbose`, can provide useful sourcing context.

For zsh, inspect the startup environment:

```zsh
print -r -- "ZDOTDIR=${ZDOTDIR:-$HOME}"
```

`print -r` prints raw text without interpreting backslash escapes. `--` ends option parsing. `${ZDOTDIR:-$HOME}` means “use `ZDOTDIR` if it is set and non-empty; otherwise use `$HOME`.” If `ZDOTDIR` is set, zsh looks there for `.zshrc` rather than assuming the home directory.

## 10. Connect a remote repository

Before creating the remote, read the [security section](#security-secrets-and-git-history). A private repository reduces exposure but does not make committed secrets safe.

Create an empty remote repository with the hosting service of choice. Do not initialize that remote with a README, license, or `.gitignore` when the local repository already contains commits; an actually empty remote makes the first push straightforward.

Then connect it:

```zsh
cd ~/dotfiles
git remote add origin <REMOTE-URL>
git remote -v
```

Replace `<REMOTE-URL>` with the SSH or HTTPS clone URL. `origin` is the conventional local name for the primary remote. `git remote -v` prints fetch and push URLs for inspection.

Push the branch:

```zsh
git push -u origin main
```

`-u`, short for `--set-upstream`, records `origin/main` as the upstream for local `main`. Later `git push` and `git pull` can use that relationship without repeating the remote and branch.

Verify:

```zsh
git status
git branch -vv
```

`git branch -vv` shows local branches and their upstream relationships.

## 11. Normal daily workflow

Edit through either the familiar application path or the repository path:

```zsh
nvim ~/.zshrc
```

Then review and publish deliberately:

```zsh
cd ~/dotfiles
git status --short
git diff
git add zsh/.zshrc
git diff --staged
git commit -m "Describe the zsh change"
git push
```

The inspection stages mean:

| Command | Question answered |
| --- | --- |
| `git status --short` | Which tracked, modified, staged, or untracked paths exist? |
| `git diff` | What unstaged content changed? |
| `git diff --staged` | Exactly what will the next commit contain? |
| `git log --oneline --decorate --graph -n 15` | What are the recent commits and branch pointers? |
| `git show --stat HEAD` | Which files changed in the latest commit? |
| `git show HEAD` | What patch is in the latest commit? |

For the log command, `--oneline` condenses each commit, `--decorate` shows branch/tag names, `--graph` draws branch topology, and `-n 15` limits output to fifteen commits.

### When is `stow --restow` needed?

Ordinary edits to the contents of an existing linked file require no Stow command. The symlink already points to the real file.

Use restow after changing package structure—for example, renaming or removing a tracked path—so obsolete target links are pruned and the current package tree is linked again:

```zsh
cd ~/dotfiles
stow --simulate --verbose --restow nvim
stow --verbose --restow nvim
```

`--restow`, equivalent to `-R`, first unstows and then stows the named package.

## 12. Pull changes onto an existing machine

Before pulling, inspect local work:

```zsh
cd ~/dotfiles
git status --short
git fetch
git log --oneline --decorate --graph HEAD..origin/main
git diff HEAD...origin/main
```

`git fetch` updates remote-tracking information without modifying working files. `HEAD..origin/main` asks the log for commits reachable from the remote branch but not the current commit. In `git diff HEAD...origin/main`, three dots compare the merge base with `origin/main`, showing the work introduced on that side since the histories diverged.

If the working tree is clean and the fetched changes are expected:

```zsh
git pull --ff-only
```

`--ff-only` allows the pull only when the local branch can move forward without creating a merge commit. If both machines made commits, it stops and forces a deliberate reconciliation instead of inventing a merge policy.

Content edits take effect immediately through existing links. If the pull changed package paths, simulate and restow the affected package:

```zsh
stow --simulate --verbose --restow nvim
stow --verbose --restow nvim
```

Verify the affected application after pulling.

## 13. Bootstrap a fresh Mac

This procedure assumes the remote has already been reviewed for secrets and the new Mac does not contain irreplaceable configuration at the target paths.

### 13.1 Install prerequisites

Install Homebrew through its official instructions, then:

```zsh
brew install git stow neovim
```

The arguments name three Homebrew formulae. Installing Neovim here is appropriate only if the repository’s configuration expects the Homebrew build; preserve any deliberate existing installation choice.

Install any external commands referenced by the existing zsh or Neovim configuration separately. Stow deploys configuration; it does not install the programs that configuration invokes. Todd’s macOS setup may also use Homebrew GNU tools such as `coreutils`, `findutils`, `grep`, `gnu-sed`, and `gawk`, but those are dependencies only when the actual configuration relies on them. Do not install a giant toolchain blindly.

### 13.2 Inspect existing target paths

Before cloning or stowing:

```zsh
ls -l ~/.zshrc
ls -ld ~/.config ~/.config/nvim
```

If either configuration already exists, do not run Stow over it. Compare it, back it up, and resolve ownership using the conflict procedure below.

### 13.3 Clone into the expected Stow directory

```zsh
git clone <REMOTE-URL> ~/dotfiles
cd ~/dotfiles
git status
```

`git clone` creates `~/dotfiles`, configures `origin`, downloads repository history, and checks out the remote’s default branch. Cloning into an existing non-empty directory is not allowed.

Review before linking:

```zsh
git log --oneline --decorate --graph -n 15
find . -maxdepth 3 -type f -print
```

The shown `find -maxdepth` form requires GNU `find`. With stock macOS `find`, omit `-maxdepth 3`.

### 13.4 Simulate one package at a time

```zsh
stow --simulate --verbose zsh
stow --verbose zsh
ls -l ~/.zshrc
zsh -n ~/.zshrc
```

Open a fresh zsh and verify it. Only then continue:

```zsh
stow --simulate --verbose nvim
stow --verbose nvim
ls -ld ~/.config/nvim
nvim
```

The package-by-package rule matters just as much during bootstrap as during initial migration.

## 14. Stow conflicts and safe resolution

### What happens when a target already exists?

If Stow needs to create a link where an unrelated ordinary file already exists, it reports a conflict and refuses the operation. This is a safety feature. Stow does not overwrite the file by default.

A typical cause is this duplication:

```text
~/dotfiles/zsh/.zshrc    # repository copy
~/.zshrc                 # independent ordinary file
```

There are now two real files. Stow cannot know which one should win.

### Safe conflict procedure

1. **Stop. Do not delete either copy.**
2. Identify both filesystem types and resolve any links.
3. Compare contents.
4. Decide which content is authoritative.
5. Preserve the other copy as a named backup or merge intentional differences.
6. Move the independent target out of the way.
7. Simulate Stow again.
8. Stow, inspect, test, and commit any merged change.

For `.zshrc`:

```zsh
ls -l ~/.zshrc ~/dotfiles/zsh/.zshrc
diff -u ~/dotfiles/zsh/.zshrc ~/.zshrc
```

`diff -u` produces a unified diff, with context, between the repository copy and the independent home-directory copy. Its argument order determines which side is shown as removed versus added.

If the repository version is authoritative and the independent file must merely be preserved:

```zsh
mv ~/.zshrc ~/.zshrc.conflict-backup
cd ~/dotfiles
stow --simulate --verbose zsh
stow --verbose zsh
```

`mv` changes the independent file’s name; it does not delete it. After testing, inspect the backup and remove it only through a deliberate decision.

For a Neovim directory, compare recursively:

```zsh
diff -ru ~/dotfiles/nvim/.config/nvim ~/.config/nvim
```

`-r` compares directories recursively and `-u` uses unified output. Then rename the independent tree rather than erasing it:

```zsh
mv ~/.config/nvim ~/.config/nvim.conflict-backup
```

### Why this guide does not recommend `--adopt` for routine conflicts

Stow provides `--adopt`, but its documented purpose is to move an existing target file into the package’s corresponding location, thereby **altering the contents of the Stow directory**, and then proceed with stowing. If a package copy already exists, this can change the repository copy in a way that is easy to misunderstand.

It can be useful in an expert, Git-reviewed workflow, but it is not the safe default for onboarding. Explicit comparison and a reversible rename make the chosen source of truth obvious.

## 15. Unstow, restow, and package lifecycle

### Unstow a package

Simulate first:

```zsh
cd ~/dotfiles
stow --simulate --verbose --delete zsh
```

Then remove Stow-owned target links:

```zsh
stow --verbose --delete zsh
```

`--delete`, equivalent to `-D`, unstows the package. It removes links in the target tree that Stow owns. It does **not** delete `~/dotfiles/zsh` or remove the configuration from Git.

Short form:

```zsh
stow -D zsh
```

`-D` is the short spelling of `--delete`. The long spelling is clearer in scripts and documentation; the short spelling is convenient interactively.

After unstowing, `~/.zshrc` will normally be absent, so a new zsh will no longer load that package. The real file remains safely at `~/dotfiles/zsh/.zshrc`.

### Stow it again

```zsh
stow --verbose zsh
```

This recreates the links from the unchanged package tree.

### Restow after changing package shape

```zsh
stow --verbose --restow zsh
```

`--restow`, equivalent to `-R`, performs delete followed by stow. It is especially useful for pruning links to files that were removed or renamed inside a package.

Short form:

```zsh
stow -R zsh
```

### Remove a package from this machine without deleting its Git copy

```zsh
cd ~/dotfiles
stow --verbose --delete nvim
git status --short
```

The target links disappear, but `nvim/` remains tracked and `git status` should show no repository deletion. This is the correct operation when the package should remain available in Git but inactive on one machine.

Deleting the package directory from `~/dotfiles` is a separate Git/content decision. Do not confuse “unstow” with “erase.”

### Useful Stow command reference

Run these from `~/dotfiles` unless explicit paths are shown.

| Command | Effect |
| --- | --- |
| `stow zsh` | Stow the `zsh` package using default directory and target |
| `stow --simulate --verbose zsh` | Show proposed changes without making them |
| `stow -D zsh` | Unstow `zsh` |
| `stow --delete zsh` | Same operation, long spelling |
| `stow -R zsh` | Unstow and then stow `zsh` |
| `stow --restow zsh` | Same operation, long spelling |
| `stow --dir="$HOME/dotfiles" --target="$HOME" zsh` | Stow with explicit directory and target |
| `stow --version` | Print installed Stow version |
| `stow --help` | Print command syntax and options |

Stow also supports multiple package names in one invocation, but the migration and bootstrap procedures intentionally use one package at a time for isolation and verification.

## 16. What belongs in the repository

Good candidates are small, understandable, user-authored configuration files:

- `.zshrc` and related shell functions or completion configuration;
- Neovim Lua configuration;
- Git configuration that contains no credentials or machine-only identity;
- Starship configuration;
- small scripts intentionally maintained as source;
- platform-specific fragments with explicit names and includes.

Todd’s broader cross-platform organization can use separate packages such as:

```text
git/
git-macos/
git-wsl/
git-windows/
git-ignore/
```

The general pattern is a portable base plus small, explicit platform overlays—not conditionals and duplicated files everywhere. Only packages relevant to a machine need to be stowed there.

Poor candidates include:

- caches, logs, swap files, histories, and generated state;
- plugin downloads or build output that a package manager can recreate;
- the Neovim state/data/cache directories returned by `stdpath("state")`, `stdpath("data")`, or `stdpath("cache")`;
- entire application-support directories copied without understanding them;
- host keys, SSH private keys, password databases, or credential stores;
- machine-generated files that churn constantly;
- large binaries;
- configuration containing secrets.

Track the source that explains the setup, not every byte an application happens to create.

## 17. Security: secrets and Git history

### Never commit these

- passwords;
- API keys;
- authentication or refresh tokens;
- SSH private keys;
- cloud-provider credentials;
- private certificates or certificate keys;
- application login databases;
- machine-specific secrets;
- cookies, session exports, or credential-helper stores.

Do not copy all of `~/.ssh`, `~/.aws`, `~/.config`, `~/Library`, or a similar broad tree into a package. Select known configuration files deliberately.

### Private does not mean secret-safe

A private remote restricts who can access it today. It does not prevent:

- accidental sharing;
- account compromise;
- overly broad collaborator access;
- CI logs or backups retaining data;
- later changing repository visibility;
- secrets living indefinitely in clones and history.

Build the repository so it could be audited or shared without exposing credentials, even if the chosen remote is private.

### Git history preserves deleted secrets

Deleting a secret in a later commit removes it from the current checkout, not from earlier commits. Anyone with the history may still retrieve it.

If a secret is committed:

1. revoke or rotate it immediately;
2. remove it from the current tree;
3. determine where it was pushed or copied;
4. rewrite history with an appropriate supported tool if necessary;
5. coordinate replacement of all affected clones and remote references.

History rewriting does not make rotation optional. Once exposed, treat the old credential as compromised.

### Separate configuration from secrets

Preferred strategies:

- Keep secrets in the macOS Keychain or a dedicated secret manager.
- Source a local file that is explicitly ignored, such as `~/.config/zsh/secrets.zsh`, only if it exists.
- Commit an `.example` file containing placeholder names, never real values.
- Use environment variables supplied by a secure login/session mechanism.
- Split portable Git configuration from machine-specific identity or credential configuration.
- Stow only the shareable package; create the secret file independently on each machine with restrictive permissions.

An ignored local file is not automatically encrypted or backed up. `.gitignore` only tells Git not to add an untracked matching path by default.

### Inspect before every push

```zsh
git status --short
git diff
git diff --staged
git log --oneline --decorate -n 5
```

Also inspect all tracked paths periodically:

```zsh
git ls-files
```

`git ls-files` prints paths in Git’s index. Look for credentials, histories, private keys, `.env` files, database files, and unexpected application state.

Remember that `.gitignore` does not stop Git from tracking a file already committed. If an ordinary non-secret generated file was accidentally tracked, remove it from the index while retaining the working copy with:

```zsh
git rm --cached -- path/to/file
```

`--cached` removes the path from Git’s index but leaves the working-tree file. The `--` ends option parsing. This creates a staged deletion and does not erase the file from prior history. For an actual secret, rotate first and follow an incident/history-cleanup process.

## 18. Troubleshooting

### Stow refuses because a target already exists

Cause: an unrelated file or link already owns the desired target name.

Diagnosis:

```zsh
ls -l ~/.zshrc ~/dotfiles/zsh/.zshrc
diff -u ~/dotfiles/zsh/.zshrc ~/.zshrc
```

Resolution: compare, preserve both, choose the authoritative content, move the independent target to a backup name, simulate, then stow. Do not blindly delete the target and do not reach first for `--adopt`.

### A symlink points somewhere unexpected

```zsh
ls -l ~/.zshrc
readlink ~/.zshrc
realpath ~/.zshrc
```

A relative `readlink` result is normal. `realpath` shows where the complete chain resolves. If it resolves outside the intended package, do not edit or delete it until its owner is understood.

### The config worked before migration but not afterward

Check in order:

1. Does the normal application path exist?
2. Is it a valid link?
3. Does it resolve into the expected package?
4. Is the real file still present?
5. Does the application compute the expected config directory?
6. Did permissions or external dependencies change independently?

Commands:

```zsh
ls -l ~/.zshrc
realpath ~/.zshrc
ls -l ~/dotfiles/zsh/.zshrc
zsh -n ~/.zshrc
```

For Neovim:

```zsh
ls -ld ~/.config/nvim
realpath ~/.config/nvim
nvim --headless '+lua print(vim.fn.stdpath("config"))' +qa
```

If the links and real files are correct, the problem may be inside the application configuration rather than Stow. Keep those diagnoses separate.

### Wrong Stow target

Symptom: links appear beside `dotfiles`, inside the repository, or under another unexpected directory.

Check:

```zsh
pwd
stow --simulate --verbose --dir="$HOME/dotfiles" --target="$HOME" zsh
```

Use the explicit command to eliminate ambiguity. The desired target is `$HOME`.

### Stow was run from the wrong directory

Bare `stow zsh` interprets the current directory as the Stow directory. Fix the context:

```zsh
cd ~/dotfiles
pwd
stow --simulate --verbose zsh
```

Or use explicit `--dir` and `--target` from anywhere.

### Package directory has the wrong filesystem shape

Incorrect Neovim package:

```text
~/dotfiles/nvim/init.lua
```

With `$HOME` as target, that shape asks Stow to create `~/init.lua`.

Correct:

```text
~/dotfiles/nvim/.config/nvim/init.lua
```

Mentally remove `~/dotfiles/nvim/`; what remains must be the path relative to `$HOME`.

### Broken symlink

```zsh
ls -l ~/.zshrc
readlink ~/.zshrc
test -e ~/.zshrc
print $?
```

`test -e` succeeds when the path resolves to an existing object. Exit status `1` after `ls -l` showed a symlink indicates a likely broken destination.

Check whether the repository moved or the real file was renamed. Restore the expected repository path, or unstow using the original Stow directory and restow from the new intended location. Avoid manually recreating a link until the package layout is understood.

### Git says configuration changed unexpectedly

Because the normal config path resolves into the repository, an application, plugin updater, formatter, or manual edit may have changed tracked content.

```zsh
cd ~/dotfiles
git status --short
git diff
git diff --stat
```

`--stat` summarizes affected files and line counts. Do not discard the change until it has been identified. Generated files probably should be removed from the package and ignored; real configuration changes should be reviewed and committed or deliberately reverted.

### A file exists both in the repository and independently under `$HOME`

There are two sources of truth. Stow will normally report a conflict instead of choosing one. Use `diff`, preserve both, merge intentional differences, rename the independent target, and then stow. The goal is to end with one real file in the repository and one Stow-managed route to it.

### Neovim cannot find its config

```zsh
nvim --headless '+lua print(vim.fn.stdpath("config"))' +qa
ls -ld ~/.config/nvim
realpath ~/.config/nvim
ls -l ~/dotfiles/nvim/.config/nvim/init.lua
```

Confirm that Neovim’s computed config path matches the target layout. Also check whether `XDG_CONFIG_HOME` is set:

```zsh
print -r -- "${XDG_CONFIG_HOME:-not set}"
```

If set, it changes the base configuration directory. Do not relocate files until determining why it is set and whether that was part of the previously working setup.

### zsh loads a different startup file

zsh reads different files for login, interactive, and other shell modes. For the `.zshrc` path specifically, first inspect `ZDOTDIR`:

```zsh
print -r -- "ZDOTDIR=${ZDOTDIR:-$HOME}"
ls -l "${ZDOTDIR:-$HOME}/.zshrc"
```

The quoted parameter expansion chooses `ZDOTDIR` when set and otherwise `$HOME`, while keeping the resulting path a single argument.

Confirm the current shell and whether it is interactive:

```zsh
print -r -- "$SHELL"
[[ -o interactive ]] && print "interactive zsh" || print "non-interactive zsh"
```

`[[ -o interactive ]]` is a zsh conditional that tests the shell option. `&&` runs the next command on success; `||` runs the final command on failure. If another startup file sets `ZDOTDIR`, the effective `.zshrc` may not be `~/.zshrc`.

## 19. Portability to Linux and WSL

The Stow model is the same:

- choose a Stow directory, commonly `~/dotfiles`;
- use `$HOME` as the target;
- make every package mirror paths relative to `$HOME`;
- keep real files in Git;
- link only the packages appropriate for that environment.

The main differences are installation and platform-specific configuration:

- install `stow` with the distribution’s package manager rather than Homebrew;
- GNU userland tools are commonly native on Linux, while macOS ships BSD variants of several commands;
- paths, installed programs, clipboard commands, package-manager locations, and some shell initialization details differ;
- WSL is Linux for Stow/package layout purposes, but may need WSL-specific Git, clipboard, PATH, or interop configuration.

Do not solve portability by stuffing every operating-system difference into one giant `.zshrc`. A portable base package plus small explicit packages such as `git-macos` and `git-wsl` keeps ownership understandable.

When bootstrapping Linux or WSL, use the same one-package loop:

```text
inspect existing target
→ clone
→ simulate one package
→ stow it
→ inspect links
→ test the application
→ continue
```

## 20. Future work: Windows, PowerShell, and `tavish`

PowerShell support is deliberately not specified in this version.

Future documentation will cover Windows and PowerShell after the workflow is implemented and verified. Todd’s intended direction is a small `tavish` command providing simple Stow-like linking and unlinking behavior. Its command syntax, target rules, link type, conflict behavior, package layout, and safety guarantees are not yet defined here and must not be inferred from GNU Stow.

Until that work exists, this playbook covers macOS first and the same GNU Stow model on Linux/WSL at a high level.

## 21. Compact operational checklist

### Initial migration

```text
install and verify Stow
→ create ~/dotfiles and initialize Git
→ add and inspect .gitignore
→ inspect ~/.zshrc
→ move it into zsh/.zshrc
→ simulate stow zsh
→ stow zsh
→ inspect link and test zsh
→ commit
→ inspect ~/.config/nvim
→ move it into nvim/.config/nvim
→ simulate stow nvim
→ stow nvim
→ inspect link and test Neovim
→ commit
→ audit for secrets
→ connect remote and push
```

### Every later package

```text
inspect
→ preserve/move the working config
→ mirror its target-relative path in one package
→ simulate
→ stow with verbose output
→ trace the resulting links
→ test the owning application
→ review Git diff
→ commit
→ push
```

## References

Behavior and options in this guide were checked against current primary or packaged command documentation:

- [GNU Stow project and manual](https://www.gnu.org/software/stow/)
- [GNU Stow 2.4.1 manual page](https://man.archlinux.org/man/stow.8)
- [Homebrew `stow` formula](https://formulae.brew.sh/formula/stow)
- [Git documentation](https://git-scm.com/docs)
- [Git `init`](https://git-scm.com/docs/git-init), [`clone`](https://git-scm.com/docs/git-clone), [`diff`](https://git-scm.com/docs/git-diff), and [`push`](https://git-scm.com/docs/git-push) references
- [Current macOS/Xcode command manual index, including `readlink` and `realpath`](https://keith.github.io/xcode-man-pages/)

The locally installed manuals remain authoritative for the exact versions on a particular machine:

```zsh
man stow
git help <command>
man readlink
man realpath
```

Replace `<command>` with a Git subcommand such as `diff` or `push`. Angle brackets here mark a placeholder; do not type them literally.

A practical guide to migrating an already-working macOS configuration into a small, understandable system built on Git and GNU Stow.

This is a migration guide, not a configuration framework. It does not replace, redesign, or “improve” the existing zsh or Neovim configuration. The job is to move the real files into `~/dotfiles`, let Git track them there, and let Stow place symbolic links where zsh and Neovim already expect their files.

PowerShell is intentionally out of scope. See [Future work: Windows, PowerShell, and `tavish`](#future-work-windows-powershell-and-tavish).

## The finished system

The existing configuration begins like this:

```text
~/.zshrc
~/.config/nvim/
```

After migration, the real files live here:

```text
~/dotfiles/
├── .git/
├── .gitignore
├── zsh/
│   └── .zshrc
└── nvim/
    └── .config/
        └── nvim/
            ├── init.lua
            └── ...
```

The normal application paths become symbolic links into that repository:

```text
~/.zshrc          -> ~/dotfiles/zsh/.zshrc
~/.config/nvim    -> ~/dotfiles/nvim/.config/nvim
```

The exact links Stow creates may be relative, and Stow may link a directory as a unit instead of linking every file separately. Both are normal. Stow intentionally uses relative links and tries to use as few links as possible.

The division of responsibility is simple:

| Layer | Job |
| --- | --- |
| Files in `~/dotfiles` | The real configuration data |
| Git | Records versions of those real files and exchanges commits with a remote |
| GNU Stow | Creates and removes links under the target directory |
| zsh and Neovim | Read their usual paths; neither needs to know Stow exists |

## 1. Concepts before commands

### What are dotfiles?

Dotfiles are ordinary files or directories whose names begin with a dot, such as `.zshrc`, `.gitconfig`, and `.config`. Unix-like systems conventionally treat these names as hidden in normal directory listings. Applications use many of them for per-user configuration.

They are not a special file type. `.zshrc` is still a regular text file, and `.config` is still a regular directory.

### Files, directories, and symbolic links

- A **file** contains data.
- A **directory** contains names that refer to files, directories, or links.
- A **symbolic link**, or **symlink**, is a small filesystem object that points to another path.

Opening a symlink normally opens its destination. That is why zsh can open `~/.zshrc` while the real file lives at `~/dotfiles/zsh/.zshrc`.

This is not a copy. There is one real configuration file and another path that leads to it.

### Why use a dotfiles repository?

A repository gives the configuration one known home. It becomes possible to:

- see exactly what changed;
- return to an earlier working version;
- synchronize changes between machines;
- review a new-machine setup instead of reconstructing it from memory;
- separate portable configuration from machine-specific configuration.

The repository should remain boring: normal files, small packages, Git, and symlinks.

### What Git contributes

Git tracks content and history inside `~/dotfiles`. It answers questions such as:

- What changed?
- When did it change?
- What was the last working version?
- What differs between this Mac and the remote repository?

Git does **not** put `.zshrc` in the home directory. It only tracks the copy inside the repository.

### What GNU Stow contributes

Stow manages the links between the repository and the target filesystem. It treats each top-level package directory—`zsh`, `nvim`, and later perhaps `git`—as a unit that can be linked, unlinked, or relinked.

Stow keeps no separate deployment database. It recognizes links that point into packages in the active Stow directory as links it owns. It will not delete unrelated files merely because they occupy a desired target path.

## 2. The Stow mental model

First, the simple idea:

> Everything inside a package mirrors where it should appear underneath the target directory.

For this layout:

```text
~/dotfiles/
├── zsh/
│   └── .zshrc
└── nvim/
    └── .config/
        └── nvim/
            └── init.lua
```

the three important names are:

| Stow term | In this system | Meaning |
| --- | --- | --- |
| Stow directory | `~/dotfiles` | Directory containing the packages |
| Package | `zsh` or `nvim` | One independently managed configuration tree |
| Target directory | `$HOME` | Root under which the package layout should appear |

Remove the package name from a repository path and place what remains under the target:

```text
~/dotfiles/zsh/.zshrc
             └────── relative package path: .zshrc

$HOME + .zshrc = ~/.zshrc
```

Likewise:

```text
~/dotfiles/nvim/.config/nvim/init.lua
              └──────────────────── relative package path: .config/nvim/init.lua

$HOME + .config/nvim/init.lua = ~/.config/nvim/init.lua
```

This filesystem shape is the whole trick. There is no special Neovim support and no special zsh support inside Stow.

### Default directory and target behavior

When `STOW_DIR` is not set, Stow uses the current working directory as the Stow directory. Its default target is the parent of that Stow directory.

Therefore, after:

```zsh
cd ~/dotfiles
```

this:

```zsh
stow zsh
```

uses `~/dotfiles` as the Stow directory and `$HOME` as the target. That convenient default depends on both the repository location and the current working directory.

The explicit equivalent is:

```zsh
stow --dir="$HOME/dotfiles" --target="$HOME" zsh
```

`--dir` selects the Stow directory. `--target` selects the target directory. The quoted `$HOME` is expanded by zsh while preventing spaces, if any, from splitting the path into multiple arguments.

Use explicit `--dir` and `--target` when:

- running the command from somewhere other than `~/dotfiles`;
- scripting or documenting a command whose meaning should not depend on the current directory;
- keeping the repository somewhere other than directly beneath `$HOME`;
- troubleshooting a suspected wrong-directory or wrong-target problem.

For interactive use in this repository, changing to `~/dotfiles` and using the short form is intentionally simple.

## 3. Safety rules for this migration

1. Migrate exactly one package at a time.
2. Inspect before moving anything.
3. Move the existing working configuration; do not recreate it from memory.
4. Simulate Stow before changing the target tree.
5. Use verbose output for visible confirmation.
6. Inspect the resulting link.
7. Launch the application and verify the configuration.
8. Commit the working package before continuing.
9. Do not use `stow --adopt` as a casual conflict-resolution shortcut. It changes files inside the package tree.
10. Never put a secret into the repository merely because the remote is private.

The migration below uses `mv`. Moving within the same filesystem is reversible: before Stow is run, moving the file back restores the original layout. Optional backup copies provide an additional escape hatch.

## 4. Prerequisites on macOS

The walkthrough assumes:

- the existing `~/.zshrc` works;
- the existing `~/.config/nvim/` works;
- Homebrew is installed;
- Git is installed and configured;
- commands are entered in zsh.

Check the current tools first:

```zsh
zsh --version
git --version
nvim --version
brew --version
```

Each command prints its installed version. Stop here if one of the applications whose configuration is being migrated is missing or currently broken; this guide preserves a working baseline rather than creating one.

### Install GNU Stow

```zsh
brew install stow
```

Homebrew’s official formula uses exactly this command.

Verify what was installed:

```zsh
command -v stow
stow --version
```

`command -v` asks zsh how it would resolve the command. `--version` prints the Stow version and exits.

Local authoritative help is available after installation:

```zsh
man stow
info stow
```

The full Texinfo manual may depend on the `info` reader being available; `man stow` is the immediate command reference.

## 5. Create the repository and its safety net

Git is initialized before migrating the first package so each independently verified package can be committed immediately.

### Create `~/dotfiles`

```zsh
mkdir -p ~/dotfiles
cd ~/dotfiles
pwd
```

`mkdir -p` creates the directory and does not complain if it already exists. `pwd` prints the working directory; it should end in `/dotfiles` directly under the home directory.

Inspect before proceeding:

```zsh
ls -la
```

`-l` uses a detailed listing and `-a` includes dot-prefixed names. A newly created directory should not contain unexpected files.

### Initialize Git

```zsh
git init -b main
git status
```

`-b main` names the initial branch `main`. `git status` confirms the repository and working-tree state.

If `git init -b main` reports that the repository already exists, stop and inspect it. Do not assume an existing repository is disposable.

### Create `.gitignore`

Create `~/dotfiles/.gitignore` with the following conservative starting point:

```gitignore
# macOS metadata
.DS_Store

# Editor swap and backup files
*.swp
*.swo
*~

# Common local secret files
.env
.env.*
!.env.example
*.pem
*.key
credentials*
secrets*
```

This is defense in depth, not a guarantee. A name not listed here can still contain a secret, and broad patterns can hide a file that was actually intended to be shared. Always inspect ignored files and staged changes.

Check the initial state:

```zsh
git status --short
git check-ignore -v .env 2>/dev/null
```

`git status --short` gives a compact status. `git check-ignore -v` explains which ignore rule matches `.env`. `2>/dev/null` redirects only error output to the null device; here it suppresses noise if the test path does not exist or no diagnostic is needed.

Commit the repository scaffold:

```zsh
git add .gitignore
git diff --staged
git commit -m "Initialize dotfiles repository"
```

`git add` stages the file. `git diff --staged` shows exactly what the next commit will contain. `-m` supplies the commit message directly.

## 6. Migrate the existing zsh configuration

Do not create a new `.zshrc`. The working file is the source of truth.

### 6.1 Inspect the existing file

```zsh
ls -l ~/.zshrc
file ~/.zshrc
```

The first command shows whether `.zshrc` is already a link. The second identifies its filesystem/content type.

If `ls -l` shows `->`, it is already a symlink. Resolve and understand that ownership before moving anything; see [Determine what actual file is being edited](#determine-what-actual-file-is-being-edited).

Optionally create a clearly named, temporary backup outside the repository:

```zsh
cp -p ~/.zshrc ~/.zshrc.pre-stow-backup
ls -l ~/.zshrc.pre-stow-backup
```

`cp -p` copies the file while preserving its mode and timestamps where possible. This backup is temporary and must not be added to the repository.

### 6.2 Create the package and move the real file

```zsh
mkdir -p ~/dotfiles/zsh
mv ~/.zshrc ~/dotfiles/zsh/.zshrc
```

This removes the ordinary file from `~/.zshrc` and places that same working file at `~/dotfiles/zsh/.zshrc`. Until the link is created, a newly started zsh will not see it at the normal path.

Inspect both sides immediately:

```zsh
ls -l ~/dotfiles/zsh/.zshrc
ls -l ~/.zshrc
```

The first path should exist. The second should report that it does not exist. If the first path is wrong or missing, stop. To reverse the move before stowing:

```zsh
mv ~/dotfiles/zsh/.zshrc ~/.zshrc
```

### 6.3 Simulate and then create the link

```zsh
cd ~/dotfiles
stow --simulate --verbose zsh
```

`--simulate` performs no filesystem mutations. `--verbose` prints the operations Stow proposes. Confirm that the target is the home directory and that the proposed link is `.zshrc`.

If the simulation is correct:

```zsh
stow --verbose zsh
```

This performs the link operation and prints what Stow does.

### 6.4 Inspect the link

```zsh
ls -l ~/.zshrc
readlink ~/.zshrc
```

`ls -l` shows that `.zshrc` is a symlink and displays its stored destination. `readlink` prints that stored destination alone. Stow normally creates a relative destination, so output such as `dotfiles/zsh/.zshrc` is expected.

On macOS versions that provide `realpath`, this resolves the complete path:

```zsh
command -v realpath
realpath ~/.zshrc
```

Run the second command only if the first prints a command path. `realpath` should print the canonical path ending in `/dotfiles/zsh/.zshrc`. Do not use `readlink -f` as a supposedly universal macOS command; BSD/macOS `readlink` compatibility has historically differed from GNU `readlink`.

Verify identity without modifying the file:

```zsh
cmp ~/.zshrc ~/dotfiles/zsh/.zshrc
```

`cmp` is silent when the two paths resolve to identical bytes. Its silence is meaningful but not very visible, so inspect its exit status immediately:

```zsh
print $?
```

In zsh, `$?` is the exit status of the preceding command. `0` means the contents matched.

### 6.5 Verify zsh still works

First parse the file without executing it:

```zsh
zsh -n ~/.zshrc
print $?
```

`-n` parses commands without executing them. Exit status `0` means zsh found no syntax error; it does not prove every runtime dependency exists.

Then start a fresh interactive zsh:

```zsh
exec zsh
```

`exec` replaces the current shell process with a new zsh, so there is no old shell to return to with `exit`. Confirm the expected prompt, aliases, completion, and key bindings. If replacing the current shell is undesirable, open a new terminal tab instead.

### 6.6 Commit the working package

```zsh
cd ~/dotfiles
git status --short
git add zsh/.zshrc
git diff --staged
git commit -m "Manage zsh configuration with Stow"
```

The `--` in `git diff -- zsh/.zshrc` ends Git’s option parsing and makes the remainder unambiguously a path. The staged diff is the final inspection before committing.

Only after the commit and successful zsh test should the temporary backup be removed. Deleting it is optional; if retained, keep it outside the repository and protect it like any other configuration copy.

## 7. Migrate the existing Neovim configuration

The directory shape matters: the package must contain `.config/nvim`, because the target is `$HOME` and Neovim expects `$HOME/.config/nvim` on macOS in this setup.

### 7.1 Inspect the existing directory

```zsh
ls -ld ~/.config ~/.config/nvim
find ~/.config/nvim -maxdepth 2 -type f -print
```

`ls -d` lists the directories themselves rather than their contents; `-l` shows detailed type and link information. The `find` command prints regular files no deeper than two levels below the Neovim directory. `-maxdepth 2` is supported by the GNU `find` Todd installs through Homebrew; stock BSD `find` on macOS does not provide GNU `-maxdepth`.

For a stock-macOS-only inspection, use:

```zsh
find ~/.config/nvim -type f -print
```

That may print more files, but it avoids GNU-specific options.

If `~/.config/nvim` is already a symlink, resolve it before proceeding.

An optional recursive backup can be made outside the repository:

```zsh
cp -R ~/.config/nvim ~/.config/nvim.pre-stow-backup
ls -ld ~/.config/nvim.pre-stow-backup
```

`-R` copies the directory recursively. This can be large if the existing directory improperly contains caches or downloaded plugins; inspect it first.

### 7.2 Create the package shape and move the directory

```zsh
mkdir -p ~/dotfiles/nvim/.config
mv ~/.config/nvim ~/dotfiles/nvim/.config/nvim
```

This preserves the entire working Neovim tree. The ordinary `~/.config` directory remains in place for other applications.

Inspect the source and target paths:

```zsh
ls -ld ~/dotfiles/nvim/.config/nvim
ls -ld ~/.config/nvim
```

The repository path should exist; the normal Neovim path should not. Before stowing, the reversible rollback is:

```zsh
mv ~/dotfiles/nvim/.config/nvim ~/.config/nvim
```

### 7.3 Simulate and create the Neovim link

```zsh
cd ~/dotfiles
stow --simulate --verbose nvim
```

Confirm that Stow proposes paths underneath `$HOME/.config`, not `$HOME/nvim` and not `~/dotfiles/.config`.

Then perform the operation:

```zsh
stow --verbose nvim
```

Because `~/.config` already exists, Stow normally descends into it and creates a link for `nvim`. If the target tree has a different shape, Stow may create fewer, higher-level links through its normal tree-folding behavior. Inspect the result rather than assuming its granularity.

### 7.4 Inspect Neovim ownership

```zsh
ls -ld ~/.config/nvim
readlink ~/.config/nvim
```

If available:

```zsh
realpath ~/.config/nvim
realpath ~/.config/nvim/init.lua
```

The resolved paths should lead into `~/dotfiles/nvim/.config/nvim`.

If Stow linked individual children instead of the whole `nvim` directory, `readlink ~/.config/nvim` will produce no destination because `nvim` itself is a real directory. In that case inspect a known child:

```zsh
ls -l ~/.config/nvim
readlink ~/.config/nvim/init.lua
```

Stow’s job is the resulting filesystem view, not a promise that every machine will have an identical number of symlinks.

### 7.5 Verify Neovim still works

Ask Neovim where it believes its configuration directory is:

```zsh
nvim --headless '+lua print(vim.fn.stdpath("config"))' +qa
```

`--headless` runs without the interactive UI. The quoted arguments are Ex commands: the first prints Neovim’s computed config path, and `+qa` quits all windows. The output should be `~/.config/nvim` expressed as an absolute path.

Then launch Neovim normally:

```zsh
nvim
```

Verify the same configuration, plugins, key mappings, colors, and expected health checks that worked before migration. This is not the moment to update plugins or change the config; isolate the migration from unrelated changes.

### 7.6 Commit the working package

```zsh
cd ~/dotfiles
git status --short
git add nvim
git diff --staged
git commit -m "Manage Neovim configuration with Stow"
```

At this point both applications use their old paths, both real configurations live in Git, and both package migrations have independent commits.

## 8. Understand what happens when editing a linked path

After migration, opening either of these:

```zsh
nvim ~/.zshrc
nvim ~/.config/nvim/init.lua
```

edits the repository-backed file. The operating system follows the symlink before Neovim opens the destination. There is not a second copy under `$HOME` waiting to be synchronized.

For `.zshrc`, the path traversal is:

```text
~/.zshrc
   │ symlink
   ▼
~/dotfiles/zsh/.zshrc
   │
   └── real file tracked by Git
```

For Neovim, the directory itself may be the link:

```text
~/.config/nvim/
   │ symlinked directory
   ▼
~/dotfiles/nvim/.config/nvim/
   │
   └── real files tracked by Git
```

That is why an edit made through the familiar home-directory path appears immediately in `git status` inside `~/dotfiles`.

## 9. Determine what actual file is being edited

When ownership is unclear, trace the path instead of guessing.

### A single file such as `.zshrc`

```zsh
ls -l ~/.zshrc
readlink ~/.zshrc
realpath ~/.zshrc
```

- `ls -l` distinguishes a regular file from a symlink and shows the stored target.
- `readlink` prints the immediate stored target and does not necessarily make it absolute.
- `realpath` resolves the chain to a canonical path when that command is available.

Expected final ownership:

```text
~/.zshrc -> ~/dotfiles/zsh/.zshrc
```

### A nested configuration such as Neovim

Check every useful level because a parent directory may be the link:

```zsh
ls -ld ~/.config
ls -ld ~/.config/nvim
ls -l ~/.config/nvim/init.lua
realpath ~/.config/nvim/init.lua
```

If `~/.config/nvim` is a symlink, `init.lua` can look like an ordinary file in a normal listing even though the parent directory redirects the traversal.

### Ask the application

For Neovim:

```vim
:lua print(vim.fn.stdpath("config"))
:verbose edit $MYVIMRC
```

The first prints the configured directory Neovim uses. The second opens the startup file and, through `:verbose`, can provide useful sourcing context.

For zsh, inspect the startup environment:

```zsh
print -r -- "ZDOTDIR=${ZDOTDIR:-$HOME}"
```

`print -r` prints raw text without interpreting backslash escapes. `--` ends option parsing. `${ZDOTDIR:-$HOME}` means “use `ZDOTDIR` if it is set and non-empty; otherwise use `$HOME`.” If `ZDOTDIR` is set, zsh looks there for `.zshrc` rather than assuming the home directory.

## 10. Connect a remote repository

Before creating the remote, read the [security section](#security-secrets-and-git-history). A private repository reduces exposure but does not make committed secrets safe.

Create an empty remote repository with the hosting service of choice. Do not initialize that remote with a README, license, or `.gitignore` when the local repository already contains commits; an actually empty remote makes the first push straightforward.

Then connect it:

```zsh
cd ~/dotfiles
git remote add origin <REMOTE-URL>
git remote -v
```

Replace `<REMOTE-URL>` with the SSH or HTTPS clone URL. `origin` is the conventional local name for the primary remote. `git remote -v` prints fetch and push URLs for inspection.

Push the branch:

```zsh
git push -u origin main
```

`-u`, short for `--set-upstream`, records `origin/main` as the upstream for local `main`. Later `git push` and `git pull` can use that relationship without repeating the remote and branch.

Verify:

```zsh
git status
git branch -vv
```

`git branch -vv` shows local branches and their upstream relationships.

## 11. Normal daily workflow

Edit through either the familiar application path or the repository path:

```zsh
nvim ~/.zshrc
```

Then review and publish deliberately:

```zsh
cd ~/dotfiles
git status --short
git diff
git add zsh/.zshrc
git diff --staged
git commit -m "Describe the zsh change"
git push
```

The inspection stages mean:

| Command | Question answered |
| --- | --- |
| `git status --short` | Which tracked, modified, staged, or untracked paths exist? |
| `git diff` | What unstaged content changed? |
| `git diff --staged` | Exactly what will the next commit contain? |
| `git log --oneline --decorate --graph -n 15` | What are the recent commits and branch pointers? |
| `git show --stat HEAD` | Which files changed in the latest commit? |
| `git show HEAD` | What patch is in the latest commit? |

For the log command, `--oneline` condenses each commit, `--decorate` shows branch/tag names, `--graph` draws branch topology, and `-n 15` limits output to fifteen commits.

### When is `stow --restow` needed?

Ordinary edits to the contents of an existing linked file require no Stow command. The symlink already points to the real file.

Use restow after changing package structure—for example, renaming or removing a tracked path—so obsolete target links are pruned and the current package tree is linked again:

```zsh
cd ~/dotfiles
stow --simulate --verbose --restow nvim
stow --verbose --restow nvim
```

`--restow`, equivalent to `-R`, first unstows and then stows the named package.

## 12. Pull changes onto an existing machine

Before pulling, inspect local work:

```zsh
cd ~/dotfiles
git status --short
git fetch
git log --oneline --decorate --graph HEAD..origin/main
git diff HEAD...origin/main
```

`git fetch` updates remote-tracking information without modifying working files. `HEAD..origin/main` asks the log for commits reachable from the remote branch but not the current commit. In `git diff HEAD...origin/main`, three dots compare the merge base with `origin/main`, showing the work introduced on that side since the histories diverged.

If the working tree is clean and the fetched changes are expected:

```zsh
git pull --ff-only
```

`--ff-only` allows the pull only when the local branch can move forward without creating a merge commit. If both machines made commits, it stops and forces a deliberate reconciliation instead of inventing a merge policy.

Content edits take effect immediately through existing links. If the pull changed package paths, simulate and restow the affected package:

```zsh
stow --simulate --verbose --restow nvim
stow --verbose --restow nvim
```

Verify the affected application after pulling.

## 13. Bootstrap a fresh Mac

This procedure assumes the remote has already been reviewed for secrets and the new Mac does not contain irreplaceable configuration at the target paths.

### 13.1 Install prerequisites

Install Homebrew through its official instructions, then:

```zsh
brew install git stow neovim
```

The arguments name three Homebrew formulae. Installing Neovim here is appropriate only if the repository’s configuration expects the Homebrew build; preserve any deliberate existing installation choice.

Install any external commands referenced by the existing zsh or Neovim configuration separately. Stow deploys configuration; it does not install the programs that configuration invokes. Todd’s macOS setup may also use Homebrew GNU tools such as `coreutils`, `findutils`, `grep`, `gnu-sed`, and `gawk`, but those are dependencies only when the actual configuration relies on them. Do not install a giant toolchain blindly.

### 13.2 Inspect existing target paths

Before cloning or stowing:

```zsh
ls -l ~/.zshrc
ls -ld ~/.config ~/.config/nvim
```

If either configuration already exists, do not run Stow over it. Compare it, back it up, and resolve ownership using the conflict procedure below.

### 13.3 Clone into the expected Stow directory

```zsh
git clone <REMOTE-URL> ~/dotfiles
cd ~/dotfiles
git status
```

`git clone` creates `~/dotfiles`, configures `origin`, downloads repository history, and checks out the remote’s default branch. Cloning into an existing non-empty directory is not allowed.

Review before linking:

```zsh
git log --oneline --decorate --graph -n 15
find . -maxdepth 3 -type f -print
```

The shown `find -maxdepth` form requires GNU `find`. With stock macOS `find`, omit `-maxdepth 3`.

### 13.4 Simulate one package at a time

```zsh
stow --simulate --verbose zsh
stow --verbose zsh
ls -l ~/.zshrc
zsh -n ~/.zshrc
```

Open a fresh zsh and verify it. Only then continue:

```zsh
stow --simulate --verbose nvim
stow --verbose nvim
ls -ld ~/.config/nvim
nvim
```

The package-by-package rule matters just as much during bootstrap as during initial migration.

## 14. Stow conflicts and safe resolution

### What happens when a target already exists?

If Stow needs to create a link where an unrelated ordinary file already exists, it reports a conflict and refuses the operation. This is a safety feature. Stow does not overwrite the file by default.

A typical cause is this duplication:

```text
~/dotfiles/zsh/.zshrc    # repository copy
~/.zshrc                 # independent ordinary file
```

There are now two real files. Stow cannot know which one should win.

### Safe conflict procedure

1. **Stop. Do not delete either copy.**
2. Identify both filesystem types and resolve any links.
3. Compare contents.
4. Decide which content is authoritative.
5. Preserve the other copy as a named backup or merge intentional differences.
6. Move the independent target out of the way.
7. Simulate Stow again.
8. Stow, inspect, test, and commit any merged change.

For `.zshrc`:

```zsh
ls -l ~/.zshrc ~/dotfiles/zsh/.zshrc
diff -u ~/dotfiles/zsh/.zshrc ~/.zshrc
```

`diff -u` produces a unified diff, with context, between the repository copy and the independent home-directory copy. Its argument order determines which side is shown as removed versus added.

If the repository version is authoritative and the independent file must merely be preserved:

```zsh
mv ~/.zshrc ~/.zshrc.conflict-backup
cd ~/dotfiles
stow --simulate --verbose zsh
stow --verbose zsh
```

`mv` changes the independent file’s name; it does not delete it. After testing, inspect the backup and remove it only through a deliberate decision.

For a Neovim directory, compare recursively:

```zsh
diff -ru ~/dotfiles/nvim/.config/nvim ~/.config/nvim
```

`-r` compares directories recursively and `-u` uses unified output. Then rename the independent tree rather than erasing it:

```zsh
mv ~/.config/nvim ~/.config/nvim.conflict-backup
```

### Why this guide does not recommend `--adopt` for routine conflicts

Stow provides `--adopt`, but its documented purpose is to move an existing target file into the package’s corresponding location, thereby **altering the contents of the Stow directory**, and then proceed with stowing. If a package copy already exists, this can change the repository copy in a way that is easy to misunderstand.

It can be useful in an expert, Git-reviewed workflow, but it is not the safe default for onboarding. Explicit comparison and a reversible rename make the chosen source of truth obvious.

## 15. Unstow, restow, and package lifecycle

### Unstow a package

Simulate first:

```zsh
cd ~/dotfiles
stow --simulate --verbose --delete zsh
```

Then remove Stow-owned target links:

```zsh
stow --verbose --delete zsh
```

`--delete`, equivalent to `-D`, unstows the package. It removes links in the target tree that Stow owns. It does **not** delete `~/dotfiles/zsh` or remove the configuration from Git.

Short form:

```zsh
stow -D zsh
```

`-D` is the short spelling of `--delete`. The long spelling is clearer in scripts and documentation; the short spelling is convenient interactively.

After unstowing, `~/.zshrc` will normally be absent, so a new zsh will no longer load that package. The real file remains safely at `~/dotfiles/zsh/.zshrc`.

### Stow it again

```zsh
stow --verbose zsh
```

This recreates the links from the unchanged package tree.

### Restow after changing package shape

```zsh
stow --verbose --restow zsh
```

`--restow`, equivalent to `-R`, performs delete followed by stow. It is especially useful for pruning links to files that were removed or renamed inside a package.

Short form:

```zsh
stow -R zsh
```

### Remove a package from this machine without deleting its Git copy

```zsh
cd ~/dotfiles
stow --verbose --delete nvim
git status --short
```

The target links disappear, but `nvim/` remains tracked and `git status` should show no repository deletion. This is the correct operation when the package should remain available in Git but inactive on one machine.

Deleting the package directory from `~/dotfiles` is a separate Git/content decision. Do not confuse “unstow” with “erase.”

### Useful Stow command reference

Run these from `~/dotfiles` unless explicit paths are shown.

| Command | Effect |
| --- | --- |
| `stow zsh` | Stow the `zsh` package using default directory and target |
| `stow --simulate --verbose zsh` | Show proposed changes without making them |
| `stow -D zsh` | Unstow `zsh` |
| `stow --delete zsh` | Same operation, long spelling |
| `stow -R zsh` | Unstow and then stow `zsh` |
| `stow --restow zsh` | Same operation, long spelling |
| `stow --dir="$HOME/dotfiles" --target="$HOME" zsh` | Stow with explicit directory and target |
| `stow --version` | Print installed Stow version |
| `stow --help` | Print command syntax and options |

Stow also supports multiple package names in one invocation, but the migration and bootstrap procedures intentionally use one package at a time for isolation and verification.

## 16. What belongs in the repository

Good candidates are small, understandable, user-authored configuration files:

- `.zshrc` and related shell functions or completion configuration;
- Neovim Lua configuration;
- Git configuration that contains no credentials or machine-only identity;
- Starship configuration;
- small scripts intentionally maintained as source;
- platform-specific fragments with explicit names and includes.

Todd’s broader cross-platform organization can use separate packages such as:

```text
git/
git-macos/
git-wsl/
git-windows/
git-ignore/
```

The general pattern is a portable base plus small, explicit platform overlays—not conditionals and duplicated files everywhere. Only packages relevant to a machine need to be stowed there.

Poor candidates include:

- caches, logs, swap files, histories, and generated state;
- plugin downloads or build output that a package manager can recreate;
- the Neovim state/data/cache directories returned by `stdpath("state")`, `stdpath("data")`, or `stdpath("cache")`;
- entire application-support directories copied without understanding them;
- host keys, SSH private keys, password databases, or credential stores;
- machine-generated files that churn constantly;
- large binaries;
- configuration containing secrets.

Track the source that explains the setup, not every byte an application happens to create.

## 17. Security: secrets and Git history

### Never commit these

- passwords;
- API keys;
- authentication or refresh tokens;
- SSH private keys;
- cloud-provider credentials;
- private certificates or certificate keys;
- application login databases;
- machine-specific secrets;
- cookies, session exports, or credential-helper stores.

Do not copy all of `~/.ssh`, `~/.aws`, `~/.config`, `~/Library`, or a similar broad tree into a package. Select known configuration files deliberately.

### Private does not mean secret-safe

A private remote restricts who can access it today. It does not prevent:

- accidental sharing;
- account compromise;
- overly broad collaborator access;
- CI logs or backups retaining data;
- later changing repository visibility;
- secrets living indefinitely in clones and history.

Build the repository so it could be audited or shared without exposing credentials, even if the chosen remote is private.

### Git history preserves deleted secrets

Deleting a secret in a later commit removes it from the current checkout, not from earlier commits. Anyone with the history may still retrieve it.

If a secret is committed:

1. revoke or rotate it immediately;
2. remove it from the current tree;
3. determine where it was pushed or copied;
4. rewrite history with an appropriate supported tool if necessary;
5. coordinate replacement of all affected clones and remote references.

History rewriting does not make rotation optional. Once exposed, treat the old credential as compromised.

### Separate configuration from secrets

Preferred strategies:

- Keep secrets in the macOS Keychain or a dedicated secret manager.
- Source a local file that is explicitly ignored, such as `~/.config/zsh/secrets.zsh`, only if it exists.
- Commit an `.example` file containing placeholder names, never real values.
- Use environment variables supplied by a secure login/session mechanism.
- Split portable Git configuration from machine-specific identity or credential configuration.
- Stow only the shareable package; create the secret file independently on each machine with restrictive permissions.

An ignored local file is not automatically encrypted or backed up. `.gitignore` only tells Git not to add an untracked matching path by default.

### Inspect before every push

```zsh
git status --short
git diff
git diff --staged
git log --oneline --decorate -n 5
```

Also inspect all tracked paths periodically:

```zsh
git ls-files
```

`git ls-files` prints paths in Git’s index. Look for credentials, histories, private keys, `.env` files, database files, and unexpected application state.

Remember that `.gitignore` does not stop Git from tracking a file already committed. If an ordinary non-secret generated file was accidentally tracked, remove it from the index while retaining the working copy with:

```zsh
git rm --cached -- path/to/file
```

`--cached` removes the path from Git’s index but leaves the working-tree file. The `--` ends option parsing. This creates a staged deletion and does not erase the file from prior history. For an actual secret, rotate first and follow an incident/history-cleanup process.

## 18. Troubleshooting

### Stow refuses because a target already exists

Cause: an unrelated file or link already owns the desired target name.

Diagnosis:

```zsh
ls -l ~/.zshrc ~/dotfiles/zsh/.zshrc
diff -u ~/dotfiles/zsh/.zshrc ~/.zshrc
```

Resolution: compare, preserve both, choose the authoritative content, move the independent target to a backup name, simulate, then stow. Do not blindly delete the target and do not reach first for `--adopt`.

### A symlink points somewhere unexpected

```zsh
ls -l ~/.zshrc
readlink ~/.zshrc
realpath ~/.zshrc
```

A relative `readlink` result is normal. `realpath` shows where the complete chain resolves. If it resolves outside the intended package, do not edit or delete it until its owner is understood.

### The config worked before migration but not afterward

Check in order:

1. Does the normal application path exist?
2. Is it a valid link?
3. Does it resolve into the expected package?
4. Is the real file still present?
5. Does the application compute the expected config directory?
6. Did permissions or external dependencies change independently?

Commands:

```zsh
ls -l ~/.zshrc
realpath ~/.zshrc
ls -l ~/dotfiles/zsh/.zshrc
zsh -n ~/.zshrc
```

For Neovim:

```zsh
ls -ld ~/.config/nvim
realpath ~/.config/nvim
nvim --headless '+lua print(vim.fn.stdpath("config"))' +qa
```

If the links and real files are correct, the problem may be inside the application configuration rather than Stow. Keep those diagnoses separate.

### Wrong Stow target

Symptom: links appear beside `dotfiles`, inside the repository, or under another unexpected directory.

Check:

```zsh
pwd
stow --simulate --verbose --dir="$HOME/dotfiles" --target="$HOME" zsh
```

Use the explicit command to eliminate ambiguity. The desired target is `$HOME`.

### Stow was run from the wrong directory

Bare `stow zsh` interprets the current directory as the Stow directory. Fix the context:

```zsh
cd ~/dotfiles
pwd
stow --simulate --verbose zsh
```

Or use explicit `--dir` and `--target` from anywhere.

### Package directory has the wrong filesystem shape

Incorrect Neovim package:

```text
~/dotfiles/nvim/init.lua
```

With `$HOME` as target, that shape asks Stow to create `~/init.lua`.

Correct:

```text
~/dotfiles/nvim/.config/nvim/init.lua
```

Mentally remove `~/dotfiles/nvim/`; what remains must be the path relative to `$HOME`.

### Broken symlink

```zsh
ls -l ~/.zshrc
readlink ~/.zshrc
test -e ~/.zshrc
print $?
```

`test -e` succeeds when the path resolves to an existing object. Exit status `1` after `ls -l` showed a symlink indicates a likely broken destination.

Check whether the repository moved or the real file was renamed. Restore the expected repository path, or unstow using the original Stow directory and restow from the new intended location. Avoid manually recreating a link until the package layout is understood.

### Git says configuration changed unexpectedly

Because the normal config path resolves into the repository, an application, plugin updater, formatter, or manual edit may have changed tracked content.

```zsh
cd ~/dotfiles
git status --short
git diff
git diff --stat
```

`--stat` summarizes affected files and line counts. Do not discard the change until it has been identified. Generated files probably should be removed from the package and ignored; real configuration changes should be reviewed and committed or deliberately reverted.

### A file exists both in the repository and independently under `$HOME`

There are two sources of truth. Stow will normally report a conflict instead of choosing one. Use `diff`, preserve both, merge intentional differences, rename the independent target, and then stow. The goal is to end with one real file in the repository and one Stow-managed route to it.

### Neovim cannot find its config

```zsh
nvim --headless '+lua print(vim.fn.stdpath("config"))' +qa
ls -ld ~/.config/nvim
realpath ~/.config/nvim
ls -l ~/dotfiles/nvim/.config/nvim/init.lua
```

Confirm that Neovim’s computed config path matches the target layout. Also check whether `XDG_CONFIG_HOME` is set:

```zsh
print -r -- "${XDG_CONFIG_HOME:-not set}"
```

If set, it changes the base configuration directory. Do not relocate files until determining why it is set and whether that was part of the previously working setup.

### zsh loads a different startup file

zsh reads different files for login, interactive, and other shell modes. For the `.zshrc` path specifically, first inspect `ZDOTDIR`:

```zsh
print -r -- "ZDOTDIR=${ZDOTDIR:-$HOME}"
ls -l "${ZDOTDIR:-$HOME}/.zshrc"
```

The quoted parameter expansion chooses `ZDOTDIR` when set and otherwise `$HOME`, while keeping the resulting path a single argument.

Confirm the current shell and whether it is interactive:

```zsh
print -r -- "$SHELL"
[[ -o interactive ]] && print "interactive zsh" || print "non-interactive zsh"
```

`[[ -o interactive ]]` is a zsh conditional that tests the shell option. `&&` runs the next command on success; `||` runs the final command on failure. If another startup file sets `ZDOTDIR`, the effective `.zshrc` may not be `~/.zshrc`.

## 19. Portability to Linux and WSL

The Stow model is the same:

- choose a Stow directory, commonly `~/dotfiles`;
- use `$HOME` as the target;
- make every package mirror paths relative to `$HOME`;
- keep real files in Git;
- link only the packages appropriate for that environment.

The main differences are installation and platform-specific configuration:

- install `stow` with the distribution’s package manager rather than Homebrew;
- GNU userland tools are commonly native on Linux, while macOS ships BSD variants of several commands;
- paths, installed programs, clipboard commands, package-manager locations, and some shell initialization details differ;
- WSL is Linux for Stow/package layout purposes, but may need WSL-specific Git, clipboard, PATH, or interop configuration.

Do not solve portability by stuffing every operating-system difference into one giant `.zshrc`. A portable base package plus small explicit packages such as `git-macos` and `git-wsl` keeps ownership understandable.

When bootstrapping Linux or WSL, use the same one-package loop:

```text
inspect existing target
→ clone
→ simulate one package
→ stow it
→ inspect links
→ test the application
→ continue
```

## 20. Future work: Windows, PowerShell, and `tavish`

PowerShell support is deliberately not specified in this version.

Future documentation will cover Windows and PowerShell after the workflow is implemented and verified. Todd’s intended direction is a small `tavish` command providing simple Stow-like linking and unlinking behavior. Its command syntax, target rules, link type, conflict behavior, package layout, and safety guarantees are not yet defined here and must not be inferred from GNU Stow.

Until that work exists, this playbook covers macOS first and the same GNU Stow model on Linux/WSL at a high level.

## 21. Compact operational checklist

### Initial migration

```text
install and verify Stow
→ create ~/dotfiles and initialize Git
→ add and inspect .gitignore
→ inspect ~/.zshrc
→ move it into zsh/.zshrc
→ simulate stow zsh
→ stow zsh
→ inspect link and test zsh
→ commit
→ inspect ~/.config/nvim
→ move it into nvim/.config/nvim
→ simulate stow nvim
→ stow nvim
→ inspect link and test Neovim
→ commit
→ audit for secrets
→ connect remote and push
```

### Every later package

```text
inspect
→ preserve/move the working config
→ mirror its target-relative path in one package
→ simulate
→ stow with verbose output
→ trace the resulting links
→ test the owning application
→ review Git diff
→ commit
→ push
```

## References

Behavior and options in this guide were checked against current primary or packaged command documentation:

- [GNU Stow project and manual](https://www.gnu.org/software/stow/)
- [GNU Stow 2.4.1 manual page](https://man.archlinux.org/man/stow.8)
- [Homebrew `stow` formula](https://formulae.brew.sh/formula/stow)
- [Git documentation](https://git-scm.com/docs)
- [Git `init`](https://git-scm.com/docs/git-init), [`clone`](https://git-scm.com/docs/git-clone), [`diff`](https://git-scm.com/docs/git-diff), and [`push`](https://git-scm.com/docs/git-push) references
- [Current macOS/Xcode command manual index, including `readlink` and `realpath`](https://keith.github.io/xcode-man-pages/)

The locally installed manuals remain authoritative for the exact versions on a particular machine:

```zsh
man stow
git help <command>
man readlink
man realpath
```

Replace `<command>` with a Git subcommand such as `diff` or `push`. Angle brackets here mark a placeholder; do not type them literally.
