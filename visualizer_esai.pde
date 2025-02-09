import processing.sound.*;
SoundFile soundfile;

// Mapping
int cols, rows;
int scl = 30;
int w = 800;
int h = 800;

float flying = 0;
float[][] terrain;

// Audio
FFT fft;
int bands = 512;
float[] spectrum = new float[bands];

void setup() {
  size(640, 360, P3D);
  background(255);
  
  // Initialize the soundfile
  soundfile = new SoundFile(this, "10-Wut-R-Frends.mp3");
  
  // Initialize FFT and link it to the soundfile
  fft = new FFT(this, bands);
  fft.input(soundfile);
  
  // Play the soundfile
  soundfile.play();
}

void draw() {
  // Analyze the audio spectrum
  fft.analyze(spectrum);

  // Example visualization: Display spectrum data
  background(0);
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
