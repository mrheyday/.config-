#!/usr/bin/make -f

upstream = https://github.com/marlonrichert/.config.git
SHELL = /bin/zsh

# Include only the software that we want on all machines.
executables = aureliojargas/clitest ekalinin/github-markdown-toc
formulas := asciinema bat less micro pyenv
taps := services
ifeq (darwin,$(findstring darwin,$(shell print $$OSTYPE)))
taps += autoupdate cask cask-fonts cask-versions
formulas += bash coreutils
casks = karabiner-elements rectangle visual-studio-code
else ifeq (linux-gnu,$(shell print $$OSTYPE))
formulas += git grep
endif

zshenv = $(HOME)/.zshenv
sshconfig = $(HOME)/.ssh/config
dotfiles := $(zshenv) $(sshconfig)
ifeq (darwin,$(findstring darwin,$(shell print $$OSTYPE)))
terminal-plist = $(HOME)/Library/Preferences/com.apple.Terminal.plist
vscode-settings = $(HOME)/Library/ApplicationSupport/Code/User/settings.json
vscode-keybindings = $(HOME)/Library/ApplicationSupport/Code/User/keybindings.json
dotfiles += $(terminal-plist) $(vscode-settings) $(vscode-keybindings)
else ifeq (linux-gnu,$(shell print $$OSTYPE))
konsole = $(HOME)/.local/share/konsole
kxmlgui5 = $(HOME)/.local/share/kxmlgui5
dotfiles += $(konsole) $(kxmlgui5)
endif

XDG_DATA_HOME = $(HOME)/.local/share
zsh-datadir = $(XDG_DATA_HOME)/zsh/
zsh-hist = $(zsh-datadir)history
zsh-hist-old = $(HOME)/.zsh_history
zsh-cdr = $(zsh-datadir).chpwd-recent-dirs
zsh-cdr-old = $(HOME)/.chpwd-recent-dirs

prefix = /usr/local
ifeq (linux-gnu,$(shell print $$OSTYPE))
exec_prefix = /home/linuxbrew/.linuxbrew
else
exec_prefix = $(prefix)
endif
bindir = $(exec_prefix)/bin
datarootdir = $(prefix)/share
datadir = $(datarootdir)

BASH = /bin/bash
CURL = /usr/bin/curl
DEFAULTS = /usr/bin/defaults
OSASCRIPT = /usr/bin/osascript
PLUTIL = /usr/bin/plutil
DSCL = /usr/bin/dscl
APT = /usr/bin/apt
DCONF = /usr/bin/dconf
GETENT = /usr/bin/getent
GIO = /usr/bin/gio
SNAP = /usr/bin/snap
WGET = /usr/bin/wget

ifeq (linux-gnu,$(shell print $$OSTYPE))
GIT = $(bindir)/git
else
GIT = /usr/bin/git
endif
GITFLAGS = -q

ZSH = /bin/zsh
ZNAP = $(HOME)/Git/zsh-snap/znap.zsh

BREW = $(bindir)/brew
BREWFLAGS = -q
HOMEBREW_PREFIX = $(exec_prefix)
HOMEBREW_CELLAR = $(HOMEBREW_PREFIX)/Cellar
HOMEBREW_REPOSITORY = $(HOMEBREW_PREFIX)/Homebrew
tapsdir = $(HOMEBREW_REPOSITORY)/Library/Taps/homebrew
taps := $(taps:%=$(tapsdir)/homebrew-%)
formulas := $(formulas:%=$(HOMEBREW_CELLAR)/%)

PYENV_ROOT = $(HOME)/.pyenv
PYENV = $(bindir)/pyenv
PYENV_VERSION = 3.7.10
PYENVFLAGS =
PIP = $(PYENV_ROOT)/shims/pip
PIPFLAGS = -q
PIPX = $(HOME)/.local/bin/pipx
PIPXFLAGS =
PIPENV = $(HOME)/.local/bin/pipenv
ifeq (linux-gnu,$(shell print $$OSTYPE))
python-dependencies = bzip2 sqlite3 zlib1g-dev
endif

all: ibus terminal git git-config git-remote git-branch
	$(GIT) fetch $(GITFLAGS) -t upstream
	$(GIT) branch $(GITFLAGS) -u upstream/main main
	$(GIT) pull $(GITFLAGS) --autostash upstream > /dev/null
	@$(GIT) remote set-head upstream -a > /dev/null

ibus: FORCE
ifneq (,$(wildcard $(DCONF)))
	$(DCONF) dump /desktop/ibus/ > $(CURDIR)/ibus/dconf.txt
endif

terminal: FORCE
ifneq (,$(wildcard $(DCONF)))
	$(DCONF) dump /org/gnome/terminal/ > $(CURDIR)/terminal/dconf.txt
