package ExpensePortal::Controller::Employees;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use ExpensePortal::Service::ClaimService;

# Who works here, and how their claims stand.

# GET /api/employees
sub list ($self) {
    my $employees = $self->_service->everyone;
    return $self->render(json => {employees => [map { $_->to_hash } @{$employees}]});
}

# GET /api/employees/:name
sub show ($self) {
    my $summary = $self->_service->employee_summary($self->param('name'));
    return $self->render(json => {error => 'No such employee'}, status => 404) if !$summary;
    return $self->render(json => $summary);
}

sub _service ($self) {
    return ExpensePortal::Service::ClaimService->new(dbh => $self->dbh);
}

1;
