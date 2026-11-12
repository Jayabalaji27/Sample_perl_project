package ExpensePortal::Role::Auditable;
use Mojo::Base -role, -signatures;

# Keeps a record of what a service did, for whoever composes this role.

has audit_log => sub { return [] };

sub audit ($self, $event, $subject) {
    push @{$self->audit_log}, {event => $event, subject => $subject, at => time};
    return $self;
}

1;
