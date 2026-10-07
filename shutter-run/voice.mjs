export function createWarning(synth, Utterance) {
  let enabled = true, nextTime = 0;
  const supported = !!synth && !!Utterance;
  function stop() { if (supported) synth.cancel(); }
  function arm() {
    stop(); nextTime = 0;
    if (!supported || !enabled) return;
    // Called from the launch/resume gesture so mobile browsers allow speech.
    const warmup = new Utterance(' '); warmup.volume = 0;
    synth.speak(warmup);
  }
  function tick(run) {
    if (!supported || !enabled || run.status !== 'running' || run.passed < 26 || run.time < nextTime) return;
    if (synth.speaking || synth.pending) return;
    const warning = new Utterance('danger, danger');
    warning.lang = 'en-US'; warning.rate = 1; warning.pitch = .8; warning.volume = 1;
    const voice = synth.getVoices().find(v => /^en[-_]/i.test(v.lang));
    if (voice) warning.voice = voice;
    synth.speak(warning); nextTime = run.time + 3;
  }
  function setEnabled(value) { enabled = value; if (!enabled) stop(); else arm(); }
  return {supported, arm, stop, tick, setEnabled, get enabled() { return enabled; }};
}
