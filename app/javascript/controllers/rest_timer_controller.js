import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["display", "progressBar"];
  static values = {
    duration: { type: Number, default: 60 },
    running: { type: Boolean, default: false },
    notificationTitle: { type: String, default: "Rest Complete" },
    notificationBody: { type: String, default: "Time for your next set!" },
  };

  connect() {
    this.remainingMs = this.durationValue * 1000;
    this.beepTimes = [10, 5, 4, 3, 2, 1];
    this.beepedAt = new Set();
    this.scheduledNotificationId = null;
    this.initAudio();
    this.requestWakeLock();
    this.initPushNotifications();
    this.start();
  }

  disconnect() {
    this.stop();
    this.releaseWakeLock();
    this.cancelServerPush();
  }

  start() {
    this.runningValue = true;
    this.lastTick = performance.now();
    this.timer = requestAnimationFrame(() => this.tick());
    this.scheduleServerPush(Math.ceil(this.remainingMs / 1000));
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
    this.rescheduleServerPush();
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
    this.showNotification();
    this.cancelServerPush();
  }

  dismiss() {
    this.cancelServerPush();
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

  async initPushNotifications() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) {
      return;
    }

    try {
      const registration = await navigator.serviceWorker.ready;

      // Check and request notification permission
      if (Notification.permission === "default") {
        await Notification.requestPermission();
      }

      if (Notification.permission !== "granted") {
        return;
      }

      // Get VAPID public key
      const vapidResponse = await fetch("/push_subscriptions/vapid_public_key");
      if (!vapidResponse.ok) {
        return;
      }

      const { vapid_public_key } = await vapidResponse.json();
      if (!vapid_public_key) {
        return;
      }

      // Subscribe to push
      let subscription = await registration.pushManager.getSubscription();
      if (!subscription) {
        subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.urlBase64ToUint8Array(vapid_public_key),
        });
      }

      // Register subscription with server
      const keys = subscription.toJSON().keys;
      await fetch("/push_subscriptions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken,
        },
        body: JSON.stringify({
          subscription: {
            endpoint: subscription.endpoint,
            p256dh: keys.p256dh,
            auth: keys.auth,
          },
        }),
      });

      this.pushSubscribed = true;
    } catch {
      // Push notifications not available
    }
  }

  async scheduleServerPush(delaySeconds) {
    if (!this.pushSubscribed || delaySeconds <= 0) return;

    try {
      const response = await fetch("/scheduled_push_notifications", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken,
        },
        body: JSON.stringify({ delay_seconds: delaySeconds }),
      });

      if (response.ok) {
        const data = await response.json();
        this.scheduledNotificationId = data.id;
      }
    } catch {
      // Failed to schedule push
    }
  }

  async cancelServerPush() {
    if (!this.scheduledNotificationId) return;

    try {
      await fetch(
        `/scheduled_push_notifications/${this.scheduledNotificationId}`,
        {
          method: "DELETE",
          headers: {
            "X-CSRF-Token": this.csrfToken,
          },
        },
      );
    } catch {
      // Failed to cancel push
    }

    this.scheduledNotificationId = null;
  }

  async rescheduleServerPush() {
    await this.cancelServerPush();
    const seconds = Math.ceil(this.remainingMs / 1000);
    if (seconds > 0) {
      await this.scheduleServerPush(seconds);
    }
  }

  showNotification() {
    if ("Notification" in window && Notification.permission === "granted") {
      new Notification(this.notificationTitleValue, {
        body: this.notificationBodyValue,
        icon: "/icon2.png",
        tag: "rest-timer",
        requireInteraction: false,
      });
    }
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4);
    const base64 = (base64String + padding)
      .replace(/-/g, "+")
      .replace(/_/g, "/");

    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content;
  }
}
