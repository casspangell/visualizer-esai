import processing.sound.*;
SoundFile soundfile;

// Audio
FFT fft;
int bands = 512;
float[] spectrum = new float[bands];

// Color variables
float redVal = 0;
float greenVal = 0;
float blueVal = 0;

void setup() {
  size(640, 360);
  background(0);
  
  // Initialize the soundfile
  soundfile = new SoundFile(this, "10-Wut-R-Frends-4.mp3");
  
  // Initialize FFT and link it to the soundfile
  fft = new FFT(this, bands);
  fft.input(soundfile);
  
  // Play the soundfile
  soundfile.play();
}

void draw() {
  // Analyze the audio spectrum
  fft.analyze(spectrum);

  // Detect peaks and adjust background color
  for (int i = 0; i < bands; i++) {
    if (spectrum[i] > 0.1) { // Threshold for detecting peaks
      float peak = spectrum[i] * 255; // Scale peak to 0-255
      if (i < bands / 3) {
        redVal = peak; // Low frequencies affect red
      } else if (i < 2 * bands / 3) {
        greenVal = peak; // Mid frequencies affect green
      } else {
        blueVal = peak; // High frequencies affect blue
      }
    }
  }

  // Smooth transitions by damping colors
  redVal *= 0.9;
  greenVal *= 0.9;
  blueVal *= 0.9;

  // Update the background color
  background(redVal, greenVal, blueVal);

  // Example visualization of spectrum
  stroke(255);
  for (int i = 0; i < bands; i++) {
    float x = map(i, 0, bands, 0, width);
    float h = spectrum[i] * height * 10; // Scale for visualization
    line(x, height, x, height - h);
  }
}

void keyPressed() {
  if (key == 'p' || key == 'P') {
    soundfile.pause(); // Pause playback
  } else if (key == 'r' || key == 'R') {
    soundfile.play(); // Resume playback
  }
}
