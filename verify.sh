#!/bin/bash

# 1. README is complete and has no TODOs
grep -q "TODO" README.md && echo "FAIL: README has TODOs" || echo "PASS: README is clean"

# 2. Telemetry guide provides specific measurement schemas
grep -q "measurement" guides/telemetry.md && echo "PASS: Telemetry guide has measurements" || echo "FAIL: Telemetry guide missing measurements"

# 3. Mix config exposes getting started and telemetry guides
grep -q "guides/getting-started.md" mix.exs && echo "PASS: mix config has getting-started" || echo "FAIL: mix config missing getting-started"
grep -q "guides/telemetry.md" mix.exs && echo "PASS: mix config has telemetry" || echo "FAIL: mix config missing telemetry"

# 4. Core SDK structs are documented with their fields and purposes
grep -q "@moduledoc" lib/paddle/client.ex && echo "PASS: Client moduledoc" || echo "FAIL: Client missing moduledoc"
grep -q "Client.new" lib/paddle/client.ex && echo "PASS: Client.new doc" || echo "FAIL: Client.new doc missing"

grep -q "@moduledoc" lib/paddle/error.ex && echo "PASS: Error moduledoc" || echo "FAIL: Error missing moduledoc"
grep -q "@moduledoc" lib/paddle/page.ex && echo "PASS: Page moduledoc" || echo "FAIL: Page missing moduledoc"
grep -q "@moduledoc" lib/paddle/event.ex && echo "PASS: Event moduledoc" || echo "FAIL: Event missing moduledoc"

# 5. Customer and Address structs
grep -q "@moduledoc" lib/paddle/customer.ex && echo "PASS: Customer moduledoc" || echo "FAIL: Customer missing moduledoc"
grep -q "@moduledoc" lib/paddle/address.ex && echo "PASS: Address moduledoc" || echo "FAIL: Address missing moduledoc"

# 6. Billing structs and nested structs documented
grep -q "@moduledoc" lib/paddle/subscription.ex && echo "PASS: Subscription moduledoc" || echo "FAIL: Subscription missing moduledoc"
grep -q "@moduledoc" lib/paddle/transaction.ex && echo "PASS: Transaction moduledoc" || echo "FAIL: Transaction missing moduledoc"

# 7. Core controller modules have hybrid explicit pipeline examples
grep -q "@moduledoc" lib/paddle/customers.ex && echo "PASS: Customers moduledoc" || echo "FAIL: Customers missing moduledoc"
grep -q "@moduledoc" lib/paddle/customers/addresses.ex && echo "PASS: Addresses moduledoc" || echo "FAIL: Addresses missing moduledoc"
grep -q "@moduledoc" lib/paddle/webhooks.ex && echo "PASS: Webhooks moduledoc" || echo "FAIL: Webhooks missing moduledoc"

# 8. Every public function in core controllers has an example showing explicit match
grep -q "## Examples" lib/paddle/customers.ex && echo "PASS: Customers has examples" || echo "FAIL: Customers missing examples"
grep -q "{:ok," lib/paddle/customers.ex && echo "PASS: Customers has explicit match" || echo "FAIL: Customers missing explicit match"

# 9. Billing controller modules have hybrid explicit pipeline examples
grep -q "@moduledoc" lib/paddle/transactions.ex && echo "PASS: Transactions moduledoc" || echo "FAIL: Transactions missing moduledoc"
grep -q "@moduledoc" lib/paddle/subscriptions.ex && echo "PASS: Subscriptions moduledoc" || echo "FAIL: Subscriptions missing moduledoc"
grep -q "## Examples" lib/paddle/transactions.ex && echo "PASS: Transactions has examples" || echo "FAIL: Transactions missing examples"
grep -q "## Examples" lib/paddle/subscriptions.ex && echo "PASS: Subscriptions has examples" || echo "FAIL: Subscriptions missing examples"

# 10. Internal sealed modules hidden
grep -q "@moduledoc false" lib/paddle.ex && echo "PASS: Paddle is sealed" || echo "FAIL: Paddle not sealed"
grep -q "@moduledoc false" lib/paddle/http.ex && echo "PASS: Http is sealed" || echo "FAIL: Http not sealed"
grep -q "@moduledoc false" lib/paddle/http/telemetry.ex && echo "PASS: Http.Telemetry is sealed" || echo "FAIL: Http.Telemetry not sealed"
grep -q "@moduledoc false" lib/paddle/application.ex && echo "PASS: Application is sealed" || echo "FAIL: Application not sealed"
grep -q "@moduledoc false" lib/paddle/internal/attrs.ex && echo "PASS: Internal.Attrs is sealed" || echo "FAIL: Internal.Attrs not sealed"
grep -q "@moduledoc false" lib/paddle/internal/pagination.ex && echo "PASS: Internal.Pagination is sealed" || echo "FAIL: Internal.Pagination not sealed"

# 11. Test for sealed modules
grep -q "sealed modules remain undocumented" test/paddle/seam_test.exs && echo "PASS: Seam test present" || echo "FAIL: Seam test missing"
grep -q "Code.fetch_docs" test/paddle/seam_test.exs && echo "PASS: Code.fetch_docs in test" || echo "FAIL: Code.fetch_docs missing in test"

# 12. Paddle.Error internal functions hidden
grep -A 1 "@doc false" lib/paddle/error.ex | grep -q "from_response" && echo "PASS: from_response is hidden" || echo "FAIL: from_response not hidden"

