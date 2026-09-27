if proof_events_file = System.get_env("PHASE32_PROOF_EVENTS_FILE") do
  Code.require_file("support/phase32_proof_formatter.ex", __DIR__)
  ExUnit.configure(formatters: [ExUnit.CLIFormatter, Paddle.Phase32ProofFormatter])
  Application.put_env(:oarlock, :phase32_proof_events_file, proof_events_file)
end

ExUnit.start()
