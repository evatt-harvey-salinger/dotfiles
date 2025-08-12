
# Set your identity (critical for collaboration)
git config --global user.name "Evatt Harvey-Salinger"
git config --global user.email "evatt.harvey-salinger@applied.co"

# Set the default branch name for new repositories to 'main'
git config --global init.defaultBranch main

# Make nvim my default editor
git config --global core.editor "nvim"

# Add some useful aliases to save typing
git config --global alias.st '!git fetch -q && git status .'
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit" 
