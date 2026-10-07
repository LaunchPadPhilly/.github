Perform a deep code quality audit of this PR's diff versus its base
branch, focused on implementation quality, maintainability,
abstraction quality, and codebase health. Rethink how to structure
the changes to meaningfully improve code quality without impacting
behavior. Work to improve abstractions and modularity, reduce
spaghetti code, and improve succinctness and legibility. Be
ambitious: if there is a clear path to a dramatically simpler
restructuring ("code judo" — a reorganization that uses the
existing architecture more effectively and deletes whole branches,
helpers, or layers rather than just rearranging them), push hard
for it rather than settling for local cleanup. Be extremely
thorough and rigorous. Measure twice, cut once.

Apply these standards:
- Flag a file crossing from under 1000 lines to over 1000 lines
  without a strong reason; prefer decomposition first.
- Flag ad-hoc conditionals, scattered special cases, or one-off
  branches bolted onto existing flows; prefer a dedicated
  abstraction, helper, or module instead.
- Bias toward the cleaner design over rubber-stamping "it works";
  prefer simplifications that remove moving pieces over refactors
  that just spread the same complexity around.
- Prefer direct, boring, maintainable code over hacky or magical
  mechanisms; flag thin/identity wrappers that add indirection
  without clarity.
- Push on type and boundary cleanliness: question unnecessary
  optionality, `unknown`/`any`, or cast-heavy code; prefer explicit
  typed models over ad-hoc shapes.
- Flag feature logic leaking into shared/canonical paths; prefer
  existing canonical helpers over bespoke one-offs.
- Flag unnecessary sequential orchestration or non-atomic updates
  when a more parallel or atomic structure is clearly better.

Prioritize findings in this order: structural regressions, missed
dramatic-simplification opportunities, spaghetti/branching growth,
boundary/type problems, file-size/decomposition, modularity, then
legibility. Prefer a small number of high-conviction comments over
a long list of cosmetic nits. Do not soften major maintainability
issues into mild suggestions, but stay direct rather than rude.

Post your findings as a single PR review with event type COMMENT.
Do NOT approve this PR and do NOT request changes as a formal review
state — this review is advisory only. A human reviewer is the merge
gate, not you.
