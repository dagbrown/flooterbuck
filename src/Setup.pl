
# infobot :: Kevin Lenzo   (c) 1997-2000

sub setup {
# param setup should stay after most of the requires
# so that it overrides anything they might set.
    &paramSetup();

    if ($param{VERBOSITY} > 1) {
        my $params = "Parameters are:\n";
        foreach (sort keys %param) {
            $params .= "   $_ -> $param{$_}\n";
        }
        &status($params);
    }

    die "dbname is null" if (!$param{'dbname'});

    %dbs = ("is" => "$param{basedir}/$param{dbname}-is",
            "are" => "$param{basedir}/$param{dbname}-are");
    srand();

    $setup_time = scalar(localtime());
    $setup_time =~ s/\n//g;

    $startTime = time();

    &openDBM(%dbs);

    $qCount = &get("is", "the qCount");
    $qEpochTime = &get("is", "the qEpochTime");

    # when i'm cofused and I have to reply
    @confused = ("huh?", 
            "what?", 
            "sorry...", 
            "i\'m not following you...",
            "excuse me?");

    # when i recognize a query but can't answer it
    @dunno = ('i don\'t know', 
            'wish i knew',
            'i haven\'t a clue',
            'no idea',
            'bugger all, i dunno');

    # check the ignore parameter for a filename containing the
    # ignore list

    if ($param{ignore}) {
        &openDBMx('ignore');
    }

    if ($param{sanePrefix}) {
        for $d (qw/is are/) {
            my $dbname = $DBprefix.$d;
            my $sane = "$param{confdir}/$param{sanePrefix}";
            $sane .= "-$d.txt";
            if (-e $sane) {
                &status("loading sane defines $sane");
                &insertFile($dbname, $sane);
            } else {
                &status("can't fine sane file $sane");
            }
        }

        if (! open IGNORE, "$param{'confdir'}/$param{sanePrefix}-ignore.txt") {
            &status("No fallback ignore file $param{'confdir'}/$param{sanePrefix}-ignore.txt");
        } else {
            while (<IGNORE>) {
                s/^\s+//;
                s/\s+\#.*//;
                chomp;
                /\S/ && do {
                    &postInc(ignore => $_);
                    if ($param{'VERBOSITY'} > 0) {
                        &status("Adding $_ to ignore list (from sane).");
                    }
                };
            }
            close IGNORE;
        }
    }

    if ($param{'plusplus'}) {
        &openDBMx('plusplus');
    }

    if ($param{'seen'}) {
        &openDBMx('seen');
    }
    
    if ($param{'topten'}) {
        &openDBMx('topten');
    }

    if ($param{'seenurls'}) {
        &openDBMx('seenurls');
    }

    # set up the users and ops
    &status("Parsing User File");
    &parseUserfile();

    &status("Parsing Channel File");
    # set up the channel file
    &parseChannelfile();

    $param{'maxKeySize'}  ||= 30; # maximum LHS length
        $param{'maxDataSize'} ||= 200; # maximum total length

        if (!defined(@verb)) {
            @verb = split(" ", "is are");
            #  am was were does has can wants needs feels
            #  handle s-v agreement for non-being verbs later
        }

    if (!defined(@qWord)) {
        @qWord = split(" ", "what where who"); # why how when
    }

    # do this ONCE per startup to amortize.  Still too much mem.
    #&getAllKeys;
    $isCount = &getDBMKeys('is'); 
    $areCount = &getDBMKeys('are');
    $factoidCount = $isCount + $areCount;

    &status("setup: $factoidCount factoids; $isCount IS; $areCount ARE");
}


sub paramSetup {
    my $initdebug = 1;
    $param{'DEBUG'} = $initdebug;

    my $defaultfile; 
    unless ($paramfile) {
	# if there is no list of param files, just go for the default
	# (usually ./files/infobot.config)

	$paramfile = "$param{confdir}/infobot.config";
        $defaultfile++;
    }

    if (! -e $paramfile) {
        if ($defaultfile) {
            die "Hey, this looks you're running this for the first time!\nPerhaps you should rename the -dist files in the conf/ subdirectory and\nedit them to your liking.\n"
        }
        else {
            die "Can't find specified configuration file $paramfile.\n"
        }
    }
    
    # now read in the parameter files
    &loadParamFiles($paramfile);
}


1;
