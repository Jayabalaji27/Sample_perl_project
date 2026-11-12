package ExpensePortal::Controller::Receipts;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use ExpensePortal::Service::ClaimService;

# A claim's receipts: plain text files, kept beside the database.

# GET /api/claims/:id/receipt?name=taxi.txt
sub show ($self) {
    my $name = $self->param('name') // q{};
    return $self->render(json => {error => 'name is required'}, status => 400) if $name eq q{};

    my $text = eval { $self->_service->receipt_text($self->param('id'), $name) };
    return $self->render(json => {error => 'No such receipt'}, status => 404) if !defined $text;
    return $self->render(json => {claim => $self->param('id') + 0, name => $name, text => $text});
}

# PUT /api/claims/:id/receipt?name=taxi.txt  (the body is the receipt's text)
sub upload ($self) {
    my $name = $self->param('name') // q{};
    return $self->render(json => {error => 'name is required'}, status => 400) if $name eq q{};

    my $service = $self->_service;
    my $claim   = $service->find($self->param('id'));
    return $self->render(json => {error => 'No such claim'}, status => 404) if !$claim;

    my $bytes = $service->attach_receipt($claim, $name, $self->req->text);
    return $self->render(json => {claim => $claim->id, name => $name, bytes => $bytes}, status => 201);
}

sub _service ($self) {
    return ExpensePortal::Service::ClaimService->new(
        dbh         => $self->dbh,
        receipt_dir => $self->config->{receipt_dir},
    );
}

1;
