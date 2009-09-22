#! /usr/bin/env perl

use strict;
use warnings;
use Test::Deep;
use Test::More;
use Data::DPath 'dpath';
use Data::Dumper;
use Clone 'clone';
use Benchmark ':all', ':hireswallclock';

# local $Data::DPath::DEBUG = 1;

BEGIN {
        print "TAP Version 13\n";
        plan tests => 3;
	use_ok( 'Data::DPath' );
}

my $base_data = {
                 'parse_errors' => [
                                    'Bad plan.  You planned 6 tests but ran 8.'
                                   ],
                 'tests_run' => 8,
                 'version' => 13,
                 'exit' => 0,
                 'start_time' => '1236463400.25151',
                 'skip_all' => undef,
                 'lines' => [
                             {
                              'is_comment' => 0,
                              'has_skip' => 0,
                              'as_string' => 'TAP version 13',
                              'is_test' => 0,
                              'is_yaml' => 0,
                              'is_plan' => 0,
                              'is_actual_ok' => 0,
                              'is_unknown' => 0,
                              'has_todo' => 0,
                              'is_bailout' => 0,
                              'is_pragma' => 0,
                              'is_version' => 1,
                              'raw' => 'TAP version 13'
                             },
                             {
                              'is_comment' => 0,
                              'has_skip' => 0,
                              'as_string' => '1..6',
                              'is_test' => 0,
                              'is_yaml' => 0,
                              'is_plan' => 1,
                              'is_actual_ok' => 0,
                              'is_unknown' => 0,
                              'has_todo' => 0,
                              'is_bailout' => 0,
                              'is_pragma' => 0,
                              'is_version' => 0,
                              'raw' => '1..6'
                             },
                             {
                              'is_comment' => 0,
                              'is_yaml' => 0,
                              'is_plan' => 0,
                              'number' => '1',
                              'is_unknown' => 0,
                              'is_bailout' => 0,
                              'is_pragma' => 0,
                              'is_unplanned' => 0,
                              'as_string' => 'ok 1 - use Data::DPath;',
                              'has_skip' => 0,
                              'is_test' => 1,
                              '_children' => [
                                              {
                                               'is_comment' => 0,
                                               'has_skip' => 0,
                                               'as_string' => '   ---
     - name: \'Hash one\'
       value: 1
     - name: \'Hash two\'
       value: 2
   ...',
                                               'is_test' => 0,
                                               'is_yaml' => 1,
                                               'is_plan' => 0,
                                               'data' => [
                                                          {
                                                           'value' => '1',
                                                           'name' => 'Hash one'
                                                          },
                                                          {
                                                           'value' => '2',
                                                           'name' => 'Hash two'
                                                          }
                                                         ],
                                               'is_actual_ok' => 0,
                                               'is_unknown' => 0,
                                               'has_todo' => 0,
                                               'is_bailout' => 0,
                                               'is_pragma' => 0,
                                               'is_version' => 0,
                                               'raw' => '   ---
     - name: \'Hash one\'
       value: 1
     - name: \'Hash two\'
       value: 2
   ...'
                                              }
                                             ],
                              'is_actual_ok' => 0,
                              'description' => '- use Data::DPath;',
                              'is_ok' => 1,
                              'has_todo' => 0,
                              'explanation' => '',
                              'directive' => '',
                              'type' => 'test',
                              'is_version' => 0,
                              'raw' => 'ok 1 - use Data::DPath;'
                             },
                             {
                              'is_comment' => 0,
                              'is_yaml' => 0,
                              'is_plan' => 0,
                              'number' => '2',
                              'is_unknown' => 0,
                              'is_bailout' => 0,
                              'is_pragma' => 0,
                              'is_unplanned' => 0,
                              'as_string' => 'ok 2 - KEYs + PARENT',
                              'has_skip' => 0,
                              'is_test' => 1,
                              'is_actual_ok' => 0,
                              'description' => '- KEYs + PARENT',
                              'is_ok' => 1,
                              'has_todo' => 0,
                              'explanation' => '',
                              'directive' => '',
                              'type' => 'test',
                              'is_version' => 0,
                              'raw' => 'ok 2 - KEYs + PARENT'
                             },
                             {
                              'is_comment' => 0,
                              'is_yaml' => 0,
                              'is_plan' => 0,
                              'number' => '3',
                              'is_unknown' => 0,
                              'is_bailout' => 0,
                              'is_pragma' => 0,
                              'is_unplanned' => 0,
                              'as_string' => 'ok 3 - quoted KEY containg slash',
                              'has_skip' => 0,
                              'is_test' => 1,
                              'is_actual_ok' => 0,
                              'description' => '- quoted KEY containg slash',
                              'is_ok' => 1,
                              'has_todo' => 0,
                              'explanation' => '',
                              'directive' => '',
                              'type' => 'test',
                              'is_version' => 0,
                              'raw' => 'ok 3 - quoted KEY containg slash'
                             },
                             {
                              'is_comment' => 0,
                              'has_skip' => 0,
                              'as_string' => 'pragma +strict',
                              'is_test' => 0,
                              'is_yaml' => 0,
                              'is_plan' => 0,
                              'is_actual_ok' => 0,
                              'is_unknown' => 0,
                              'has_todo' => 0,
                              'is_bailout' => 0,
                              'is_pragma' => 1,
                              'is_version' => 0,
                              'raw' => 'pragma +strict'
                             },
                             {
                              'is_comment' => 0,
                              'is_yaml' => 0,
                              'is_plan' => 0,
                              'number' => '4',
                              'is_unknown' => 0,
                              'is_bailout' => 0,
                              'is_pragma' => 0,
                              'is_unplanned' => 0,
                              'as_string' => 'not ok 4 # TODO spec only',
                              'has_skip' => 0,
                              'is_test' => 1,
                              '_children' => [
                                              {
                                               'is_comment' => 1,
                                               'has_skip' => 0,
                                               'as_string' => '#   Failed (TODO) test at t/data_dpath.t line 144.',
                                               'is_test' => 0,
                                               'is_yaml' => 0,
                                               'is_plan' => 0,
                                               'is_actual_ok' => 0,
                                               'is_unknown' => 0,
                                               'has_todo' => 0,
                                               'is_bailout' => 0,
                                               'is_pragma' => 0,
                                               'is_version' => 0,
                                               'raw' => '#   Failed (TODO) test at t/data_dpath.t line 144.'
                                              },
                                              {
                                               'is_comment' => 1,
                                               'has_skip' => 0,
                                               'as_string' => '#     Structures begin differing at:',
                                               'is_test' => 0,
                                               'is_yaml' => 0,
                                               'is_plan' => 0,
                                               'is_actual_ok' => 0,
                                               'is_unknown' => 0,
                                               'has_todo' => 0,
                                               'is_bailout' => 0,
                                               'is_pragma' => 0,
                                               'is_version' => 0,
                                               'raw' => '#     Structures begin differing at:'
                                              },
                                              {
                                               'is_comment' => 1,
                                               'has_skip' => 0,
                                               'as_string' => '#          $got->[0] = Does not exist',
                                               'is_test' => 0,
                                               'is_yaml' => 0,
                                               'is_plan' => 0,
                                               'is_actual_ok' => 0,
                                               'is_unknown' => 0,
                                               'has_todo' => 0,
                                               'is_bailout' => 0,
                                               'is_pragma' => 0,
                                               'is_version' => 0,
                                               'raw' => '#          $got->[0] = Does not exist'
                                              },
                                              {
                                               'is_comment' => 1,
                                               'has_skip' => 0,
                                               'as_string' => '#     $expected->[0] = ARRAY(0x8e4c238)',
                                               'is_test' => 0,
                                               'is_yaml' => 0,
                                               'is_plan' => 0,
                                               'is_actual_ok' => 0,
                                               'is_unknown' => 0,
                                               'has_todo' => 0,
                                               'is_bailout' => 0,
                                               'is_pragma' => 0,
                                               'is_version' => 0,
                                               'raw' => '#     $expected->[0] = ARRAY(0x8e4c238)'
                                              }
                                             ],
                              'is_actual_ok' => 0,
                              'description' => '',
                              'is_ok' => 1,
                              'has_todo' => 1,
                              'explanation' => 'spec only',
                              'directive' => 'TODO',
                              'type' => 'test',
                              'is_version' => 0,
                              'raw' => 'not ok 4 # TODO spec only'
                             },
                             {
                              'is_comment' => 0,
                              'is_yaml' => 0,
                              'is_plan' => 0,
                              'number' => '5',
                              'is_unknown' => 0,
                              'is_bailout' => 0,
                              'is_pragma' => 0,
                              'is_unplanned' => 0,
                              'as_string' => 'ok 5 - ANYWHERE + KEY + FILTER int # TODO spec only',
                              'has_skip' => 0,
                              'is_test' => 1,
                              'is_actual_ok' => 1,
                              'description' => '- ANYWHERE + KEY + FILTER int',
                              'is_ok' => 1,
                              'has_todo' => 1,
                              'explanation' => 'spec only',
                              'directive' => 'TODO',
                              'type' => 'test',
                              'is_version' => 0,
                              'raw' => 'ok 5 - ANYWHERE + KEY + FILTER int # TODO spec only'
                             },
                             {
                              'is_comment' => 0,
                              'is_yaml' => 0,
                              'is_plan' => 0,
                              'number' => '6',
                              'is_unknown' => 0,
                              'is_bailout' => 0,
                              'is_pragma' => 0,
                              'is_unplanned' => 0,
                              'as_string' => 'ok 6 # SKIP rethink twice',
                              'has_skip' => 1,
                              'is_test' => 1,
                              'is_actual_ok' => 0,
                              'description' => '',
                              'is_ok' => 1,
                              'has_todo' => 0,
                              'explanation' => 'rethink twice',
                              'directive' => 'SKIP',
                              'type' => 'test',
                              'is_version' => 0,
                              'raw' => 'ok 6 # skip rethink twice'
                             },
                             {
                              'is_comment' => 0,
                              'is_yaml' => 0,
                              'is_plan' => 0,
                              'number' => '7',
                              'is_unknown' => 0,
                              'is_bailout' => 0,
                              'is_pragma' => 0,
                              'is_unplanned' => 1,
                              'as_string' => 'not ok 7 # TODO spec only',
                              'has_skip' => 0,
                              'is_test' => 1,
                              '_children' => [
                                              {
                                               'is_comment' => 1,
                                               'has_skip' => 0,
                                               'as_string' => '#   Failed (TODO) test at t/data_dpath.t line 356.',
                                               'is_test' => 0,
                                               'is_yaml' => 0,
                                               'is_plan' => 0,
                                               'is_actual_ok' => 0,
                                               'is_unknown' => 0,
                                               'has_todo' => 0,
                                               'is_bailout' => 0,
                                               'is_pragma' => 0,
                                               'is_version' => 0,
                                               'raw' => '#   Failed (TODO) test at t/data_dpath.t line 356.'
                                              },
                                              {
                                               'is_comment' => 1,
                                               'has_skip' => 0,
                                               'as_string' => '#     Structures begin differing at:',
                                               'is_test' => 0,
                                               'is_yaml' => 0,
                                               'is_plan' => 0,
                                               'is_actual_ok' => 0,
                                               'is_unknown' => 0,
                                               'has_todo' => 0,
                                               'is_bailout' => 0,
                                               'is_pragma' => 0,
                                               'is_version' => 0,
                                               'raw' => '#     Structures begin differing at:'
                                              },
                                              {
                                               'is_comment' => 1,
                                               'has_skip' => 0,
                                               'as_string' => '#          $got->[0] = Does not exist',
                                               'is_test' => 0,
                                               'is_yaml' => 0,
                                               'is_plan' => 0,
                                               'is_actual_ok' => 0,
                                               'is_unknown' => 0,
                                               'has_todo' => 0,
                                               'is_bailout' => 0,
                                               'is_pragma' => 0,
                                               'is_version' => 0,
                                               'raw' => '#          $got->[0] = Does not exist'
                                              },
                                              {
                                               'is_comment' => 1,
                                               'has_skip' => 0,
                                               'as_string' => '#     $expected->[0] = \'interesting value\'',
                                               'is_test' => 0,
                                               'is_yaml' => 0,
                                               'is_plan' => 0,
                                               'is_actual_ok' => 0,
                                               'is_unknown' => 0,
                                               'has_todo' => 0,
                                               'is_bailout' => 0,
                                               'is_pragma' => 0,
                                               'is_version' => 0,
                                               'raw' => '#     $expected->[0] = \'interesting value\''
                                              }
                                             ],
                              'is_actual_ok' => 0,
                              'description' => '',
                              'is_ok' => 0,
                              'has_todo' => 1,
                              'explanation' => 'spec only',
                              'directive' => 'TODO',
                              'type' => 'test',
                              'is_version' => 0,
                              'raw' => 'not ok 7 # TODO spec only'
                             },
                             {
                              'is_comment' => 0,
                              'is_yaml' => 0,
                              'is_plan' => 0,
                              'number' => '8',
                              'is_unknown' => 0,
                              'is_bailout' => 0,
                              'is_pragma' => 0,
                              'is_unplanned' => 1,
                              'as_string' => 'ok 8 - FILTER eval regex # TODO too dirty, first cleanup _filter_eval',
                              'has_skip' => 0,
                              'is_test' => 1,
                              'is_actual_ok' => 1,
                              'description' => '- FILTER eval regex',
                              'is_ok' => 0,
                              'has_todo' => 1,
                              'explanation' => 'too dirty, first cleanup _filter_eval',
                              'directive' => 'TODO',
                              'type' => 'test',
                              'is_version' => 0,
                              'raw' => 'ok 8 - FILTER eval regex # TODO too dirty, first cleanup _filter_eval'
                             },
                            ],
                 'is_good_plan' => 0,
                 'has_problems' => 2,
                 'end_time' => '1236463400.25468',
                 'pragmas' => [
                               'strict'
                              ],
                 'plan' => '1..6',
                 'tests_planned' => 6
                };

