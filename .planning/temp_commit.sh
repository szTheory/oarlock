#!/bin/bash
set -e

git add lib/paddle/price.ex test/paddle/price_test.exs
git commit -m "feat(17-02): add Paddle.Price struct and tests

- Implement Paddle.Price struct definition
- Define typespec and explicitly map price fields
- Catch unknown keys in raw_data map
- Include warning about custom prices in @moduledoc
- Add tests to ensure properties and raw_data are mapped correctly"

TASK_COMMIT=$(git rev-parse --short HEAD)
echo "Commit: $TASK_COMMIT"
