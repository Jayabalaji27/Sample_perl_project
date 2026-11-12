package ExpensePortal::Controller::Health;
use Mojo::Base 'Mojolicious::Controller', -signatures;

# GET /health: the application answers, and so does its database.
sub check ($self) {
    my ($one) = $self->dbh->selectrow_array('SELECT 1');
    return $self->render(json => {status => $one ? 'ok' : 'degraded'});
}

1;
