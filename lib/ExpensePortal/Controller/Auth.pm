package ExpensePortal::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# The bridge in front of /api: a bearer token, and the name of who is asking.
sub check ($self) {
    my $token    = $self->req->headers->authorization  // q{};
    my $employee = $self->req->headers->header('X-Employee') // q{};

    if ($token eq 'Bearer ' . $self->config->{api_token} && $employee ne q{}) {
        $self->stash(employee => $employee);
        return 1;
    }

    $self->render(json => {error => 'unauthorized'}, status => 401);
    return undef;
}

1;
