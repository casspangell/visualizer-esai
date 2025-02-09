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
float strobeIntensity = 0;
float energyLevel = 0;
boolean slowPhase = false;
float slowTimer = 0;
boolean dropDetected = false;
float lastEnergyLevel = 0;
float slowPhaseThreshold = 80;
float slowPhaseDuration = 0;
color currentColor;
color targetColor;
float colorLerpFactor = 0.1;
float bassDistortion = 0;
float midShake = 0;
float highFlicker = 0;
boolean sweepDetected = false;
float sweepTimer = 0;
boolean molassesPhase = false;
float molassesTimer = 0;
float molassesIntensityThreshold = 0.15;
float molassesSlowFactor = 0.002;
boolean bassHoldPhase = false;
float bassHoldTimer = 0;
float bassHoldThreshold = 0.2;
float bassHoldSlowFactor = 0.005;
float sweepBlurAmount = 0;

void setup() {
  size(1080, 1080, P3D);
  background(0);
  
  // Load the audio file
  soundfile = new SoundFile(this, "Project-183.mp3");
  
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
  


  // Detect a drop to trigger slow phase dynamically
  if ((lastEnergyLevel - energyLevel > slowPhaseThreshold) && !slowPhase) {
    dropDetected = true;
    slowPhase = true;
    slowTimer = millis();
    slowPhaseDuration = map(lastEnergyLevel - energyLevel, 0, 200, 1000, 4000); // Slow phase duration scales with drop intensity
  }
  lastEnergyLevel = energyLevel;
  
  // Detect sweeping woosh sound
  float sweepIntensity = spectrum[150] + spectrum[200] + spectrum[250];
  if (sweepIntensity > 0.3 && !sweepDetected) {
    sweepDetected = true;
    sweepTimer = millis();
    sweepBlurAmount = 10;
  }
  if (sweepDetected) {
    sweepBlurAmount = lerp(sweepBlurAmount, 0, 0.02);
    if (millis() - sweepTimer > 3000) {
      sweepDetected = false;
    }
  }

  // Ensure slow phase adapts to music intensity
  if (dropDetected && millis() - slowTimer > slowPhaseDuration) { // Dynamic slow phase duration
    slowPhase = false;
    dropDetected = false;
  }

  // Background with intensity-based fade effect
  background(0);
  fill(0, 30 + energyLevel * 0.1);
  rect(0, 0, width, height);

  // Audio frequency response (SMOOTHED with lerp)
  float intensityFactor = slowPhase ? 0.01 : 1.0; // Reduce intensity during slow phase
  float bass = lerp(bassPulse, spectrum[5] * 300 * intensityFactor, 0.05);
  float mids = lerp(glitchIntensity, spectrum[20] * 10 * intensityFactor, 0.06);
  float highs = lerp(strobeIntensity, spectrum[300] * 200 * intensityFactor, 0.02);

  bassPulse = bass;
  glitchIntensity = mids;
  strobeIntensity = highs;

  // **BASS: Liquid Terrain Pulse (Dampened at Low Energy, Wild at High Energy) following drop speed**
  //flying -= (0.015 + energyLevel * 0.002) * intensityFactor;
  
    // Introduce a bigger pulse effect when bass hits
  bassPulse = lerp(bassPulse, spectrum[5] * 300, 0.15);
  float bassSlowFactor = map(spectrum[5], 0, 1, 0.5, 1.0); // More extreme slow down based on bass intensity
  float terrainSpeedFactor = (sweepDetected) ? 0.3 : bassSlowFactor;
  flying -= (0.015 + energyLevel * 0.002 + bassPulse * 0.06) * terrainSpeedFactor;

  for (int y = 0; y < rows; y++) {
    for (int x = 0; x < cols; x++) {
      float distance = dist(x, y, cols / 2, rows / 2);
      terrain[x][y] = map(noise(x * 0.1, y * 0.1, flying), 0, 1, -40 - energyLevel * 0.5, 40 + energyLevel * 0.5) + bassPulse * sin(distance * 0.1);
    }
  }

  // **GLITCH: Snare/Clap Flickering (Goes Crazy with High Energy)**
  if (!slowPhase && random(1) < glitchIntensity * (0.004 + energyLevel * 0.001)) {
    strokeWeight(random(1, 4 + energyLevel * 0.5));
  } else {
    strokeWeight(1);
  }

  // **HIGH-FREQUENCY STROBES (Maximum Chaos on High Energy Levels)**
  if (!slowPhase && strobeIntensity > 10) {  
    background(255, min(255, strobeIntensity * (1.5 + energyLevel * 0.1)));  
  }

  // Draw terrain as filled mesh covering the screen
  pushMatrix();
  translate(0, 0, 0);
  
  stroke(255);
  noStroke();
  
  for (int y = 0; y < rows - 1; y++) {
    beginShape(TRIANGLE_STRIP);
    for (int x = 0; x < cols; x++) {
      float z1 = terrain[x][y];
      float z2 = terrain[x][y + 1];
      
      float colorMix = map(z1, -40, 40, 0, 1);
      if (!slowPhase && energyLevel > 200) {  
        fill(lerpColor(color(255, 0, 0), color(0, 255, 255), colorMix));
      } else {
        fill(lerpColor(color(0, 255, 255), color(255, 0, 150), colorMix)); 
      }
      
      vertex(x * scl, y * scl, z1);
      vertex(x * scl, (y + 1) * scl, z2);
    }
    endShape();
  }
  
  popMatrix();
}
