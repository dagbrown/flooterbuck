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


CONFS=infobot.channels-dist infobot.config-dist infobot.help-dist \
	infobot.users-dist magic8.txt sane-are.txt sane-ignore.txt \
	sane-is.txt unittab.txt

SOURCES=ANSI.pl CTCP.pl Channel.pl DBM.pl Extras.pl HandleURLs.pl \
	Help.pl Irc.pl IrcExtras.pl IrcHooks.pl Misc.pl Norm.pl Params.pl \
	Process.pl Question.pl RDF.pl Reply.pl Search.pl Setup.pl Statement.pl \
	Update.pl User.pl Util.pm

# computed variables
SRC_FILES=$(shell for f in $(SOURCES);do echo $(SRCDIR)/$$f;done)
CONF_FILES=$(shell for f in $(CONFS);do echo $(CONFDIR)/$$f;done)
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
		$(CONF_FILES) | \
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
