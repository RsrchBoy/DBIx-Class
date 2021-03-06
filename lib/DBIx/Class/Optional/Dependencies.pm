package DBIx::Class::Optional::Dependencies;

use warnings;
use strict;

use Carp;

# NO EXTERNAL NON-5.8.1 CORE DEPENDENCIES EVER (e.g. C::A::G)
# This module is to be loaded by Makefile.PM on a pristine system

# POD is generated automatically by calling _gen_pod from the
# Makefile.PL in $AUTHOR mode

my $moose_basic = {
  'Moose'                      => '0.98',
  'MooseX::Types'              => '0.21',
};

my $admin_basic = {
  %$moose_basic,
  'MooseX::Types::Path::Class' => '0.05',
  'MooseX::Types::JSON'        => '0.02',
  'JSON::Any'                  => '1.22',
  'namespace::autoclean'       => '0.09',
};

my $reqs = {
  dist => {
    #'Module::Install::Pod::Inherit' => '0.01',
  },

  replicated => {
    req => {
      %$moose_basic,
      'Hash::Merge'               => '0.12',
    },
    pod => {
      title => 'Storage::Replicated',
      desc => 'Modules required for L<DBIx::Class::Storage::DBI::Replicated>',
    },
  },

  admin => {
    req => {
      %$admin_basic,
    },
    pod => {
      title => 'DBIx::Class::Admin',
      desc => 'Modules required for the DBIx::Class administrative library',
    },
  },

  admin_script => {
    req => {
      %$moose_basic,
      %$admin_basic,
      'Getopt::Long::Descriptive' => '0.081',
      'Text::CSV'                 => '1.16',
    },
    pod => {
      title => 'dbicadmin',
      desc => 'Modules required for the CLI DBIx::Class interface dbicadmin',
    },
  },

  deploy => {
    req => {
      'SQL::Translator'           => '0.11006',
    },
    pod => {
      title => 'Storage::DBI::deploy()',
      desc => 'Modules required for L<DBIx::Class::Storage::DBI/deploy> and L<DBIx::Class::Storage::DBI/deploymen_statements>',
    },
  },


  test_pod => {
    req => {
      'Test::Pod'                 => '1.41',
    },
  },

  test_podcoverage => {
    req => {
      'Test::Pod::Coverage'       => '1.08',
      'Pod::Coverage'             => '0.20',
    },
  },

  test_notabs => {
    req => {
      'Test::NoTabs'              => '0.9',
    },
  },

  test_eol => {
    req => {
      'Test::EOL'                 => '0.6',
    },
  },

  test_cycle => {
    req => {
      'Test::Memory::Cycle'       => '0',
      'Devel::Cycle'              => '1.10',
    },
  },

  test_dtrelated => {
    req => {
      # t/36datetime.t
      # t/60core.t
      'DateTime::Format::SQLite'  => '0',

      # t/96_is_deteministic_value.t
      'DateTime::Format::Strptime'=> '0',

      # t/inflate/datetime_mysql.t
      # (doesn't need Mysql itself)
      'DateTime::Format::MySQL' => '0',

      # t/inflate/datetime_pg.t
      # (doesn't need PG itself)
      'DateTime::Format::Pg'  => '0',
    },
  },

  cdbicompat => {
    req => {
      'DBIx::ContextualFetch'     => '0',
      'Class::DBI::Plugin::DeepAbstractSearch' => '0',
      'Class::Trigger'            => '0',
      'Time::Piece::MySQL'        => '0',
      'Clone'                     => '0',
      'Date::Simple'              => '3.03',
    },
  },

  rdbms_pg => {
    req => {
      $ENV{DBICTEST_PG_DSN}
        ? (
          'Sys::SigAction'        => '0',
          'DBD::Pg'               => '2.009002',
        ) : ()
    },
  },

  rdbms_mysql => {
    req => {
      $ENV{DBICTEST_MYSQL_DSN}
        ? (
          'DBD::mysql'              => '0',
        ) : ()
    },
  },

  rdbms_oracle => {
    req => {
      $ENV{DBICTEST_ORA_DSN}
        ? (
          'DateTime::Format::Oracle' => '0',
        ) : ()
    },
  },

  rdbms_ase => {
    req => {
      $ENV{DBICTEST_SYBASE_DSN}
        ? (
          'DateTime::Format::Sybase' => 0,
        ) : ()
    },
  },

  rdbms_asa => {
    req => {
      (scalar grep { $ENV{$_} } (qw/DBICTEST_SYBASE_ASA_DSN DBICTEST_SYBASE_ASA_ODBC_DSN/) )
        ? (
          'DateTime::Format::Strptime' => 0,
        ) : ()
    },
  },

  rdbms_db2 => {
    req => {
      $ENV{DBICTEST_DB2_DSN}
        ? (
          'DBD::DB2' => 0,
        ) : ()
    },
  },

};


