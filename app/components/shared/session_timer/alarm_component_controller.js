import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    expiresAt: String,
    startAtMs: { type: Number, default: 0 }
  };

  static targets = ["beepSound"];

  connect() {
    this.endTime = new Date(this.expiresAtValue);

    this.update();
    this.updateIntervalId = setInterval(() => this.update(), 1000);
  }

  disconnect() {
    clearInterval(this.updateIntervalId)
  }

  beepSoundTargetDisconnected(element) {
    const audioTag = element;
    audioTag.pause();
  }

  update() {
    const now = new Date();
    const timeLeftMs = this.endTime - now;

    this.beepSoundState(timeLeftMs)
  }

  beepSoundState(milliseconds){
    if(!this.hasBeepSoundTarget) return;
    if(milliseconds > this.startAtMsValue) return;

    const audioTag = this.beepSoundTarget

    if (audioTag.paused || audioTag.ended) {
      audioTag.play();
    }

    if (milliseconds <= 0) {
      if (audioTag.paused || audioTag.ended) return;

      audioTag.pause();
    }
  }
}
