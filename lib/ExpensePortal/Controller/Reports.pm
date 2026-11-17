package ExpensePortal::Controller::Reports;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use ExpensePortal::Service::ReportService;

# Totals and exports of an employee's claims.

# GET /api/reports/totals?employee=alice&rounding=floor
sub totals ($self) {
    my $employee = $self->param('employee') // $self->stash('employee');
    my $totals   = eval { $self->_service->totals_by_category($employee, $self->param('rounding') // 'ceil') };
    return $self->render(json => {error => 'Unknown rounding rule'}, status => 400) if !$totals;
    return $self->render(json => {employee => $employee, totals => $totals});
}

# GET /api/reports/status?employee=alice&status=approved
sub by_status ($self) {
    my $employee = $self->param('employee') // $self->stash('employee');
    my $status   = $self->param('status')   // 'submitted';
    my $claims   = $self->_service->claims_in_status($employee, $status);
    return $self->render(json => {employee => $employee, status => $status, claims => [map { $_->to_hash } @{$claims}]});
}

# POST /api/reports/export?employee=alice
sub export ($self) {
    my $employee = $self->param('employee') // $self->stash('employee');
    my $file     = "claims-$employee.csv";
    my $lines    = $self->_service->export_claims($employee, $file);
    return $self->render(json => {file => $file, lines => $lines + 0});
}

sub _service ($self) {
    return ExpensePortal::Service::ReportService->new(
        dbh        => $self->dbh,
        export_dir => $self->config->{export_dir},
    );
}

1;
