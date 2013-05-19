// imports for minim, serial, and arduino //
import ddf.minim.*;
import ddf.minim.analysis.*;
import processing.serial.*;
import cc.arduino.*;
// end imports //

int desiredWidth = 900; // desired widht of the window
boolean hasArd = false; // is there an arduino connected?
//hasArd = false;

/* color variables */
int iWhite = 0x00000000;
int iRed = 0xFFFF0000;
int iGreen = 0xFF00FF00;
int iBlue = 0xFF0000FF;
/* end color variables */

/* LED pins and corresponding colors */
int[] ledPins = {2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}; 
int[] ledColor = {iRed, iBlue, iGreen, iBlue, iRed};
/*end LED pins and colors */

/*sensitivity and time on */
int sensitivity = 200;
int minTimeOn = 5;

// do not edit these variables! //
Arduino arduino; // creates arduino variable
int[] lastFired = new int[ledPins.length];
int frameWidth = (desiredWidth - (desiredWidth % ledColor.length))  + 1;
int flasherWidth = frameWidth/ledPins.length;
int flasherHeight = flasherWidth;
int frameHeight = 200 + flasherHeight + 1;
String mode;
String source;
Minim minim;
AudioInput in;
AudioPlayer song;
BeatDetect beat;
/* below is the program */

//Used to stop flashing if the only signal on the line is random noise
boolean hasInput = false;
float tol = 0.005;

void setup() {
  background (0);
  //Uncomment the mode/source pair for the desired input

  //Shoutcast radio stream
  //mode = "radio"; source = "http://scfire-ntc-aa05.stream.aol.com:80/stream/1018";

  // File playback
  //mode = "file"; source = "/music/Goodbye.mp3";
  
  // mic/line in
  mode = "mic"; source = "";

  size(frameWidth, frameHeight, P2D);

  if(hasArd)
    println(Arduino.list());
    
  minim = new Minim(this);
  if (hasArd) arduino = new Arduino(this, Arduino.list()[6]);

  for (int i = 0; i < ledPins.length; i++) {
    if (hasArd) arduino.pinMode(ledPins[i], Arduino.OUTPUT);
  }

  minim = new Minim(this);

  if (mode == "file" || mode == "radio") {
    song = minim.loadFile(source, 2048);
    song.play();
    beat = new BeatDetect(song.bufferSize(), song.sampleRate());
    beat.setSensitivity(sensitivity);
  } 
  else if (mode == "mic") {
    in = minim.getLineIn(Minim.STEREO, 2048);
    beat = new BeatDetect(in.bufferSize(), in.sampleRate());
    beat.setSensitivity(sensitivity);
  }
}

void draw() {
  if (mode == "file" || mode == "radio") {
    beat.detect(song.mix);
    drawWaveForm((AudioSource)song);
  } 
  else if (mode == "mic") {
    beat.detect(in.mix); 
    drawWaveForm((AudioSource)in);
  }

  if (hasInput) { //hasInput is set within drawWaveForm
    for (int i=0; i<ledPins.length; i++) {
      if ( beat.isRange( i+1, i+1, 1) ) {
        if (hasArd) arduino.digitalWrite(ledPins[i], Arduino.HIGH);
        if(i < ledColor.length)
          fill(ledColor[i]);
        else
          fill(255);
        rect(flasherWidth*i, 200, flasherWidth, flasherHeight);
        lastFired[i] = millis();
      } 
      else {
        if ((millis() - lastFired[i]) > minTimeOn) {
          fill(0);
          rect(flasherWidth*i, 200, flasherWidth, flasherHeight);
          if (hasArd) arduino.digitalWrite(ledPins[i], Arduino.LOW);
        }
      }
    }
  }
}  //End draw method

//Display the input waveform
//This method sets 'hasInput' - if any sample in the signal has a value
//larger than 'tol,' there is a signal and the lights should flash.
//Otherwise, only noise is present and the lights should stay off.
void drawWaveForm(AudioSource src) {
  //background(0);
  fill(0);
  rect(0, 0, width-1, 200);
  stroke(255);

  hasInput = false;

  for (int i = 0; i < src.bufferSize() - 1; i++)
  {
    line(i, 50 + src.left.get(i)*50, i+1, 50 + src.left.get(i+1)*50);
    line(i, 150 + src.right.get(i)*50, i+1, 150 + src.right.get(i+1)*50);

    if (!hasInput && (abs(src.left.get(i)) > tol || abs(src.right.get(i)) > tol)) {
      hasInput = true;
    }
  }
}

void resetPins() {
  for (int i=0; i<ledPins.length; i++) {
    if (hasArd) arduino.digitalWrite(ledPins[i], Arduino.LOW);
  }
}

void stop() {
  resetPins();  
  if (mode == "mic") {
    in.close();
  }  
  minim.stop();
  super.stop();
}