my $resultlist;

# ---------- prepare ----------

my $path          = '//lines//description[ value =~ m(use Data::DPath) ]/../_children//data//name[ value eq "Hash two"]/../value';
my $expected      = "2";

$resultlist = [ dpath($path)->match($base_data) ];
# diag Dumper($resultlist);
cmp_deeply $resultlist, [ $expected ], "base_data";

SKIP: {
        skip "Set env DPATH_BENCHMARK=1 to enable benchmark", 1 unless $ENV{DPATH_BENCHMARK};

        diag "Running benchmark. Can take some time ...";
        my $huge_data;
        my $multi = 100;
        my @huge_expected = map   { $expected  }         1..$multi;
        $huge_data->{$_}  = clone ( $base_data ) foreach 1..$multi;
        my $count = 3;
        my $t = timeit ($count, sub { $resultlist = [ dpath($path)->match($huge_data) ] });
        my $n = $t->[5];
        my $throughput = $n / $t->[0];
        #diag Dumper($huge_data);
        # diag Dumper(\@huge_expected);
        # diag Dumper($resultlist);
        diag Dumper($t);
        cmp_deeply $resultlist, [ @huge_expected ], "huge_data";
        print "  ---\n";
        print "  benchmark:\n";
        print "    timestr:    ".timestr($t), "\n";
        print "    wallclock:  $t->[0]\n";
        print "    usr:        $t->[1]\n";
        print "    sys:        $t->[2]\n";
        print "    throughput: $throughput\n";
        print "  ...\n";

}
