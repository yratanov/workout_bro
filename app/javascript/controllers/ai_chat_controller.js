import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "messages", "response", "submit"];
  static values = { url: String };

  connect() {
    this.observer = new MutationObserver(() => this.onResponseChange());
    this.observer.observe(this.responseTarget, {
      childList: true,
      characterData: true,
      subtree: true,
    });
  }

  disconnect() {
    this.observer?.disconnect();
  }

  onResponseChange() {
    if (this.responseTarget.innerHTML.trim() === "") return;

    this.removeLoadingIndicator();
    this.scrollToBottom();

    if (this.responseTarget.dataset.messageId) {
      this.finalizeResponse();
    }
  }

  finalizeResponse() {
    const content = this.responseTarget.innerHTML;
    const div = document.createElement("div");
    div.className =
      "text-slate-300 text-sm prose prose-invert prose-sm max-w-none";
    div.innerHTML = content;
    this.messagesTarget.appendChild(div);

    this.responseTarget.innerHTML = "";
    delete this.responseTarget.dataset.messageId;
    this.submitTarget.disabled = false;
    this.scrollToBottom();
  }

  async submit(event) {
    event.preventDefault();

    const question = this.inputTarget.value.trim();
    if (!question) return;

    this.inputTarget.value = "";
    this.submitTarget.disabled = true;

    this.appendUserMessage(question);
    this.appendLoadingIndicator();

    const csrfToken = document.querySelector(
      'meta[name="csrf-token"]',
    )?.content;

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Content-Type": "application/x-www-form-urlencoded",
          Accept: "text/html",
        },
        body: `question=${encodeURIComponent(question)}`,
      });

      if (!response.ok) {
        this.removeLoadingIndicator();
        this.appendErrorMessage();
        this.submitTarget.disabled = false;
      }
    } catch {
      this.removeLoadingIndicator();
      this.appendErrorMessage();
      this.submitTarget.disabled = false;
    }

    this.inputTarget.focus();
  }

  appendUserMessage(text) {
    const div = document.createElement("div");
    div.className = "bg-slate-700 rounded-lg px-3 py-2 text-sm text-white ml-8";
    div.textContent = text;
    this.messagesTarget.appendChild(div);
    this.scrollToBottom();
  }

  appendLoadingIndicator() {
    const div = document.createElement("div");
    div.id = "ai_chat_loading";
    div.className = "flex items-center gap-2 text-slate-400 text-sm";
    div.innerHTML = `
      <div class="w-4 h-4 border-2 border-purple-400 border-t-transparent rounded-full animate-spin"></div>
      <span>Thinking...</span>
    `;
    this.messagesTarget.appendChild(div);
    this.scrollToBottom();
  }

  removeLoadingIndicator() {
    const loading = document.getElementById("ai_chat_loading");
    if (loading) loading.remove();
  }

  appendErrorMessage() {
    const div = document.createElement("div");
    div.className = "text-red-400 text-sm";
    div.textContent = "Something went wrong. Please try again.";
    this.messagesTarget.appendChild(div);
    this.scrollToBottom();
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight;
  }
}
