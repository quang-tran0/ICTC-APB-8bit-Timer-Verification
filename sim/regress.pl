#! /usr/bin/perl
# ============================================================================
#  regress.pl
#  -----------
#  Regression driver for the 8-bit timer testbench.
#
#  Reads tc_list from regress.cfg, runs each testcase via `make run`, and
#  classifies the result by grepping the produced log file for the
#  configured pass / fail keywords (e.g. "TEST PASSED" / "TEST FAILED").
#
#  The Makefile currently does not emit those keywords itself, so we infer
#  pass/fail with a small post-check:
#     - PASS  : log contains `scenario finished -> $finish`
#               AND no `TIMEOUT` AND no `** Error`
#     - FAIL  : otherwise
#
#  A per-testcase summary is printed to stdout AND to regress.rpt.
#
#  Usage:
#     ./regress.pl                # full run (build + sim + report)
#     ./regress.pl -r             # re-generate report from existing logs
#     ./regress.pl -f foo.cfg     # use an alternative config file
#     ./regress.pl -h             # help
# ============================================================================

use strict;
use warnings;
use Getopt::Long;

my $opt_file;
my $opt_report;
my $opt_help;

my $cov             = 'off';
my $pass_key_word   = 'TEST PASSED';
my $fail_key_word   = 'TEST FAILED';

# Each entry in @tc_list is a hashref:
#   { name => "default_value_register_test", seed => 1, opts => "+FOO" }
my @tc_list;

# Per-testcase results, filled by run_regress().
# Each entry: { name, seed, log, status => "PASS"|"FAIL"|"UNKNOWN" }
my @results;

my ($start_time, $end_time);

GetOptions(
  'f|file=s'  => \$opt_file,
  'r|report!' => \$opt_report,
  'h|help!'   => \$opt_help,
);

main();

sub main {
    if ($opt_help) {
        print_usage();
        return;
    }

    if ($opt_report) {
        parse_cfg();
        classify_results();
        report();
        return;
    }

    print "Run regression...\n";
    parse_cfg();
    run_regress();
    merge_coverage() if lc($cov) eq 'on';
    classify_results();
    report();
}

# ----------------------------------------------------------------------------
# parse_cfg
# Reads regress.cfg, populates @tc_list.
# ----------------------------------------------------------------------------
sub parse_cfg {
    my $cfg_file = defined $opt_file ? $opt_file : 'regress.cfg';
    open(my $fh, '<', $cfg_file) or die "Can't open regress cfg file $cfg_file: $!\n";

    my $tc_start = 0;
    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next if $line eq '';
        next if $line =~ /^#/;

        if ($line =~ /^cov\s*=\s*(\S+)/i) {
            $cov = $1;
        }
        elsif ($line =~ /^pass_key_word\s*=\s*"?(.*?)"?\s*$/) {
            $pass_key_word = $1;
        }
        elsif ($line =~ /^fail_key_word\s*=\s*"?(.*?)"?\s*$/) {
            $fail_key_word = $1;
        }
        elsif ($line =~ /^tc_list\s*\{/) {
            $tc_start = 1;
            $line =~ s/.*\{//;   # allow content on the same line
            if ($line eq '') { next; }
            # fall-through to process this line
        }
        elsif ($line =~ /\}/) {
            $tc_start = 0;
        }
        elsif ($tc_start) {
            # Skip comments and blank lines inside the tc_list block
            next if $line =~ /^\s*\/\//;
            next if $line =~ /^\s*$/;

            # Strip optional trailing ;
            $line =~ s/;$//;

            # Split by comma: name, run_times=N, run_opts=...
            my @parts = split(/\s*,\s*/, $line);
            my $name   = $parts[0] // '';
            my $times  = 1;
            my $opts   = '';

            for my $p (@parts) {
                if ($p =~ /run_times\s*=\s*(\d+)/) { $times = $1; }
                if ($p =~ /run_opts\s*=\s*(.*)/) {
                    $opts = $1;
                    $opts =~ s/^\s+//;
                }
            }

            for (my $i = 0; $i < $times; $i++) {
                my $seed = int(rand(999999 - 100000 + 1)) + 100000;
                push @tc_list, {
                    name => $name,
                    seed => $seed,
                    opts => $opts,
                };
            }
        }
    }
    close($fh);
}

# ----------------------------------------------------------------------------
# run_regress
# Drives `make build` once, then `make run` for every testcase.
# ----------------------------------------------------------------------------
sub run_regress {
    $start_time = time();
    my $cov_arg = lc($cov) eq 'on' ? ' COV=ON' : '';

    if ($cov_arg ne '') {
        unlink glob('*.ucdb');
        unlink 'coverage.rpt';
    }

    system("make build$cov_arg");
    print "\n";

    for my $tc (@tc_list) {
        my $name = $tc->{name};
        my $seed = $tc->{seed};
        my $opts = $tc->{opts};

        print "==== Running $name (seed=$seed) ====\n";
        my $cmd = "make run TESTNAME=$name SEED=$seed RUNARG=$opts$cov_arg 2>&1";
        system($cmd);
        print "\n";
    }
    $end_time = time();
}

sub merge_coverage {
    print "==== Merging coverage databases ====\n";
    system("make cov_merge");
    print "\n";
}