else ifneq (,$(wildcard $(PLUTIL)))
	$(PLUTIL) -extract 'Window Settings.Dark Mode' xml1 -o '$(CURDIR)/terminal/Dark Mode.terminal' $(HOME)/Library/Preferences/com.apple.Terminal.plist
endif

git-config: FORCE
	@$(GIT) config remote.pushdefault origin
	@$(GIT) config push.default current

git-remote: FORCE
ifneq ($(upstream),$(shell $(GIT) remote get-url upstream 2> /dev/null))
	@-$(GIT) remote add upstream $(upstream)
	@$(GIT) remote set-url upstream $(upstream)
endif

git-branch: FORCE
ifeq (,$(shell $(GIT) branch -l main))
	-$(GIT) branch $(GITFLAGS) -m master main
endif

backups := $(wildcard $(dotfiles:%=%~))
ifneq (,$(wildcard $(OSASCRIPT)))
find = ) (
replace = ), (
backups := $(subst $(find),$(replace),$(foreach f,$(backups),(POSIX file "$(f)")))
endif

clean: FORCE
ifneq (,$(backups))
ifneq (,$(wildcard $(OSASCRIPT)))
	$(OSASCRIPT) -e 'tell application "Finder" to delete every item of {$(backups)}' &> /dev/null || :
else ifneq (,$(wildcard $(GIO)))
	$(GIO) trash $(backups)
endif
endif

install: all installdirs dotfiles code konsole brew shell python

dotfiles: $(dotfiles:%=%~)
ifneq (,$(wildcard $(DEFAULTS)))
	$(DEFAULTS) write com.apple.Terminal 'Window Settings' -dict-add 'Dark Mode' "$( plutil -convert xml1 -o - '$(CURDIR)/terminal/Dark Mode.terminal' )"
	$(DEFAULTS) write com.apple.Terminal 'Default Window Settings' 'Dark Mode'
	$(DEFAULTS) write com.apple.Terminal 'Startup Window Settings' 'Dark Mode'
else ifneq (,$(wildcard $(DCONF)))
	$(DCONF) load /desktop/ibus/ < $(CURDIR)/ibus/dconf.txt
	$(DCONF) load /org/gnome/terminal/ < $(CURDIR)/terminal/dconf.txt
	$(foreach p,\
		$(filter-out list,$(shell $(DCONF) list /org/gnome/terminal/legacy/profiles:/)),\
		$(DCONF) write /org/gnome/terminal/legacy/profiles:/$(p)login-shell true;)
	$(foreach p,$(filter-out list,\
		$(shell $(DCONF) list /com/gexperts/Tilix/profiles/)),\
		$(DCONF) write /com/gexperts/Tilix/profiles:/$(p)login-shell true;)
endif
	ln -fns $(CURDIR)/zsh/.zshenv $(zshenv)
ifeq (darwin,$(findstring darwin,$(shell print $$OSTYPE)))
	ln -fns $(CURDIR)/ssh/config $(sshconfig)
	ln -fns $(CURDIR)/terminal/com.apple.Terminal.plist $(terminal-plist)
	ln -fns $(CURDIR)/vscode/settings.json $(vscode-settings)
	ln -fns $(CURDIR)/vscode/keybindings.json $(vscode-keybindings)
else ifeq (linux-gnu,$(shell print $$OSTYPE))
	ln -fns $(CURDIR)/konsole $(konsole)
	ln -fns $(CURDIR)/kxmlgui5 $(kxmlgui5)
endif
ifeq (,$(wildcard $(zsh-hist)))
ifneq (,$(wildcard $(zsh-hist-old)))
	mv $(zsh-hist-old) $(zsh-hist)
endif
endif
ifeq (,$(wildcard $(zsh-cdr)))
ifneq (,$(wildcard $(zsh-cdr-old)))
	mv $(zsh-cdr-old) $(zsh-cdr)
endif
endif

installdirs: FORCE
ifeq (darwin,$(findstring darwin,$(shell print $$OSTYPE)))
ifneq (,$(wildcard $(HOME)/Library/ApplicationSupport))
	$(OSASCRIPT) -e 'tell application "Finder" to delete every item of {(POSIX file "$(HOME)/Library/ApplicationSupport")}' &> /dev/null || :
endif
	ln -fns "$(HOME)/Library/Application Support" $(HOME)/Library/ApplicationSupport
endif
	mkdir -pm 0700 $(sort $(zsh-datadir) $(dir $(dotfiles)))

brew: $(formulas) $(casks) $(taps) brew-autoupdate
	HOMEBREW_NO_AUTO_UPDATE=1 $(BREW) autoremove $(BREWFLAGS)
	HOMEBREW_NO_AUTO_UPDATE=1 $(BREW) cleanup $(BREWFLAGS)

$(formulas): brew-upgrade
ifneq (,$(wildcard $@))
	HOMEBREW_NO_AUTO_UPDATE=1 $(BREW) install $(BREWFLAGS) --formula $(notdir $@)
endif

$(casks): $(tapsdir)/homebrew-cask
ifeq (darwin,$(findstring darwin,$(shell print $$OSTYPE)))
ifneq (,$(wildcard $@))
	HOMEBREW_NO_AUTO_UPDATE=1 $(BREW) install $(BREWFLAGS) --cask $@ 2> /dev/null
endif
endif

brew-autoupdate: $(tapsdir)/homebrew-autoupdate
ifeq (darwin,$(findstring darwin,$(shell print $$OSTYPE)))
	-HOMEBREW_NO_AUTO_UPDATE=1 $(BREW) autoupdate stop $(BREWFLAGS) > /dev/null
	HOMEBREW_NO_AUTO_UPDATE=1 $(BREW) autoupdate start $(BREWFLAGS) --cleanup --upgrade > /dev/null
endif

$(taps): brew-upgrade
ifneq (,$(wildcard $@))
	HOMEBREW_NO_AUTO_UPDATE=1 $(BREW) tap $(BREWFLAGS) $(subst homebrew-,homebrew/,$(notdir $@))
endif

brew-upgrade: $(BREW)
	$(BREW) update
	HOMEBREW_NO_AUTO_UPDATE=1 $(BREW) upgrade $(BREWFLAGS)

$(BREW):
	$(BASH) -c "$$( $(CURL) -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh )"

shell: shell-executables shell-change

shell-executables: $(ZNAP)
	source $(ZNAP) && znap install $(executables) > /dev/null

shell-change: FORCE
ifneq (,$(wildcard $(DSCL)))
ifneq (UserShell: $(SHELL),$(shell $(DSCL) . -read ~/ UserShell))
	chsh -s $(SHELL)
endif
else ifneq (,$(wildcard $(GETENT)))
ifneq ($(SHELL),$(findstring $(SHELL),$(shell $(GETENT) passwd $$LOGNAME)))
	chsh -s $(SHELL)
endif
endif

$(ZNAP):
	mkdir -pm 0700 $(abspath $(dir $@)..)
	$(GIT) -C $(abspath $(dir $@)..) clone $(GITFLAGS) --depth=1 https://github.com/marlonrichert/zsh-snap.git

python: python-pipenv

python-pipenv: python-pipenv-brew python-pipenv-pipx

python-pipenv-brew: FORCE
ifneq (,$(wildcard $(HOMEBREW_CELLAR)/pipenv))
	-HOMEBREW_NO_AUTO_UPDATE=1 $(BREW) uninstall $(BREWFLAGS) --formula pipenv
endif

python-pipenv-pipx: python-pipx
	$(PIPX) upgrade pipenv &> /dev/null || $(PIPX) install $(PIPXFLAGS) pipenv > /dev/null

python-pipx: python-pipx-brew python-pipx-pip

python-pipx-brew: FORCE
ifneq (,$(wildcard $(HOMEBREW_CELLAR)/pipx))
	-HOMEBREW_NO_AUTO_UPDATE=1 $(BREW) uninstall $(BREWFLAGS) --formula pipx
endif

python-pipx-pip: python-pip
	$(PIP) install $(PIPFLAGS) -U --user pipx

python-pip: python-pyenv
	$(PIP) install $(PIPFLAGS) -U pip

python-pyenv: $(HOMEBREW_CELLAR)/pyenv $(python-dependencies)
ifeq (,$(findstring $(PYENV_VERSION),$(shell $(PYENV) versions --bare)))
	@print '\e[5;31;40mCompiling Python $(PYENV_VERSION). This might take a while! Please stand by...\e[0m' && :
	PYENV_ROOT=$(PYENV_ROOT) $(PYENV) install $(PYENVFLAGS) -s $(PYENV_VERSION)
endif
	PYENV_ROOT=$(PYENV_ROOT) $(PYENV) global $(PYENV_VERSION)

konsole $(python-dependencies): FORCE
ifeq (linux-gnu,$(shell print $$OSTYPE))
ifneq (,$(shell $(APT) show $@ 2> /dev/null))
	sudo $(APT) install $@
endif
endif

code: FORCE
ifeq (linux-gnu,$(shell print $$OSTYPE))
ifneq (,$(shell $(SNAP) list code $@ 2> /dev/null))
	$(SNAP) list code &> /dev/null && $(SNAP) remove code
endif
	$(if command -v code > /dev/null,,\
	( TMPSUFFIX=.deb; sudo $(APT) install =( $(WGET) -ncv --show-progress -O - 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64' ) )\
	)
endif

$(dotfiles:%=%~): clean
	$(if $(wildcard $(@:%~=%)), mv $(@:%~=%) $@,)

.SUFFIXES:
FORCE:
