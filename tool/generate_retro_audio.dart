// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() async {
  final audioDir = Directory('assets/audio');
  if (!audioDir.existsSync()) {
    audioDir.createSync(recursive: true);
  }

  print('Generating Retro 2D Arcade Sound Effects & Music...');

  // 1. UI Click: Retro 8-bit crisp blip (dual pitch hop)
  final clickWav = generateClickSfx();
  File('assets/audio/sfx_click.wav').writeAsBytesSync(clickWav);
  print('Saved sfx_click.wav (${clickWav.length} bytes)');

  // 2. Walk: Retro footstep tap (short soft low-freq square blip)
  final stepWav = generateStepSfx();
  File('assets/audio/sfx_step.wav').writeAsBytesSync(stepWav);
  print('Saved sfx_step.wav (${stepWav.length} bytes)');

  // 3. Normal Paddle Hit: Crisp retro arcade ball bounce
  final hitWav = generateHitSfx();
  File('assets/audio/sfx_hit.wav').writeAsBytesSync(hitWav);
  print('Saved sfx_hit.wav (${hitWav.length} bytes)');

  // 4. Smash: Explosive retro 8-bit smash impact with noise explosion + pitch drop
  final smashWav = generateSmashSfx();
  File('assets/audio/sfx_smash.wav').writeAsBytesSync(smashWav);
  print('Saved sfx_smash.wav (${smashWav.length} bytes)');

  // 5. Dash: Supersonic retro turbo dash swoosh
  final dashWav = generateDashSfx();
  File('assets/audio/sfx_dash.wav').writeAsBytesSync(dashWav);
  print('Saved sfx_dash.wav (${dashWav.length} bytes)');

  // 6. Left Spin (Cyclone Curve): Swirling rising resonance pitch bend
  final leftSpinWav = generateLeftSpinSfx();
  File('assets/audio/sfx_left_spin.wav').writeAsBytesSync(leftSpinWav);
  print('Saved sfx_left_spin.wav (${leftSpinWav.length} bytes)');

  // 7. Right Spin (Vortex Hook): Electric zap / plasma arpeggio
  final rightSpinWav = generateRightSpinSfx();
  File('assets/audio/sfx_right_spin.wav').writeAsBytesSync(rightSpinWav);
  print('Saved sfx_right_spin.wav (${rightSpinWav.length} bytes)');

  // 8. BGM: Catchy 8-bit arcade sports chiptune loop (~11 seconds, seamlessly loops)
  final bgmWav = generateArcadeBgm();
  File('assets/audio/bgm_arcade_loop.wav').writeAsBytesSync(bgmWav);
  print('Saved bgm_arcade_loop.wav (${bgmWav.length} bytes)');

  // 9. Victory: Triumphant retro 8-bit arcade championship fanfare jingle (~1.8s)
  final victoryWav = generateVictorySfx();
  File('assets/audio/sfx_victory.wav').writeAsBytesSync(victoryWav);
  print('Saved sfx_victory.wav (${victoryWav.length} bytes)');

  // 10. Defeat: Retro 8-bit sad minor descending game over jingle (~1.6s)
  final defeatWav = generateDefeatSfx();
  File('assets/audio/sfx_defeat.wav').writeAsBytesSync(defeatWav);
  print('Saved sfx_defeat.wav (${defeatWav.length} bytes)');

  // 11. Point Scored: Retro 8-bit cheerful 2-tone reward chime (~0.22s)
  final pointWav = generatePointScoredSfx();
  File('assets/audio/sfx_point_scored.wav').writeAsBytesSync(pointWav);
  print('Saved sfx_point_scored.wav (${pointWav.length} bytes)');

  // 12. Fault / Violation: Retro arcade double-buzz alert whistle (~0.25s)
  final faultWav = generateFaultSfx();
  File('assets/audio/sfx_fault.wav').writeAsBytesSync(faultWav);
  print('Saved sfx_fault.wav (${faultWav.length} bytes)');

  // 13. Coin Earn / Shop Purchase: Iconic retro 8-bit twin-chime (~0.22s)
  final coinWav = generateCoinSfx();
  File('assets/audio/sfx_coin.wav').writeAsBytesSync(coinWav);
  print('Saved sfx_coin.wav (${coinWav.length} bytes)');

  // 14. Serve Launch: Energetic rising underhand serve whoosh (~0.16s)
  final serveWav = generateServeSfx();
  File('assets/audio/sfx_serve.wav').writeAsBytesSync(serveWav);
  print('Saved sfx_serve.wav (${serveWav.length} bytes)');

  // 15. Court Floor Bounce: Distinct hollow acrylic/wood court bounce pop (~0.08s)
  final bounceWav = generateBounceSfx();
  File('assets/audio/sfx_bounce.wav').writeAsBytesSync(bounceWav);
  print('Saved sfx_bounce.wav (${bounceWav.length} bytes)');

  // 16. Level Up: Ascending multi-tier celebratory power-up fanfare (~0.55s)
  final levelUpWav = generateLevelUpSfx();
  File('assets/audio/sfx_levelup.wav').writeAsBytesSync(levelUpWav);
  print('Saved sfx_levelup.wav (${levelUpWav.length} bytes)');

  // 17. Countdown: Crisp 8-bit electronic pulse beep (~0.12s)
  final countdownWav = generateCountdownSfx();
  File('assets/audio/sfx_countdown.wav').writeAsBytesSync(countdownWav);
  print('Saved sfx_countdown.wav (${countdownWav.length} bytes)');

  print('All retro arcade audio assets successfully generated!');
}

