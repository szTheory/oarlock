#!/bin/bash
set -e

git add lib/paddle/prices.ex test/paddle/prices_test.exs lib/paddle/internal/pagination.ex
git commit -m "feat(17-02): implement Paddle.Prices API wrapper

- Implement read-only operations for Prices: get/2, list/2, stream/2, all/2
- Reject include query parameter in list operations to prevent eager hydration
- Replicate custom checkout prices warning in @moduledoc
- Use strict string empty check for ID validation
- Extract build_page/3 and next_page/3 to Paddle.Internal.Pagination to be shared
- Add mock tests for all implemented API operations"

TASK_COMMIT=$(git rev-parse --short HEAD)
echo "Commit: $TASK_COMMIT"
