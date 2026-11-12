package ExpensePortal::Controller::Claims;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use ExpensePortal::Service::ClaimService;

# The claims endpoints. The rules live in ClaimService; an action only reads
# the request and writes the answer.

# GET /api/claims?employee=alice (the caller's own claims when not given)
sub list ($self) {
    my $employee = $self->param('employee') // $self->stash('employee');
    my $claims   = $self->_service->claims_of($employee);
    return $self->render(json => {claims => [map { $_->to_hash } @{$claims}]});
}

# GET /api/claims/:id
sub show ($self) {
    my $claim = $self->_load or return;
    return $self->render(json => $claim->to_hash);
}

# POST /api/claims  {"category": "travel", "amount": 120.5}
sub create ($self) {
    my $input = $self->req->json // {};
    my ($claim, $errors) = $self->_service->submit(
        employee => $self->stash('employee'),
        category => $input->{category},
        amount   => $input->{amount},
    );
    return $self->render(json => {errors => $errors}, status => 422) if @{$errors};
    return $self->render(json => $claim->to_hash, status => 201);
}

# POST /api/claims/:id/approve
sub approve ($self) {
    return $self->_decide('approve');
}

# POST /api/claims/:id/reject
sub reject ($self) {
    return $self->_decide('reject');
}

sub _decide ($self, $decision) {
    my $claim   = $self->_load or return;
    my $decided = eval { $self->_service->decide($claim, $decision, $self->stash('employee')) };
    return $self->render(json => $decided->to_hash) if $decided;

    my $why = $@ =~ s/\s+\z//r;
    return $self->render(json => {error => $why}, status => 409);
}

sub _load ($self) {
    my $claim = $self->_service->find($self->param('id'));
    return $claim if $claim;
    $self->render(json => {error => 'No such claim'}, status => 404);
    return undef;
}

sub _service ($self) {
    return ExpensePortal::Service::ClaimService->new(
        dbh            => $self->dbh,
        approval_limit => $self->config->{approval_limit},
        receipt_dir    => $self->config->{receipt_dir},
    );
}

1;