Uint8List buildWav(List<double> samples, {int sampleRate = 22050}) {
  final numSamples = samples.length;
  final numChannels = 1;
  final bitsPerSample = 16;
  final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final blockAlign = numChannels * (bitsPerSample ~/ 8);
  final dataSize = numSamples * (bitsPerSample ~/ 8);
  final totalFileSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);

  // RIFF Chunk
  buffer.setUint8(0, 0x52); // 'R'
  buffer.setUint8(1, 0x49); // 'I'
  buffer.setUint8(2, 0x46); // 'F'
  buffer.setUint8(3, 0x46); // 'F'
  buffer.setUint32(4, totalFileSize, Endian.little);

  // WAVE Chunk
  buffer.setUint8(8, 0x57);  // 'W'
  buffer.setUint8(9, 0x41);  // 'A'
  buffer.setUint8(10, 0x56); // 'V'
  buffer.setUint8(11, 0x45); // 'E'

  // fmt subchunk
  buffer.setUint8(12, 0x66); // 'f'
  buffer.setUint8(13, 0x6D); // 'm'
  buffer.setUint8(14, 0x74); // 't'
  buffer.setUint8(15, 0x20); // ' '
  buffer.setUint32(16, 16, Endian.little); // SubChunk1Size (16 for PCM)
  buffer.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
  buffer.setUint16(22, numChannels, Endian.little);
  buffer.setUint32(24, sampleRate, Endian.little);
  buffer.setUint32(28, byteRate, Endian.little);
  buffer.setUint16(32, blockAlign, Endian.little);
  buffer.setUint16(34, bitsPerSample, Endian.little);

  // data subchunk
  buffer.setUint8(36, 0x64); // 'd'
  buffer.setUint8(37, 0x61); // 'a'
  buffer.setUint8(38, 0x74); // 't'
  buffer.setUint8(39, 0x61); // 'a'
  buffer.setUint32(40, dataSize, Endian.little);

  int offset = 44;
  for (int i = 0; i < numSamples; i++) {
    double s = samples[i].clamp(-1.0, 1.0);
    int pcm16 = (s * 32767).toInt();
    buffer.setInt16(offset, pcm16, Endian.little);
    offset += 2;
  }

  return buffer.buffer.asUint8List();
}

/// Helper square wave
double squareWave(double phase, {double duty = 0.5}) {
  final p = phase - phase.floor();
  return p < duty ? 1.0 : -1.0;
}

/// Helper triangle wave
double triangleWave(double phase) {
  final p = phase - phase.floor();
  return (4.0 * (p - 0.5).abs()) - 1.0;
}

/// Helper sawtooth wave
double sawtoothWave(double phase) {
  final p = phase - phase.floor();
  return 2.0 * p - 1.0;
}

/// 1. UI Click: High arcade blip, two tones 880Hz -> 1320Hz, ~0.045s
Uint8List generateClickSfx() {
  const sampleRate = 22050;
  const duration = 0.045;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];

  double phase = 0.0;
  for (int i = 0; i < count; i++) {
    final t = i / sampleRate;
    final env = pow(1.0 - (i / count), 1.8).toDouble();
    final freq = t < 0.018 ? 880.0 : 1320.0;
    phase += freq / sampleRate;
    final wave = squareWave(phase, duty: 0.35) * 0.7 + triangleWave(phase) * 0.3;
    samples.add(wave * env * 0.7);
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 2. Walk: Retro footstep tap, soft short blip, ~0.035s
Uint8List generateStepSfx() {
  const sampleRate = 22050;
  const duration = 0.035;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];
  final rand = Random(42);

  double phase = 0.0;
  for (int i = 0; i < count; i++) {
    final t = i / sampleRate;
    final env = pow(1.0 - (i / count), 2.5).toDouble();
    // Pitch drop from 180 to 90 Hz
    final freq = 180.0 - 90.0 * (t / duration);
    phase += freq / sampleRate;
    final tone = triangleWave(phase) * 0.65;
    final noise = (rand.nextDouble() * 2.0 - 1.0) * 0.35;
    samples.add((tone + noise) * env * 0.5);
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 3. Normal Paddle Hit: Classic Pong/Arcade hit ping, ~0.08s
Uint8List generateHitSfx() {
  const sampleRate = 22050;
  const duration = 0.085;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];

  double phase = 0.0;
  for (int i = 0; i < count; i++) {
    final t = i / sampleRate;
    final env = pow(1.0 - (i / count), 2.2).toDouble();
    // Pitch drops from 640 to 320 Hz
    final freq = 640.0 * (1.0 - 0.5 * (t / duration));
    phase += freq / sampleRate;
    final wave = squareWave(phase, duty: 0.5) * 0.8 + triangleWave(phase) * 0.2;
    samples.add(wave * env * 0.8);
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 4. Smash: Explosive retro 8-bit smash impact with noise explosion + heavy bass drop, ~0.28s
Uint8List generateSmashSfx() {
  const sampleRate = 22050;
  const duration = 0.28;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];
  final rand = Random(1337);

  double phaseSquare = 0.0;
  double phaseSub = 0.0;
  for (int i = 0; i < count; i++) {
    final progress = i / count;
    // Rapid exponential decay
    final envTone = pow(1.0 - progress, 2.0).toDouble();
    final envNoise = pow(1.0 - progress, 3.5).toDouble();

    // Pitch drops dramatically from 450Hz down to 55Hz
    final freqSquare = 450.0 * exp(-progress * 5.0) + 55.0;
    phaseSquare += freqSquare / sampleRate;

    // Sub bass impact
    final freqSub = 120.0 * exp(-progress * 4.0) + 40.0;
    phaseSub += freqSub / sampleRate;

    final square = squareWave(phaseSquare, duty: 0.25) * 0.45;
    final sub = triangleWave(phaseSub) * 0.45;
    final noise = (rand.nextDouble() * 2.0 - 1.0) * 0.7;

    final sample = (square + sub) * envTone + noise * envNoise;
    samples.add(sample.clamp(-1.0, 1.0) * 0.95);
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 5. Dash: Supersonic retro turbo dash swoosh, ~0.22s
Uint8List generateDashSfx() {
  const sampleRate = 22050;
  const duration = 0.22;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];
  final rand = Random(777);

  double phase = 0.0;
  for (int i = 0; i < count; i++) {
    final progress = i / count;
    // Bell envelope
    final env = sin(progress * pi);

    // Rising then falling whoosh
    final freq = 300.0 + 900.0 * sin(progress * pi);
    phase += freq / sampleRate;

    final tone = squareWave(phase, duty: 0.5) * 0.4;
    final noise = (rand.nextDouble() * 2.0 - 1.0) * 0.6;

    final mix = (tone + noise) * env * 0.8;
    samples.add(mix.clamp(-1.0, 1.0));
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 6. Left Spin (Cyclone Curve): Swirling pitch modulation bend, ~0.26s
Uint8List generateLeftSpinSfx() {
  const sampleRate = 22050;
  const duration = 0.26;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];

  double phase = 0.0;
  for (int i = 0; i < count; i++) {
    final progress = i / count;
    final env = (1.0 - progress) * (sin(progress * pi * 0.5) + 0.3);

    // Rapid vibrato swirl with rising center frequency
    final vibrato = sin(progress * 48.0 * pi) * 120.0;
    final baseFreq = 380.0 + progress * 500.0;
    final freq = baseFreq + vibrato;
    phase += freq / sampleRate;

    final wave = sawtoothWave(phase) * 0.5 + squareWave(phase, duty: 0.3) * 0.5;
    samples.add((wave * env * 0.8).clamp(-1.0, 1.0));
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 7. Right Spin (Vortex Hook): Electric plasma zap / rapid arpeggio, ~0.26s
Uint8List generateRightSpinSfx() {
  const sampleRate = 22050;
  const duration = 0.26;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];

  // Fast 16th note arcade arpeggio frequencies (A minor / Electric chord)
  final arp = [440.0, 554.37, 659.25, 880.0, 1108.73, 1318.51, 1760.0];

  double phase = 0.0;
  for (int i = 0; i < count; i++) {
    final progress = i / count;
    final env = pow(1.0 - progress, 1.2).toDouble();

    final noteIndex = ((progress * 28.0).toInt()) % arp.length;
    final freq = arp[noteIndex];
    phase += freq / sampleRate;

    final pulse = squareWave(phase, duty: 0.2) * 0.7 + triangleWave(phase) * 0.3;
    samples.add((pulse * env * 0.8).clamp(-1.0, 1.0));
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 8. BGM: Catchy 8-bit arcade sports chiptune loop (~11.0 seconds, seamless loop)
Uint8List generateArcadeBgm() {
  const sampleRate = 22050;
  const bpm = 132.0;
  final beatSec = 60.0 / bpm;
  // 6 bars of 4 beats = 24 beats ~ 10.909 seconds
  const totalBeats = 24;
  final duration = totalBeats * beatSec;
  final totalSamples = (sampleRate * duration).toInt();
  final samples = List<double>.filled(totalSamples, 0.0);

  // Musical Scale (C Major Pentatonic / Energetic Arcade Chiptune)
  const g4 = 392.00;
  const c5 = 523.25;
  const d5 = 587.33;
  const e5 = 659.25;
  const g5 = 783.99;
  const a5 = 880.00;
  const c3 = 130.81;
  const g3 = 196.00;
  const a2 = 110.00;
  const f3 = 174.61;

  // Melody notes: (beatOffset, durationBeats, freq)
  final melody = <List<num>>[
    // Bar 1 & 2 (C chord groove)
    [0.0, 0.5, c5], [0.5, 0.5, e5], [1.0, 0.5, g5], [1.5, 0.5, e5],
    [2.0, 0.75, a5], [2.75, 0.25, g5], [3.0, 1.0, e5],
    [4.0, 0.5, d5], [4.5, 0.5, e5], [5.0, 0.5, g5], [5.5, 0.5, d5],
    [6.0, 1.0, c5], [7.0, 1.0, g4],

    // Bar 3 & 4 (F / A minor variation)
    [8.0, 0.5, c5], [8.5, 0.5, d5], [9.0, 0.5, e5], [9.5, 0.5, g5],
    [10.0, 0.75, a5], [10.75, 0.25, c5 * 2], [11.0, 1.0, a5],
    [12.0, 0.5, g5], [12.5, 0.5, e5], [13.0, 0.5, d5], [13.5, 0.5, c5],
    [14.0, 1.0, d5], [15.0, 1.0, e5],

    // Bar 5 & 6 (High energy climax & resolution loop back)
    [16.0, 0.5, g5], [16.5, 0.5, a5], [17.0, 0.5, c5 * 2], [17.5, 0.5, a5],
    [18.0, 1.0, g5], [19.0, 1.0, e5],
    [20.0, 0.5, d5], [20.5, 0.5, e5], [21.0, 0.5, d5], [21.5, 0.5, c5],
    [22.0, 1.5, d5], [23.5, 0.5, g4],
  ];

  // Bassline notes: (beatOffset, durationBeats, freq)
  final bassline = <List<num>>[];
  final bassChords = [c3, c3, f3, f3, a2, g3];
  for (int bar = 0; bar < 6; bar++) {
    final base = bassChords[bar];
    for (int b = 0; b < 4; b++) {
      final beat = bar * 4.0 + b;
      final freq = (b % 2 == 0) ? base : base * 1.5; // root - fifth bounce
      bassline.add([beat, 0.4, freq]);
      bassline.add([beat + 0.5, 0.35, freq * 1.25]); // upbeat octave/third bounce
    }
  }

  // Synthesize Melody (Lead Square Wave with 50% duty and gentle decay)
  for (final note in melody) {
    final startBeat = note[0];
    final durBeat = note[1];
    final freq = note[2].toDouble();
    final startSample = (startBeat * beatSec * sampleRate).toInt();
    final noteSamples = (durBeat * beatSec * sampleRate).toInt();

    double phase = 0.0;
    for (int i = 0; i < noteSamples && (startSample + i) < totalSamples; i++) {
      final env = pow(1.0 - (i / noteSamples), 0.6).toDouble();
      phase += freq / sampleRate;
      final wave = squareWave(phase, duty: 0.5) * 0.32;
      samples[startSample + i] += wave * env;
    }
  }

  // Synthesize Bassline (Punchy Triangle wave + Square blend)
  for (final note in bassline) {
    final startBeat = note[0];
    final durBeat = note[1];
    final freq = note[2].toDouble();
    final startSample = (startBeat * beatSec * sampleRate).toInt();
    final noteSamples = (durBeat * beatSec * sampleRate).toInt();

    double phase = 0.0;
    for (int i = 0; i < noteSamples && (startSample + i) < totalSamples; i++) {
      final env = pow(1.0 - (i / noteSamples), 1.5).toDouble();
      phase += freq / sampleRate;
      final wave = triangleWave(phase) * 0.35 + squareWave(phase, duty: 0.25) * 0.15;
      samples[startSample + i] += wave * env;
    }
  }

  // Synthesize Retro 8-bit Chiptune Drums (Kick on 1 & 3, Snare/Noise on 2 & 4, Hi-hat on 8ths)
  final rand = Random(999);
  for (int beat = 0; beat < totalBeats; beat++) {
    final beatSample = (beat * beatSec * sampleRate).toInt();

    // Kick on every beat, accented on 0 and 2 of each bar
    final kickSamples = (0.09 * sampleRate).toInt();
    double kickPhase = 0.0;
    for (int i = 0; i < kickSamples && (beatSample + i) < totalSamples; i++) {
      final p = i / kickSamples;
      final env = pow(1.0 - p, 3.0).toDouble();
      final freq = 140.0 * (1.0 - p) + 40.0;
      kickPhase += freq / sampleRate;
      final wave = triangleWave(kickPhase) * 0.45;
      samples[beatSample + i] += wave * env;
    }

    // Snare (Noise burst) on beats 1 and 3 of each 4-beat bar (b == 1 or b == 3)
    if (beat % 2 == 1) {
      final snareSamples = (0.075 * sampleRate).toInt();
      for (int i = 0; i < snareSamples && (beatSample + i) < totalSamples; i++) {
        final env = pow(1.0 - (i / snareSamples), 2.5).toDouble();
        final noise = (rand.nextDouble() * 2.0 - 1.0) * 0.28;
        samples[beatSample + i] += noise * env;
      }
    }

    // Hi-hat (Very short tick) on the upbeat
    final upbeatSample = beatSample + ((beatSec * 0.5) * sampleRate).toInt();
    final hatSamples = (0.02 * sampleRate).toInt();
    for (int i = 0; i < hatSamples && (upbeatSample + i) < totalSamples; i++) {
      final env = pow(1.0 - (i / hatSamples), 2.0).toDouble();
      final noise = (rand.nextDouble() * 2.0 - 1.0) * 0.15;
      samples[upbeatSample + i] += noise * env;
    }
  }

  // Master Normalization & Soft Limiter
  double maxPeak = 0.0001;
  for (int i = 0; i < totalSamples; i++) {
    if (samples[i].abs() > maxPeak) maxPeak = samples[i].abs();
  }
  final gain = 0.85 / maxPeak;
  for (int i = 0; i < totalSamples; i++) {
    samples[i] = (samples[i] * gain).clamp(-1.0, 1.0);
  }

  return buildWav(samples, sampleRate: sampleRate);
}

/// 9. Victory: Triumphant retro 8-bit arcade championship fanfare jingle (~1.85s)
Uint8List generateVictorySfx() {
  const sampleRate = 22050;
  const duration = 1.85;
  final totalSamples = (sampleRate * duration).toInt();
  final samples = List<double>.filled(totalSamples, 0.0);

  // Notes: [startTime, duration, frequency, harmonyFreq]
  // Upbeat victorious C major fanfare
  final notes = [
    [0.00, 0.12, 392.00, 261.63], // G4 + C4
    [0.13, 0.12, 523.25, 329.63], // C5 + E4
    [0.26, 0.12, 659.25, 392.00], // E5 + G4
    [0.39, 0.28, 783.99, 523.25], // G5 + C5 (hold)
    [0.70, 0.12, 659.25, 392.00], // E5 + G4
    [0.83, 0.12, 783.99, 523.25], // G5 + C5
    [0.96, 0.88, 1046.50, 659.25], // C6 + E5 (Grand triumphant hold!)
  ];

  for (final n in notes) {
    final start = (n[0] * sampleRate).toInt();
    final dur = (n[1] * sampleRate).toInt();
    final fLead = n[2];
    final fHarm = n[3];

    double phaseLead = 0.0;
    double phaseHarm = 0.0;

    for (int i = 0; i < dur && (start + i) < totalSamples; i++) {
      final p = i / dur;
      final env = pow(1.0 - p, 0.6).toDouble();

      // Celebratory vibrato on long holds
      final vibrato = dur > 0.4 ? sin(p * 18.0 * pi) * 8.0 : 0.0;

      phaseLead += (fLead + vibrato) / sampleRate;
      phaseHarm += (fHarm + vibrato * 0.5) / sampleRate;

      final lead = squareWave(phaseLead, duty: 0.4) * 0.55;
      final harm = triangleWave(phaseHarm) * 0.35;

      samples[start + i] += (lead + harm) * env;
    }
  }

  // Celebratory sparkle arpeggio on the sustained climax
  final arps = [1046.50, 1318.51, 1567.98, 2093.00];
  final arpStart = (0.96 * sampleRate).toInt();
  final arpDur = (0.80 * sampleRate).toInt();
  double arpPhase = 0.0;
  for (int i = 0; i < arpDur && (arpStart + i) < totalSamples; i++) {
    final p = i / arpDur;
    final env = pow(1.0 - p, 1.2).toDouble();
    final noteIdx = ((p * 24.0).toInt()) % arps.length;
    arpPhase += arps[noteIdx] / sampleRate;
    final sparkle = squareWave(arpPhase, duty: 0.25) * 0.20;
    samples[arpStart + i] += sparkle * env;
  }

  // Limiter
  double peak = 0.0001;
  for (int i = 0; i < totalSamples; i++) {
    if (samples[i].abs() > peak) peak = samples[i].abs();
  }
  final gain = 0.88 / peak;
  for (int i = 0; i < totalSamples; i++) {
    samples[i] = (samples[i] * gain).clamp(-1.0, 1.0);
  }

  return buildWav(samples, sampleRate: sampleRate);
}

/// 10. Defeat: Retro 8-bit sad minor descending game over jingle (~1.65s)
Uint8List generateDefeatSfx() {
  const sampleRate = 22050;
  const duration = 1.65;
  final totalSamples = (sampleRate * duration).toInt();
  final samples = List<double>.filled(totalSamples, 0.0);

  // Sad descending minor motif
  final notes = [
    [0.00, 0.22, 659.25], // E5
    [0.24, 0.22, 622.25], // D#5
    [0.48, 0.22, 587.33], // D5
    [0.72, 0.30, 554.37], // C#5
    [1.04, 0.60, 261.63], // C4 (slow downward pitch slide to deep low note)
  ];

  for (final n in notes) {
    final start = (n[0] * sampleRate).toInt();
    final dur = (n[1] * sampleRate).toInt();
    final baseFreq = n[2];

    double phase = 0.0;
    for (int i = 0; i < dur && (start + i) < totalSamples; i++) {
      final p = i / dur;
      final env = pow(1.0 - p, 1.2).toDouble();

      // Downward pitch slide on final low note
      final freq = (baseFreq == 261.63)
          ? (baseFreq * exp(-p * 1.5))
          : baseFreq;

      phase += freq / sampleRate;
      final wave = triangleWave(phase) * 0.65 + squareWave(phase, duty: 0.15) * 0.35;
      samples[start + i] += wave * env * 0.75;
    }
  }

  return buildWav(samples, sampleRate: sampleRate);
}

/// 11. Point Scored: Retro 8-bit cheerful 2-tone reward chime (~0.22s)
Uint8List generatePointScoredSfx() {
  const sampleRate = 22050;
  const duration = 0.22;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];

  // Fast 2-note reward: D5 (587.33) -> A5 (880.00)
  double phase1 = 0.0;
  double phase2 = 0.0;
  for (int i = 0; i < count; i++) {
    final t = i / sampleRate;
    final progress = i / count;
    final env = pow(1.0 - progress, 1.6).toDouble();

    if (t < 0.08) {
      phase1 += 587.33 / sampleRate;
      final w = squareWave(phase1, duty: 0.4) * 0.6 + triangleWave(phase1) * 0.4;
      samples.add(w * env * 0.8);
    } else {
      phase2 += 880.00 / sampleRate;
      final w = squareWave(phase2, duty: 0.3) * 0.7 + triangleWave(phase2) * 0.3;
      samples.add(w * env * 0.85);
    }
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 12. Fault / Violation: Retro arcade double-buzz alert whistle (~0.25s)
Uint8List generateFaultSfx() {
  const sampleRate = 22050;
  const duration = 0.25;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];

  double phase = 0.0;
  for (int i = 0; i < count; i++) {
    final t = i / sampleRate;
    // 2 buzz pulses: 0.0 to 0.10s, then 0.13 to 0.24s
    double env = 0.0;
    if (t >= 0.0 && t < 0.10) {
      env = pow(1.0 - (t / 0.10), 1.2).toDouble();
    } else if (t >= 0.13 && t < 0.24) {
      env = pow(1.0 - ((t - 0.13) / 0.11), 1.2).toDouble();
    }

    // Harsh dissonant retro buzzer (145 Hz + 218 Hz)
    phase += 145.0 / sampleRate;
    final bz1 = squareWave(phase, duty: 0.3);
    final bz2 = squareWave(phase * 1.5, duty: 0.7);
    final sample = (bz1 * 0.5 + bz2 * 0.5) * env * 0.75;
    samples.add(sample);
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 13. Coin Earn / Shop Purchase: Iconic retro 8-bit twin-chime (~0.22s)
Uint8List generateCoinSfx() {
  const sampleRate = 22050;
  const duration = 0.22;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];

  // B5 (987.77 Hz) for 0.055s -> jump to E6 (1318.51 Hz)
  double phase1 = 0.0;
  double phase2 = 0.0;
  for (int i = 0; i < count; i++) {
    final t = i / sampleRate;
    if (t < 0.055) {
      final env = pow(1.0 - (t / 0.055), 0.5).toDouble();
      phase1 += 987.77 / sampleRate;
      final w = squareWave(phase1, duty: 0.5) * 0.7 + triangleWave(phase1) * 0.3;
      samples.add(w * env * 0.8);
    } else {
      final p = (t - 0.055) / (duration - 0.055);
      final env = pow(1.0 - p, 1.8).toDouble();
      phase2 += 1318.51 / sampleRate;
      final w = squareWave(phase2, duty: 0.4) * 0.75 + triangleWave(phase2) * 0.25;
      samples.add(w * env * 0.85);
    }
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 14. Serve Launch: Energetic rising underhand serve whoosh (~0.16s)
Uint8List generateServeSfx() {
  const sampleRate = 22050;
  const duration = 0.16;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];
  final rand = Random(404);

  double phase = 0.0;
  for (int i = 0; i < count; i++) {
    final p = i / count;
    final env = sin(p * pi);
    // Rising sweep from 220Hz up to 660Hz
    final freq = 220.0 + 440.0 * p;
    phase += freq / sampleRate;

    final tone = triangleWave(phase) * 0.5;
    final air = (rand.nextDouble() * 2.0 - 1.0) * 0.5;
    samples.add((tone + air) * env * 0.75);
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 15. Court Floor Bounce: Distinct hollow acrylic/wood court bounce pop (~0.08s)
Uint8List generateBounceSfx() {
  const sampleRate = 22050;
  const duration = 0.08;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];

  double phase = 0.0;
  for (int i = 0; i < count; i++) {
    final p = i / count;
    final env = pow(1.0 - p, 2.5).toDouble();
    // Warm low-mid thud drop from 260Hz down to 110Hz
    final freq = 260.0 - 150.0 * p;
    phase += freq / sampleRate;
    final wave = triangleWave(phase) * 0.8 + squareWave(phase, duty: 0.3) * 0.2;
    samples.add(wave * env * 0.85);
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 16. Level Up: Ascending multi-tier celebratory power-up fanfare (~0.55s)
Uint8List generateLevelUpSfx() {
  const sampleRate = 22050;
  const duration = 0.55;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];

  final notes = [523.25, 659.25, 783.99, 987.77, 1046.50, 1318.51, 1567.98];
  double phase = 0.0;
  for (int i = 0; i < count; i++) {
    final p = i / count;
    final noteIdx = ((p * 12.0).toInt()).clamp(0, notes.length - 1);
    final freq = notes[noteIdx];
    final env = pow(1.0 - (p > 0.6 ? (p - 0.6) / 0.4 : 0.0), 1.5).toDouble();

    phase += freq / sampleRate;
    final wave = squareWave(phase, duty: 0.35) * 0.7 + triangleWave(phase) * 0.3;
    samples.add(wave * env * 0.8);
  }
  return buildWav(samples, sampleRate: sampleRate);
}

/// 17. Countdown: Crisp 8-bit electronic pulse beep (~0.12s)
Uint8List generateCountdownSfx() {
  const sampleRate = 22050;
  const duration = 0.12;
  final count = (sampleRate * duration).toInt();
  final samples = <double>[];

  double phase = 0.0;
  for (int i = 0; i < count; i++) {
    final p = i / count;
    final env = pow(1.0 - p, 2.0).toDouble();
    phase += 660.0 / sampleRate;
    final wave = squareWave(phase, duty: 0.5) * 0.8;
    samples.add(wave * env * 0.75);
  }
  return buildWav(samples, sampleRate: sampleRate);
}
