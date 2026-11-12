package ExpensePortal;
use Mojo::Base 'Mojolicious', -signatures;

use DBI;
use Mojo::File qw(path);
use YAML::XS ();    # the settings file's parser: the plugin below needs it loaded

use ExpensePortal::Repository::Schema;

# The Expense Portal: employees submit expense claims, managers decide them.
#
# Settings come from expense_portal.yml beside this application (see README).

# The database handle, opened once and shared: an in-memory database then lives
# as long as the application does.
has dbh => sub ($self) {
    my $dbh = DBI->connect(
        'dbi:SQLite:dbname=' . $self->config->{database},
        q{}, q{}, {RaiseError => 1, PrintError => 0, AutoCommit => 1, sqlite_unicode => 1},
    );
    ExpensePortal::Repository::Schema->deploy($dbh);
    return $dbh;
};

sub startup ($self) {
    my $config = $self->plugin(NotYAMLConfig => {module => 'YAML::XS'});

    path($config->{$_})->make_path for qw(receipt_dir export_dir);
    path($config->{database})->dirname->make_path unless $config->{database} eq ':memory:';

    $self->helper(dbh => sub ($c) { return $c->app->dbh });

    my $r = $self->routes;
    $r->get('/health')->to('health#check');

    # Everything under /api needs the bearer token and says who is asking.
    my $api = $r->under('/api')->to('auth#check');

    $api->get('/claims')->to('claims#list');
    $api->post('/claims')->to('claims#create');
    $api->get('/claims/:id')->to('claims#show');
    $api->post('/claims/:id/approve')->to('claims#approve');
    $api->post('/claims/:id/reject')->to('claims#reject');

    $api->get('/claims/:id/receipt')->to('receipts#show');
    $api->put('/claims/:id/receipt')->to('receipts#upload');

    $api->get('/reports/totals')->to('reports#totals');
    $api->post('/reports/export')->to('reports#export');

    $api->get('/employees')->to('employees#list');
    $api->get('/employees/:name')->to('employees#show');

    return;
}

1;
