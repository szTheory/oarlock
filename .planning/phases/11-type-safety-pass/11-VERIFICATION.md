# Type Safety Pass Verification

## Explicit Negative-Path Verification Procedure

To verify the roadmap success criterion that the CI gate will actually catch broken or missing public specs, you can run this controlled temporary break locally. Because the CI job in `.github/workflows/ci.yml` runs the same `mix typecheck.specs` command, this local failure serves as equivalent proof that a missing or broken spec branch will fail the required CI gate before merging.

### Steps to Reproduce

1. **Remove a known public spec temporarily.**
   Open `lib/paddle/customers.ex` and comment out the `@spec` for `get/2`:

   ```elixir
   # @spec get(Paddle.Client.t(), customer_id()) ::
   #         {:ok, Paddle.Customer.t()} | {:error, Paddle.Error.t() | :invalid_customer_id}
   def get(%Client{} = client, customer_id) do
   ```

2. **Run the typecheck task.**
   Execute the mechanical check task locally:

   ```bash
   mix typecheck.specs
   ```

3. **Observe the failure.**
   The command will exit with a non-zero status code and emit actionable output pointing to the exact file and function missing its spec:

   ```text
   Failed: Missing @spec for Paddle.Customers.get/2 in lib/paddle/customers.ex
   ```

4. **Restore the spec.**
   Uncomment the `@spec` in `lib/paddle/customers.ex`.

   ```elixir
   @spec get(Paddle.Client.t(), customer_id()) ::
           {:ok, Paddle.Customer.t()} | {:error, Paddle.Error.t() | :invalid_customer_id}
   def get(%Client{} = client, customer_id) do
   ```

5. **Verify the gate passes again.**
   Run `mix typecheck.specs` again. The command should now exit `0` and print a success message.

**Important:** Do not commit the temporarily broken spec. The repository must remain in a passing state.
