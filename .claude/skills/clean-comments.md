---
name: clean-comments
description: Clean up comments in a particular way, e.g. moving knowledge to tests.
---

I've noticed that agents use comments almost as if to reassure the human that they'd been "heard," but at the cost of cleanliness; the comments later amass and become technical debt. So for each comment:

- If the code obviously says the same thing, delete the comment.
- If the comment does clarify some apsect, consider whether better naming or organization might make the comment unnecessary, but without making the code messy or worse.
- If the comment still seems the economic choice for clarity, then keep it, but ensure there is a test that tests the bit of code needing this explanation. Let the majority of complexity be captured in the test itself, and reduce the comment to a high-level, single-sentence summary, pointing to the name of the test that offers more detail. After writing a test, make an erroneous change in the original code's logic that proves the test fails when it should; then restore the original code and see that the test passes; feel free to try multiple erroneous logic changes.
- Don't move on to the next comment until you perform all of these steps for the current comment.
