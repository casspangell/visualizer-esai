import processing.sound.*;
SoundFile soundfile;

// Audio
FFT fft;
int bands = 512;
float[] spectrum = new float[bands];

// Circles data
int numCircles = 30;
float[] circleX, circleY, circleSize, explosionFactor;
float[] speedX, speedY;

// Color variables
float redVal = 0;
float greenVal = 0;
float blueVal = 0;

void setup() {
  size(640, 360);
  background(0);
  
  // Load the MP3 file
  soundfile = new SoundFile(this, "10-Wut-R-Frends-4.mp3");
  
  // Initialize FFT
  fft = new FFT(this, bands);
  fft.input(soundfile);
  
  // Start playing the sound file
  soundfile.play();

  // Initialize circles with random positions and speeds
  circleX = new float[numCircles];
  circleY = new float[numCircles];
  circleSize = new float[numCircles];
  explosionFactor = new float[numCircles]; // Controls explosion intensity
  speedX = new float[numCircles];
  speedY = new float[numCircles];

  for (int i = 0; i < numCircles; i++) {
    circleX[i] = random(width);
    circleY[i] = random(height);
    circleSize[i] = random(10, 100);
    explosionFactor[i] = 1; // Default no explosion
    speedX[i] = random(-3, 3);
    speedY[i] = random(-3, 3);
  }
}

void draw() {
  // Analyze the audio spectrum
  fft.analyze(spectrum);

  // Detect peaks and adjust colors
  float peakThreshold = 0.08; // Defines an "explosive" moment
  boolean explosionTriggered = false; // Track if an explosion should happen
  
  for (int i = 0; i < bands; i++) {
    if (spectrum[i] > peakThreshold) { // Super sensitive peak detection
      float peak = spectrum[i] * 255;
      explosionTriggered = true; // Trigger explosion
      if (i < bands / 3) {
        redVal = peak;
      } else if (i < 2 * bands / 3) {
        greenVal = peak;
      } else {
        blueVal = peak;
      }
    }
  }

  // Apply explosion effect if triggered
  if (explosionTriggered) {
    for (int i = 0; i < numCircles; i++) {
      explosionFactor[i] = random(3, 6); // Circles grow fast
      speedX[i] = random(-10, 10); // Speed increases randomly
      speedY[i] = random(-10, 10);
    }
  }

  // Smooth transitions by damping colors
  redVal *= 0.7;
  greenVal *= 0.7;
  blueVal *= 0.7;

  // Background fade effect for smoother visuals
  background(0, 20);

  // Draw moving circles with explosion effect
  for (int i = 0; i < numCircles; i++) {
    float peakEffect = spectrum[int(map(i, 0, numCircles, 0, bands))] * 500;
    float newSize = circleSize[i] + peakEffect * explosionFactor[i];

    fill(redVal, greenVal, blueVal, 180);
    noStroke();
    ellipse(circleX[i], circleY[i], newSize, newSize);

    // Explosive outward motion
    circleX[i] += speedX[i] * explosionFactor[i];
    circleY[i] += speedY[i] * explosionFactor[i];

    // Reset explosion effect gradually
    explosionFactor[i] *= 0.9; // Shrinks back down
    if (explosionFactor[i] < 1) {
      explosionFactor[i] = 1; // Reset to normal state
    }

    // Keep circles within bounds
    if (circleX[i] < 0 || circleX[i] > width) {
      speedX[i] = random(-5, 5);
      circleX[i] = constrain(circleX[i], 0, width);
    }
    if (circleY[i] < 0 || circleY[i] > height) {
      speedY[i] = random(-5, 5);
      circleY[i] = constrain(circleY[i], 0, height);
    }
  }
}

void keyPressed() {
  if (key == 'p' || key == 'P') {
    soundfile.pause();
  } else if (key == 'r' || key == 'R') {
    soundfile.play();
  }
}
