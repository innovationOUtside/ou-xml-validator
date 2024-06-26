function ou_activitySetup() {
  for (const toggle of document.querySelectorAll(".ou-toggle")) {
    toggle.addEventListener("click", () => {
      // Find the associated content container
      const answerContent = toggle
        .closest(".ou-activity-answer")
        .querySelector(".ou-activity-answer-content");

      if (answerContent) {
        // Toggle the visibility of the content
        answerContent.classList.toggle("ou-hidden");

        // Toggle the button state
        toggle.classList.toggle("ou-toggle-hidden");
      }
    });
  }
}

document.addEventListener("DOMContentLoaded", () => {
  ou_activitySetup();

  // Initially hide all answer contents and set button text to "Show answer"
  document.querySelectorAll(".ou-activity-answer").forEach((answer) => {
    const content = answer.querySelector(".ou-activity-answer-content");
    const toggle = answer.querySelector(".ou-toggle");

    if (content && toggle) {
      content.classList.add("ou-hidden");
      toggle.classList.add("ou-toggle-hidden");
    }
  });
});
