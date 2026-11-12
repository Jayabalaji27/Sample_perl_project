# Sample Perl project: Expense Portal

A small expense-claims web service, written in Perl with the
[Mojolicious](https://github.com/mojolicious/mojo) framework. It is a sample
for testing security scanners, dependency-graph tools and automated code fixes.

**It is vulnerable on purpose. Never deploy it.** It holds five planted code
weaknesses and pins three libraries with known advisories. Everything else
works: the application runs, and its 177 tests pass.

## Why this project exists

Scanning the Mojolicious framework itself gives poor test material. Its
"findings" are deliberate (a template engine has to `eval`), it has almost no
dependencies, and a framework has no application layers for a dependency graph
to show. This project is an *application* built on Mojolicious instead, so that
a scan gives:

- **code findings that are real and fixable**, one for each rule below;
- **library advisories** with versions to upgrade to;
- **a layered dependency graph**: controllers, services, repositories and models,
  with the calls between them.

## What is in it

Employees submit expense claims. A manager approves or rejects them, and a claim
over the approval limit needs a director. Claims can carry receipts, and can be
totalled and exported.

| Layer | Package | What it does |
|---|---|---|
| Web | `ExpensePortal::Controller::*` | The HTTP endpoints: `Auth`, `Claims`, `Receipts`, `Reports`, `Employees`, `Health` |
| Service | `ExpensePortal::Service::*` | The rules: `ClaimService`, `ReportService`, over a shared `Base` |
| Repository | `ExpensePortal::Repository::*` | The database: `ClaimRepository`, `EmployeeRepository`, `Schema`, over a shared `Base` |
| Domain | `ExpensePortal::Model::*` | `Claim` and `Employee` |
| Other | `ExpensePortal::Util::*`, `ExpensePortal::Role::Auditable` | Money and file helpers; an audit-log role the services compose |

`lib/ExpensePortal.pm` is the application: its settings, its database handle and
its routes.

### Endpoints

Every `/api` request needs `Authorization: Bearer <api_token>` and an
`X-Employee` header naming who is asking.

| Method | Path | Action |
|---|---|---|
| GET | `/health` | `health#check` |
| GET | `/api/claims` | `claims#list` |
| POST | `/api/claims` | `claims#create` |
| GET | `/api/claims/:id` | `claims#show` |
| POST | `/api/claims/:id/approve` | `claims#approve` |
| POST | `/api/claims/:id/reject` | `claims#reject` |
| GET | `/api/claims/:id/receipt` | `receipts#show` |
| PUT | `/api/claims/:id/receipt` | `receipts#upload` |
| GET | `/api/reports/totals` | `reports#totals` |
| POST | `/api/reports/export` | `reports#export` |
| GET | `/api/employees` | `employees#list` |
| GET | `/api/employees/:name` | `employees#show` |

## The planted code weaknesses

One for each of these Perl::Critic policies. Each is in a sub that code in
another file calls, and each has a fix that stays inside that sub.

| Policy | CWE | Where | Reached from | The fix |
|---|---|---|---|---|
| `ValuesAndExpressions::PreventSQLInjection` | CWE-89 | `Repository::ClaimRepository::find_by_employee` | `ClaimService`, `ReportService`, and the `claims`, `reports` endpoints | A `?` placeholder, with the employee as a bind value |
| `BuiltinFunctions::ProhibitStringyEval` | CWE-95 | `Service::ReportService::round_amount` | `GET /api/reports/totals?rounding=` | A table of the allowed rounding rules instead of `eval` |
| `InputOutput::ProhibitBacktickOperators` | CWE-78 | `Service::ReportService::export_line_count` | `POST /api/reports/export` | `open` with `-|` and a list of arguments, so no shell runs |
| `InputOutput::ProhibitTwoArgOpen` | CWE-78 | `Util::Files::read_receipt` | `GET /api/claims/:id/receipt?name=` | Three-argument `open` |
| `InputOutput::RequireEncodingWithUTF8Layer` | CWE-176 | `Util::Files::write_export` | `POST /api/reports/export` | `:encoding(UTF-8)` in place of `:utf8` |

With all five fixed, Perl::Critic reports nothing and the 177 tests still pass.
The tests describe what each sub does, not how, so they pass before and after a
correct fix.

### Seeing one for yourself

The SQL injection is the easiest to see. Ask for the claims of a name nobody
has, with a quote in it:

```bash
curl -G http://127.0.0.1:3000/api/claims \
  -H 'Authorization: Bearer demo-token' -H 'X-Employee: alice' \
  --data-urlencode "employee=nobody' OR '1'='1"
```

As it stands, that returns every employee's claims. With the fix, it returns
none.

## The libraries with known advisories

`cpanfile` pins these versions exactly, and `cpanfile.snapshot` records them.
The snapshot was written by `carton install`, not by hand.

| Library | Pinned | Advisories | Upgrade to |
|---|---|---|---|
| `Mojolicious` | 9.30 | 7, including CVE-2024-58134 and CVE-2024-58135 | 9.48 or later clears those with a fixed version |
| `DBI` | 1.653 | CVE-2026-88815 (medium), CVE-2026-88816 (high) | 1.654 or later |
| `YAML::XS` (distribution `YAML-LibYAML`) | 0.83 | CVE-2025-40908 (critical) | 0.903.0 or later |
| `DBD::SQLite` | 1.76 | none known | |
| `Role::Tiny` | 2.002004 | none known | |

Advisory databases grow, so a later scan may report more for these versions.

## Running it

You need Perl 5.20 or later and [Carton](https://metacpan.org/pod/Carton). It
was built and tested with Perl 5.44.

```bash
carton install                                  # the pinned libraries, into ./local
carton exec prove -lr t                         # the tests
carton exec perl script/expense_portal daemon   # the application, on http://127.0.0.1:3000
```

Settings are in `expense_portal.yml`: the token, the SQLite file, and where
receipts and exports are written. A new database starts with three people:
`alice` (employee), `bob` (manager) and `carol` (director).

```bash
# alice submits a claim, and bob approves it
curl -X POST http://127.0.0.1:3000/api/claims \
  -H 'Authorization: Bearer demo-token' -H 'X-Employee: alice' \
  -H 'Content-Type: application/json' -d '{"category": "travel", "amount": 120.50}'

curl -X POST http://127.0.0.1:3000/api/claims/1/approve \
  -H 'Authorization: Bearer demo-token' -H 'X-Employee: bob'
```

## Resetting after a test run

The tag `baseline` is the starting state, with every weakness in place:

```bash
git checkout main
git reset --hard baseline
git push --force origin main
```

Delete the fix branches a tool created before the next run.