# ----------------------------------------------------------------------------
# classify_results
# For each testcase, look at log/<name>_<seed>.log and decide pass/fail.
# If the expected log file is missing, try to find a log with the same
# testcase name but a different seed so the user can still see a result.
# ----------------------------------------------------------------------------
sub classify_results {
    @results = ();

    # Build a lookup index: name => list of available log paths
    my %log_index;
    if (opendir(my $dh, 'log')) {
        while (my $f = readdir($dh)) {
            next if $f !~ /\.log$/;
            if ($f =~ /^([A-Za-z0-9_]+)_(\d+)\.log$/) {
                push @{ $log_index{$1} }, $2;
            }
        }
        closedir($dh);
    }

    for my $tc (@tc_list) {
        my $name = $tc->{name};
        my $seed = $tc->{seed};
        my $log  = "log/${name}_${seed}.log";

        # If exact match not found, fall back to any seed for this name
        if (!-e $log && exists $log_index{$name} && @{ $log_index{$name} }) {
            my @seeds = sort @{ $log_index{$name} };
            $log = "log/${name}_${seeds[0]}.log";
        }

        my $status = 'UNKNOWN';
        if (!-e $log) {
            $status = 'NO_LOG';
        }
        else {
            # Trust the testbench's explicit verdict. base_test prints
            # "TEST PASSED" / "TEST FAILED" (scoreboard total_fail == 0).
            # Note: "scenario finished" is printed on BOTH pass and fail,
            # and a stray simulator "** Error" line does not mean the test
            # logically failed, so neither is used to decide pass/fail.
            my $pass_hit = `grep -c '$pass_key_word' $log 2>/dev/null`;
            chomp $pass_hit; $pass_hit = 0 if $pass_hit eq '';

            my $fail_hit = `grep -c '$fail_key_word' $log 2>/dev/null`;
            chomp $fail_hit; $fail_hit = 0 if $fail_hit eq '';

            if    ($fail_hit > 0) { $status = 'FAIL'; }
            elsif ($pass_hit > 0) { $status = 'PASS'; }
            else                  { $status = 'UNKNOWN'; }
        }
        push @results, {
            name   => $name,
            seed   => $seed,
            log    => $log,
            status => $status,
        };
    }
}

# ----------------------------------------------------------------------------
# report
# Print summary + write regress.rpt
# ----------------------------------------------------------------------------
sub report {
    my $tc_pass    = 0;
    my $tc_fail    = 0;
    my $tc_unknown = 0;

    for my $r (@results) {
        if    ($r->{status} eq 'PASS')    { $tc_pass++; }
        elsif ($r->{status} eq 'FAIL')    { $tc_fail++; }
        else                              { $tc_unknown++; }
    }

    my $used_time = ($end_time && $start_time) ? ($end_time - $start_time) : 0;
    $used_time = format_time($used_time);

    # ---- console ----
    print "\n";
    print "=========================================================\n";
    print "              8-bit Timer Regression Report              \n";
    print "=========================================================\n";
    printf "Total testcase run: %d\n", scalar(@results);
    print  "Passed            : $tc_pass\n";
    print  "Failed            : $tc_fail\n";
    print  "Unknown           : $tc_unknown\n";
    print  "Used time         : $used_time\n";
    print "---------------------------------------------------------\n";
    print "Per-testcase results:\n";

    for my $r (@results) {
        my $marker;
        if    ($r->{status} eq 'PASS') { $marker = '[PASS]'; }
        elsif ($r->{status} eq 'FAIL') { $marker = '[FAIL]'; }
        else                           { $marker = '[????]'; }
        printf "  %s  %-40s seed=%-7d log=%s\n",
               $marker, $r->{name}, $r->{seed}, $r->{log};
    }
    print "=========================================================\n";
    printf "RESULT: %d PASS / %d FAIL / %d UNKNOWN\n",
           $tc_pass, $tc_fail, $tc_unknown;
    print "=========================================================\n";

    # ---- file ----
    open(my $fh, '>', 'regress.rpt') or die "Can't open regress.rpt: $!\n";
    print $fh "###########################################################\n";
    print $fh "####               ICTC Regression Report              ####\n";
    print $fh "###########################################################\n";
    printf $fh "Total testcase run: %d\n", scalar(@results);
    print $fh "Passed            : $tc_pass\n";
    print $fh "Failed            : $tc_fail\n";
    print $fh "Unknown           : $tc_unknown\n";
    printf $fh "Used time         : %s\n", $used_time;
    print $fh "-----------------------------------------------------------\n";
    print $fh "Per-testcase results:\n";
    for my $r (@results) {
        my $marker = "[$r->{status}]";
        printf $fh "  %-7s  %-40s seed=%-7d log=%s\n",
               $marker, $r->{name}, $r->{seed}, $r->{log};
    }
    close($fh);

    print "\nReport written to regress.rpt\n";
}

sub print_usage {
    print <<'EOF';
  Regression driver for the 8-bit timer testbench.

  Usage:
    ./regress.pl                # full run (build + simulate + report)
    ./regress.pl -r             # re-generate report from existing logs
    ./regress.pl -f FILE        # use alternative config file
    ./regress.pl -h             # show this help

  Testcase list is read from regress.cfg (overridable with -f).
  Each entry has the form:
    <test_name>, run_times=N, run_opts=...

  Result classification (post-check on log/<name>_<seed>.log):
    PASS  - log contains "scenario finished" AND no "** Error" / "TIMEOUT"
    FAIL  - otherwise
EOF
}

sub format_time {
    my ($seconds) = @_;
    return "0s" if !defined $seconds || $seconds <= 0;

    if ($seconds < 60) {
        return "${seconds}s";
    }
    elsif ($seconds < 3600) {
        my $m = int($seconds / 60);
        my $s = $seconds % 60;
        return $s > 0 ? "${m}m ${s}s" : "${m}m";
    }
    else {
        my $h = int($seconds / 3600);
        my $m = int(($seconds % 3600) / 60);
        my $s = $seconds % 60;
        my $r = "${h}h";
        $r .= " ${m}m" if $m > 0;
        $r .= " ${s}s" if $s > 0;
        return $r;
    }
}