sub req_list_for {
  my ($class, $group) = @_;

  croak "req_list_for() expects a requirement group name"
    unless $group;

  my $deps = $reqs->{$group}{req}
    or croak "Requirement group '$group' does not exist";

  return { %$deps };
}


our %req_availability_cache;
sub req_ok_for {
  my ($class, $group) = @_;

  croak "req_ok_for() expects a requirement group name"
    unless $group;

  $class->_check_deps ($group) unless $req_availability_cache{$group};

  return $req_availability_cache{$group}{status};
}

sub req_missing_for {
  my ($class, $group) = @_;

  croak "req_missing_for() expects a requirement group name"
    unless $group;

  $class->_check_deps ($group) unless $req_availability_cache{$group};

  return $req_availability_cache{$group}{missing};
}

sub req_errorlist_for {
  my ($class, $group) = @_;

  croak "req_errorlist_for() expects a requirement group name"
    unless $group;

  $class->_check_deps ($group) unless $req_availability_cache{$group};

  return $req_availability_cache{$group}{errorlist};
}

sub _check_deps {
  my ($class, $group) = @_;

  my $deps = $class->req_list_for ($group);

  my %errors;
  for my $mod (keys %$deps) {
    if (my $ver = $deps->{$mod}) {
      eval "use $mod $ver ()";
    }
    else {
      eval "require $mod";
    }

    $errors{$mod} = $@ if $@;
  }

  if (keys %errors) {
    my $missing = join (', ', map { $deps->{$_} ? "$_ >= $deps->{$_}" : $_ } (sort keys %errors) );
    $missing .= " (see $class for details)" if $reqs->{$group}{pod};
    $req_availability_cache{$group} = {
      status => 0,
      errorlist => { %errors },
      missing => $missing,
    };
  }
  else {
    $req_availability_cache{$group} = {
      status => 1,
      errorlist => {},
      missing => '',
    };
  }
}

sub req_group_list {
  return { map { $_ => { %{ $reqs->{$_}{req} || {} } } } (keys %$reqs) };
}

