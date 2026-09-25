# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Demo.Repo.insert!(%Demo.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# For Phase 20: Seed script structure established.
# We will populate this in Phase 21 (Mock Auth) and Phase 22 (Checkout).
# Ensure all operations here are idempotent (e.g., Repo.insert!(..., on_conflict: :nothing)).

IO.puts("==> Seeding database (idempotent)...")
# TODO: Seed Mock Users
# TODO: Seed Mock Products / Prices
IO.puts("==> Database seeded successfully.")
