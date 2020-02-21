package Ubuntu::Releases;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       list_ubuntu_releases
               );

our %SPEC;

our $meta = {
    summary => 'Ubuntu releases',
    fields => {
        version         => { pos => 0, schema => "str*", sortable => 1, summary => "Version", unique => 1 },
        code_name       => { pos => 1, schema => "str*", sortable => 1, summary => "Code name", unique => 1 },
        animal          => { pos => 2, schema => "str*", sortable => 1, summary => "Code name", unique => 1 },
        reldate         => { pos => 3, schema => "date*", sortable => 1, summary => "Release date" },
        eoldate         => { pos => 4, schema => "date*", sortable => 1, summary => "Supported until" },

        linux_version   => {pos=> 5, schema=>'str*'},

        mysql_version        => {pos=> 6, schema=>'str*'},
        mariadb_version      => {pos=> 7, schema=>'str*'},
        postgresql_version   => {pos=> 8, schema=>'str*'},
        apache_httpd_version => {pos=> 9, schema=>'str*'},
        nginx_version        => {pos=>10, schema=>'str*'},

        perl_version         => {pos=>11, schema=>'str*'},
        python_version       => {pos=>12, schema=>'str*'},
        php_version          => {pos=>13, schema=>'str*'},
        ruby_version         => {pos=>14, schema=>'str*'},
        bash_version         => {pos=>15, schema=>'str*'},
    },
    pk => "version",
};

our $data = do {
    no warnings 'void';
    [];
# BEGIN_CODE

    # this code will be run by Dist::Zilla::Plugin::InsertCodeResult during
    # build and the result will be inserted to the source code, while the
    # original code will no longer be in the final built version.

    {
        use strict;
        use warnings;

        require File::Slurper;
        require JSON::MaybeXS;
        require Text::CSV_XS;

        # mapping of release name -> animal
        my %animal_for;
        for (@{ Text::CSV_XS::csv(in => "../gudangdata/table/ubuntu_release_animal/data.csv") }) {
            $animal_for{ $_->[0] } = $_->[1];
        }

        my $json = JSON::MaybeXS->new;
        my $rels = $json->decode(
            File::Slurper::read_binary("../gudangdata-distrowatch/table/ubuntu_release/data.json"));
        my $data = [];
        for my $rel (@$rels) {
            next if $rel->{release_name} =~ /^snapshot/;
            my ($ver, $code) = $rel->{release_name} =~ /\A(\d\S*?(?: LTS)?)([a-z].+)\z/
                or die "Can't extract code+ver from release_name '$rel->{release_name}'";
            my $animal = $animal_for{$code}
                or warn "Can't find out the animal for release codenamed $code";
            push @$data, {
                version=>$ver, code_name=>$code, animal=>$animal,
                reldate=>$rel->{release_date}, eoldate=>($rel->{eol_date} =~ /\xa0/ ? undef : $rel->{eol_date}),
                linux_version=>$rel->{linux_version},
                mysql_version=>$rel->{mysql_version},
                mariadb_version=>$rel->{mariadb_version},
                postgresql_version=>$rel->{postgresql_version},
                apache_httpd_version=>$rel->{httpd_version},
                nginx_version=>$rel->{nginx_version},
                perl_version=>$rel->{perl_version},
                python_version=>$rel->{python_version},
                php_version=>$rel->{php_version},
                ruby_version=>$rel->{ruby_version},
                bash_version=>$rel->{bash_version},
            };
        }
        $data;
    }
# END_CODE
};

my $res = gen_read_table_func(
    name => 'list_ubuntu_releases',
    table_data => $data,
    table_spec => $meta,
    #langs => ['en_US', 'id_ID'],
);
die "BUG: Can't generate func: $res->[0] - $res->[1]" unless $res->[0] == 200;

1;
# ABSTRACT: List Ubuntu releases

=head1 SYNOPSIS

 use Ubuntu::Releases;
 my $res = list_ubuntu_releases(detail=>1);
 # raw data is in $Ubuntu::Releases::data;


=head1 DESCRIPTION

This module contains list of Ubuntu releases. Data source is
currently at: L<https://github.com/sharyanto/gudangdata-distrowatch>
(table/redhat_release) which in turn is retrieved from
L<http://distrowatch.com>.


=head1 SEE ALSO

L<Debian::Releases>

=cut