# This is to be called by the author only (automatically in Makefile.PL)
sub _gen_pod {

  my $class = shift;
  my $modfn = __PACKAGE__ . '.pm';
  $modfn =~ s/\:\:/\//g;

  my $podfn = __FILE__;
  $podfn =~ s/\.pm$/\.pod/;

  my $distver =
    eval { require DBIx::Class; DBIx::Class->VERSION; }
      ||
    do {
      warn
"\n\n---------------------------------------------------------------------\n" .
'Unable to load core DBIx::Class module to determine current version, '.
'possibly due to missing dependencies. Author-mode autodocumentation ' .
"halted\n\n" . $@ .
"\n\n---------------------------------------------------------------------\n"
      ;
      '*UNKNOWN*';  # rv
    }
  ;

  my $sqltver = $class->req_list_for ('deploy')->{'SQL::Translator'}
    or die "Hrmm? No sqlt dep?";

  my @chunks = (
    <<"EOC",
#########################################################################
#####################  A U T O G E N E R A T E D ########################
#########################################################################
#
# The contents of this POD file are auto-generated.  Any changes you make
# will be lost. If you need to change the generated text edit _gen_pod()
# at the end of $modfn
#
EOC
    '=head1 NAME',
    "$class - Optional module dependency specifications (for module authors)",
    '=head1 SYNOPSIS',
    <<EOS,
Somewhere in your build-file (e.g. L<Module::Install>'s Makefile.PL):

  ...

  configure_requires 'DBIx::Class' => '$distver';

  require $class;

  my \$deploy_deps = $class->req_list_for ('deploy');

  for (keys %\$deploy_deps) {
    requires \$_ => \$deploy_deps->{\$_};
  }

  ...

Note that there are some caveats regarding C<configure_requires()>, more info
can be found at L<Module::Install/configure_requires>
EOS
    '=head1 DESCRIPTION',
    <<'EOD',
Some of the less-frequently used features of L<DBIx::Class> have external
module dependencies on their own. In order not to burden the average user
with modules he will never use, these optional dependencies are not included
in the base Makefile.PL. Instead an exception with a descriptive message is
thrown when a specific feature is missing one or several modules required for
its operation. This module is the central holding place for  the current list
of such dependencies, for DBIx::Class core authors, and DBIx::Class extension
authors alike.
EOD
    '=head1 CURRENT REQUIREMENT GROUPS',
    <<'EOD',
Dependencies are organized in C<groups> and each group can list one or more
required modules, with an optional minimum version (or 0 for any version).
The group name can be used in the
EOD
  );

  for my $group (sort keys %$reqs) {
    my $p = $reqs->{$group}{pod}
      or next;

    my $modlist = $reqs->{$group}{req}
      or next;

    next unless keys %$modlist;

    push @chunks, (
      "=head2 $p->{title}",
      "$p->{desc}",
      '=over',
      ( map { "=item * $_" . ($modlist->{$_} ? " >= $modlist->{$_}" : '') } (sort keys %$modlist) ),
      '=back',
      "Requirement group: B<$group>",
    );
  }

  push @chunks, (
    '=head1 METHODS',
    '=head2 req_group_list',
    '=over',
    '=item Arguments: $none',
    '=item Returns: \%list_of_requirement_groups',
    '=back',
    <<EOD,
This method should be used by DBIx::Class packagers, to get a hashref of all
dependencies keyed by dependency group. Each key (group name) can be supplied
to one of the group-specific methods below.
EOD

    '=head2 req_list_for',
    '=over',
    '=item Arguments: $group_name',
    '=item Returns: \%list_of_module_version_pairs',
    '=back',
    <<EOD,
This method should be used by DBIx::Class extension authors, to determine the
version of modules a specific feature requires in the B<current> version of
DBIx::Class. See the L</SYNOPSIS> for a real-world
example.
EOD

    '=head2 req_ok_for',
    '=over',
    '=item Arguments: $group_name',
    '=item Returns: 1|0',
    '=back',
    'Returns true or false depending on whether all modules required by C<$group_name> are present on the system and loadable',

    '=head2 req_missing_for',
    '=over',
    '=item Arguments: $group_name',
    '=item Returns: $error_message_string',
    '=back',
    <<EOD,
Returns a single line string suitable for inclusion in larger error messages.
This method would normally be used by DBIx::Class core-module author, to
indicate to the user that he needs to install specific modules before he will
be able to use a specific feature.

For example if some of the requirements for C<deploy> are not available,
the returned string could look like:

 SQL::Translator >= $sqltver (see $class for details)

The author is expected to prepend the necessary text to this message before
returning the actual error seen by the user.
EOD

    '=head2 req_errorlist_for',
    '=over',
    '=item Arguments: $group_name',
    '=item Returns: \%list_of_loaderrors_per_module',
    '=back',
    <<'EOD',
Returns a hashref containing the actual errors that occured while attempting
to load each module in the requirement group.
EOD
    '=head1 AUTHOR',
    'See L<DBIx::Class/CONTRIBUTORS>.',
    '=head1 LICENSE',
    'You may distribute this code under the same terms as Perl itself',
  );

  open (my $fh, '>', $podfn) or croak "Unable to write to $podfn: $!";
  print $fh join ("\n\n", @chunks);
  close ($fh);
}

1;
