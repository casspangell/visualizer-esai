import processing.sound.*;

SoundFile soundfile;
FFT fft;
int bands = 512;
float[] spectrum = new float[bands];

// Terrain mapping for liquid motion effect
int cols, rows;
int scl = 20; // Slightly smaller scale for more details
int w = 1080; // Terrain width
int h = 1080; // Terrain height
float flying = 0;
float[][] terrain;

// Pulse and glitch effect variables
float bassPulse = 0;
float glitchIntensity = 0;
float strobeIntensity = 0; // New variable to smooth high-frequency flashes
float energyLevel = 0;

void setup() {
  size(1080, 1080, P3D);
  background(0);
  
  // Load the audio file
  soundfile = new SoundFile(this, "10-Wut-R-Frends-4.mp3");
  
  // Initialize FFT
  fft = new FFT(this, bands);
  fft.input(soundfile);
  
  // Start playing the sound
  soundfile.loop();
  
  // Setup terrain for liquid effect
  cols = w / scl;
  rows = h / scl;
  terrain = new float[cols][rows];
}

void draw() {
  // Analyze the audio spectrum
  fft.analyze(spectrum);

  // Compute overall energy level
  float sum = 0;
  for (int i = 0; i < bands; i++) {
    sum += spectrum[i];
  }
  energyLevel = lerp(energyLevel, sum * 50, 0.05);

  // Background with intensity-based fade effect
  background(0);
  fill(0, 30 + energyLevel * 0.1);
  rect(0, 0, width, height);

  // Audio frequency response (SMOOTHED with lerp)
  float bass = lerp(bassPulse, spectrum[5] * 300, 0.05 + energyLevel * 0.001); // Increased smoothing when energy is high
  float mids = lerp(glitchIntensity, spectrum[100] * 100, 0.06 + energyLevel * 0.002); // More glitch with higher energy
  float highs = lerp(strobeIntensity, spectrum[300] * 200, 0.02 + energyLevel * 0.003); // Strobes scale with energy

  bassPulse = bass;
  glitchIntensity = mids;
  strobeIntensity = highs;

  // **BASS: Liquid Terrain Pulse (Dampened at Low Energy, Wild at High Energy)**
  flying -= 0.015 + energyLevel * 0.002; // More chaotic movement with more energy

  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      float distance = dist(x, y, cols / 2, rows / 2);
      terrain[x][y] = map(noise(x * 0.1, y * 0.1, flying), 0, 1, -40 - energyLevel * 0.5, 40 + energyLevel * 0.5) + bassPulse * sin(distance * 0.1);
    }
  }

  // **GLITCH: Snare/Clap Flickering (Goes Crazy with High Energy)**
  if (random(1) < glitchIntensity * (0.004 + energyLevel * 0.001)) {  // More frequent glitching at higher energy
    strokeWeight(random(1, 4 + energyLevel * 0.5));
  } else {
    strokeWeight(1);
  }

  // **HIGH-FREQUENCY STROBES (Maximum Chaos on High Energy Levels)**
  if (strobeIntensity > 10) {  
    background(255, min(255, strobeIntensity * (1.5 + energyLevel * 0.1)));  // Blinding flashes when energy is max
  }

  // Draw terrain as filled mesh covering the screen
  pushMatrix();
  translate(0, 0, 0);  // Reset translation to keep it fully flat
  
  stroke(255);
  noStroke();
  
  for (int y = 0; y < rows - 1; y++) {
    beginShape(TRIANGLE_STRIP);
    for (int x = 0; x < cols; x++) {
      float z1 = terrain[x][y];
      float z2 = terrain[x][y + 1];
      
      float colorMix = map(z1, -40, 40, 0, 1);
      if (energyLevel > 200) {  // When energy is super high, go wild with colors
        fill(lerpColor(color(255, 0, 0), color(0, 255, 255), colorMix));
      } else {
        fill(lerpColor(color(0, 255, 255), color(255, 0, 150), colorMix)); // Default colors
      }
      
      vertex(x * scl, y * scl, z1);
      vertex(x * scl, (y + 1) * scl, z2);
    }
    endShape();
  }
  
  popMatrix();
}
