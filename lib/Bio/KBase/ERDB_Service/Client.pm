package Bio::KBase::ERDB_Service::Client;

use JSON::RPC::Client;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

Bio::KBase::ERDB_Service::Client

=head1 DESCRIPTION



=cut

sub new
{
    my($class, $url) = @_;

    my $self = {
	client => Bio::KBase::ERDB_Service::Client::RpcClient->new,
	url => $url,
    };
    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 GetAll

  $return = $obj->GetAll($objectNames, $filterClause, $parameters, $fields, $count)

=over 4

=item Parameter and return types

=begin html

<pre>
$objectNames is an objectNames
$filterClause is a filterClause
$parameters is a parameters
$fields is a fields
$count is a count
$return is a rowlist
objectNames is a string
filterClause is a string
parameters is a reference to a list where each element is a parameter
parameter is a string
fields is a string
count is an int
rowlist is a reference to a list where each element is a fieldValues
fieldValues is a reference to a list where each element is a fieldValue
fieldValue is a string

</pre>

=end html

=begin text

$objectNames is an objectNames
$filterClause is a filterClause
$parameters is a parameters
$fields is a fields
$count is a count
$return is a rowlist
objectNames is a string
filterClause is a string
parameters is a reference to a list where each element is a parameter
parameter is a string
fields is a string
count is an int
rowlist is a reference to a list where each element is a fieldValues
fieldValues is a reference to a list where each element is a fieldValue
fieldValue is a string


=end text

=item Description

Wrapper for the GetAll function documented <a href='http://pubseed.theseed.org/sapling/server.cgi?pod=ERDB#GetAll'>here</a>.
Note that the objectNames and fields arguments must be strings; array references are not allowed.

=back

=cut

sub GetAll
{
    my($self, @args) = @_;

    if ((my $n = @args) != 5)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function GetAll (received $n, expecting 5)");
    }
    {
	my($objectNames, $filterClause, $parameters, $fields, $count) = @args;

	my @_bad_arguments;
        (!ref($objectNames)) or push(@_bad_arguments, "Invalid type for argument 1 \"objectNames\" (value was \"$objectNames\")");
        (!ref($filterClause)) or push(@_bad_arguments, "Invalid type for argument 2 \"filterClause\" (value was \"$filterClause\")");
        (ref($parameters) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"parameters\" (value was \"$parameters\")");
        (!ref($fields)) or push(@_bad_arguments, "Invalid type for argument 4 \"fields\" (value was \"$fields\")");
        (!ref($count)) or push(@_bad_arguments, "Invalid type for argument 5 \"count\" (value was \"$count\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to GetAll:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'GetAll');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "ERDB_Service.GetAll",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'GetAll',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method GetAll",
					    status_line => $self->{client}->status_line,
					    method_name => 'GetAll',
				       );
    }
}



sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, {
        method => "ERDB_Service.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'GetAll',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method GetAll",
            status_line => $self->{client}->status_line,
            method_name => 'GetAll',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for Bio::KBase::ERDB_Service::Client\n";
    }
    if ($sMajor == 0) {
        warn "Bio::KBase::ERDB_Service::Client version is $svr_version. API subject to change.\n";
    }
}

package Bio::KBase::ERDB_Service::Client::RpcClient;
use base 'JSON::RPC::Client';

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $obj) = @_;
    my $result;

    if ($uri =~ /\?/) {
       $result = $self->_get($uri);
    }
    else {
        Carp::croak "not hashref." unless (ref $obj eq 'HASH');
        $result = $self->_post($uri, $obj);
    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}

1;
