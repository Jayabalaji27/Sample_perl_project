package ExpensePortal::Service::ClaimService;
use Mojo::Base 'ExpensePortal::Service::Base', -signatures;
use Role::Tiny::With;

use ExpensePortal::Model::Claim;
use ExpensePortal::Util::Files qw(read_receipt save_receipt);
use ExpensePortal::Util::Money qw(round_cents);

with 'ExpensePortal::Role::Auditable';

# The rules for claims: what may be submitted, and who may decide it.

# A manager decides claims up to this amount; above it, a director.
has approval_limit => 500;
has receipt_dir    => 'data/receipts';

sub claims_of ($self, $employee) {
    return $self->claims->find_by_employee($employee);
}

sub find ($self, $id) {
    return $self->claims->find_by_id($id);
}

# A new claim. Returns the stored claim and no errors, or no claim and why.
sub submit ($self, %input) {
    my $claim = ExpensePortal::Model::Claim->new(
        employee => $input{employee},
        category => $input{category} // 'other',
        amount   => $input{amount},
    );

    my $errors = $claim->validate;
    return (undef, $errors) if @{$errors};

    $claim->amount(round_cents($claim->amount));
    $claim->id($self->claims->add($claim));
    $self->audit(submitted => $claim->id);
    return ($claim, []);
}

# Approves or rejects an open claim. Dies, saying why, when that is not allowed.
sub decide ($self, $claim, $decision, $approver) {
    die 'Claim ' . $claim->id . ' is already ' . $claim->status . "\n" if !$claim->is_open;
    die "Nobody decides their own claim\n" if $claim->employee eq $approver;

    my $who = $self->employees->find_by_name($approver);
    die "Only a manager can decide a claim\n" if !$who || !$who->is_manager;
    die 'A claim over ' . $self->approval_limit . " needs a director\n"
        if $decision eq 'approve' && $claim->amount > $self->approval_limit && !$who->is_director;

    my $status = $decision eq 'approve' ? 'approved' : 'rejected';
    $self->claims->set_status($claim->id, $status);
    $claim->status($status);
    $self->audit($status => $claim->id);
    return $claim;
}

# Stores a receipt's text for a claim and returns how many characters it holds.
sub attach_receipt ($self, $claim, $name, $text) {
    my $written = save_receipt($self->_receipt_path($claim->id, $name), $text);
    $self->audit(receipt => $claim->id);
    return $written;
}

# The text of a claim's receipt. Dies when there is none.
sub receipt_text ($self, $id, $name) {
    return read_receipt($self->_receipt_path($id, $name));
}

sub everyone ($self) {
    return $self->employees->all;
}

# An employee, with how many of their claims are in each status.
sub employee_summary ($self, $name) {
    my $employee = $self->employees->find_by_name($name) or return undef;
    return {employee => $employee->to_hash, claims => $self->claims->count_by_status($name)};
}

sub _receipt_path ($self, $id, $name) {
    return $self->receipt_dir . "/$id-$name";
}

1;
