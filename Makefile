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

RELEASEDIR=flooterbuck-$(shell cat VERSION)

SOURCES=ANSI.pl CTCP.pl Channel.pl DBM.pl Extras.pl HandleURLs.pl \
	Help.pl Irc.pl IrcExtras.pl IrcHooks.pl Misc.pl Norm.pl Params.pl \
	Process.pl Question.pl RDF.pl Reply.pl Search.pl Setup.pl Statement.pl \
	Update.pl User.pl Util.pm

SRC_FILES=$(shell for f in $(SOURCES);do echo $(SRCDIR)/$$f;done)

TARBALL=$(RELEASEDIR).tar.gz

default: ../$(TARBALL)

../$(RELEASEDIR):
	mkdir -p ../$(RELEASEDIR)
	tar cvf - $(PROGRAM) \
		$(wildcard $(MODULESDIR)/*.pm) \
		$(SRC_FILES) \
		$(DOCS) \
		$(CONFDIR)/*-dist $(CONFDIR)/sane-*.txt | \
		( cd ../$(RELEASEDIR) && tar xf - )

tarball: ../$(TARBALL)

../$(TARBALL): ../$(RELEASEDIR)
	cd .. ; tar cvvf - $(RELEASEDIR) | gzip -9 > $(TARBALL)
	# cd .. && rm -r $(RELEASEDIR)
