#------------------------------------------------------------------------
# FOR DEVELOPER USE ONLY!
#
# If you're one of those adventurous souls running infobot via CVS, then
# please pay no attention to this Makefile!  It won't do you any good anyway.
#------------------------------------------------------------------------

DOCS=LICENSE README TODO REVISIONS

PROGRAM=infobot
MODULESDIR=modules
CONFDIR=conf
SRCDIR=src
SCRIPTDIR=scripts


CONFS=infobot.channels-dist infobot.config-dist infobot.help-dist \
	infobot.users-dist magic8.txt sane-are.txt sane-ignore.txt \
	sane-is.txt unittab.txt

SOURCES=ANSI.pl CTCP.pl Channel.pl DBM.pl Extras.pl HandleURLs.pl \
	Help.pl Irc.pl IrcExtras.pl IrcHooks.pl Misc.pl Norm.pl Params.pl \
	Process.pl Question.pl RDF.pl Reply.pl Search.pl Setup.pl Statement.pl \
	Update.pl User.pl Util.pm

SCRIPTS=README.scripts curl dbmext-test dump_db flock-test \
	get_entries_from_log hysteresis make_password make_snap \
	restore_snap run_if_needed.pl track2fact unupdate_dbs update_db

# computed variables
SRC_FILES=$(shell for f in $(SOURCES);do echo $(SRCDIR)/$$f;done)
CONF_FILES=$(shell for f in $(CONFS);do echo $(CONFDIR)/$$f;done)
SCRIPT_FILES=$(shell for f in $(SCRIPTS);do echo $(SCRIPTDIR)/$$f;done)
RELEASEDIR=flooterbuck-$(shell cat VERSION)
TAG=release-$(shell sed 's/\./-/g' VERSION)

TARBALL=$(RELEASEDIR).tar.gz

default: $(TARBALL)

../$(RELEASEDIR):
	mkdir -p ../$(RELEASEDIR)
	tar cvf - $(PROGRAM) \
		$(wildcard $(MODULESDIR)/*.pm) \
		$(SRC_FILES) \
		$(DOCS) \
		$(CONF_FILES) \
		$(SCRIPT_FILES) | \
		( cd ../$(RELEASEDIR) && tar xf - )

$(TARBALL): ../$(TARBALL)
	mv ../$(TARBALL) $(TARBALL)

tarball: ../$(TARBALL)

../$(TARBALL): ../$(RELEASEDIR)
	cd .. ; tar cvvf - $(RELEASEDIR) | gzip -9 > $(TARBALL)
	cd .. && rm -r $(RELEASEDIR)

release: tag tarball

tag:
	cd .. && cvs tag $(TAG) infobot CVSROOT webpage

untag:
	cd .. && cvs tag -d $(TAG) infobot CVSROOT webpage
