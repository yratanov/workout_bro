import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["display", "progressBar"];
  static values = {
    duration: { type: Number, default: 60 },
    running: { type: Boolean, default: false },
  };

  connect() {
    this.remainingMs = this.durationValue * 1000;
    this.beepTimes = [10, 5, 4, 3, 2, 1];
    this.beepedAt = new Set();
    this.initAudio();
    this.requestWakeLock();
    this.start();
  }

  disconnect() {
    this.stop();
    this.releaseWakeLock();
  }

  start() {
    this.runningValue = true;
    this.lastTick = performance.now();
    this.timer = requestAnimationFrame(() => this.tick());
  }

  stop() {
    this.runningValue = false;
    if (this.timer) cancelAnimationFrame(this.timer);
  }

  tick() {
    if (!this.runningValue) return;

    const now = performance.now();
    const delta = now - this.lastTick;
    this.lastTick = now;
    this.remainingMs -= delta;

    if (this.remainingMs <= 0) {
      this.complete();
      return;
    }

    this.updateDisplay();
    this.checkBeeps();
    this.timer = requestAnimationFrame(() => this.tick());
  }

  addTime(event) {
    const seconds = parseInt(event.params.seconds, 10);
    this.remainingMs += seconds * 1000;
    if (this.remainingMs < 0) this.remainingMs = 0;
    this.updateDisplay();
  }

  updateDisplay() {
    const totalSeconds = Math.ceil(this.remainingMs / 1000);
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    this.displayTarget.textContent = `${mins}:${secs.toString().padStart(2, "0")}`;

    const progress = (this.remainingMs / (this.durationValue * 1000)) * 100;
    this.progressBarTarget.style.width = `${Math.max(0, progress)}%`;
  }

  initAudio() {
    this.audioContext = null;
  }

  getAudioContext() {
    if (!this.audioContext) {
      this.audioContext = new (
        window.AudioContext || window.webkitAudioContext
      )();
    }
    return this.audioContext;
  }

  playBeep(frequency = 800, duration = 100) {
    try {
      const ctx = this.getAudioContext();
      const oscillator = ctx.createOscillator();
      const gain = ctx.createGain();
      oscillator.connect(gain);
      gain.connect(ctx.destination);
      oscillator.frequency.value = frequency;
      oscillator.type = "sine";
      gain.gain.setValueAtTime(0.3, ctx.currentTime);
      oscillator.start();
      oscillator.stop(ctx.currentTime + duration / 1000);
    } catch {
      // Audio not available
    }
  }

  checkBeeps() {
    const seconds = Math.ceil(this.remainingMs / 1000);
    if (this.beepTimes.includes(seconds) && !this.beepedAt.has(seconds)) {
      this.beepedAt.add(seconds);
      this.playBeep(seconds <= 5 ? 1000 : 600);
    }
  }

  complete() {
    this.stop();
    this.displayTarget.textContent = "0:00";
    this.progressBarTarget.style.width = "0%";
    this.playBeep(1200, 300);
  }

  dismiss() {
    this.element.remove();
  }

  async requestWakeLock() {
    if ("wakeLock" in navigator) {
      try {
        this.wakeLock = await navigator.wakeLock.request("screen");
      } catch {
        // Wake lock not available or denied
      }
    }
  }

  releaseWakeLock() {
    if (this.wakeLock) {
      this.wakeLock.release();
      this.wakeLock = null;
    }
  }
}
