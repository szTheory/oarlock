import os

# 1. Update 12-01-PLAN.md
f = ".planning/phases/12-documentation-pass/12-01-PLAN.md"
with open(f, "r") as file:
    content = file.read()

content = content.replace(
    "<automated>grep -v '^#' README.md | grep -c \"TODO\" == 0</automated>",
    "<automated>! grep -q \"TODO\" README.md</automated>"
)

content = content.replace(
    "<read_first>guides/getting-started.md, lib/paddle/http/telemetry.ex</read_first>",
    "<read_first>guides/getting-started.md, lib/paddle/http/telemetry.ex, guides/accrue-seam.md</read_first>"
)

action_old = "For `guides/getting-started.md`: Review the file, ensure it walks through the happy path (client -> customer -> address -> transaction -> checkout -> webhook -> subscription) and adheres to the \"Hybrid Explicit\" approach (D-01)."
action_new = "For `guides/getting-started.md`: Review the file, ensure it walks through the happy path (client -> customer -> address -> transaction -> checkout -> webhook -> subscription) and adheres to the \"Hybrid Explicit\" approach (D-01).\n    Reference the analog `guides/accrue-seam.md` from PATTERNS.md to ensure consistent tone, layout, and styling."
content = content.replace(action_old, action_new)

with open(f, "w") as file:
    file.write(content)

# 2. Update 12-04-PLAN.md
f = ".planning/phases/12-documentation-pass/12-04-PLAN.md"
with open(f, "r") as file:
    content = file.read()

action1_old = "Add `## Related Paddle docs` with a link to the canonical Paddle API docs for each function (D-07)."
action1_new = "Add `## Related Paddle docs` with a link to the canonical Paddle API docs for each function (D-07).\n    Include a `## Provider behavior` section in docs for non-obvious footguns (D-08).\n    Ensure typespecs exhaustively list the error union (e.g., `{:error, :invalid_id | Paddle.Error.t()}`) (D-10)."
content = content.replace(action1_old, action1_new)

with open(f, "w") as file:
    file.write(content)

# 3. Update 12-05-PLAN.md
f = ".planning/phases/12-documentation-pass/12-05-PLAN.md"
with open(f, "r") as file:
    content = file.read()

content = content.replace(action1_old, action1_new)

with open(f, "w") as file:
    file.write(content)

# 4. Update 12-06-PLAN.md
f = ".planning/phases/12-documentation-pass/12-06-PLAN.md"
with open(f, "r") as file:
    content = file.read()

task3_old = """<task type="auto">
  <name>Task 3: Final verification of documentation build</name>
  <files></files>
  <read_first></read_first>
  <action>
    Run `mix docs --warnings-as-errors` to ensure all cross-links, missing module docs, and syntax errors are resolved across the entire project.
    If it fails, it means there is an error in one of the previously edited files. This is a verification step to confirm the entire pass. (No files modified in this task unless to fix an error).
  </action>
  <verify>
    <automated>mix docs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `mix docs --warnings-as-errors` exits with 0
  </acceptance_criteria>
  <done>Documentation builds without warnings.</done>
</task>"""

task3_new = """<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 3: Final verification of documentation build</name>
  <what-built>All documentation generation</what-built>
  <how-to-verify>
    Run `mix docs --warnings-as-errors` to ensure all cross-links, missing module docs, and syntax errors are resolved across the entire project.
  </how-to-verify>
  <resume-signal>Type "approved" if it succeeds, or fix issues and retry.</resume-signal>
</task>"""

content = content.replace("autonomous: true", "autonomous: false")
content = content.replace(task3_old, task3_new)

with open(f, "w") as file:
    file.write(content)

print("Updates completed.")
