
import processing.serial.*;
import java.io.PrintWriter;
import javax.sound.sampled.*;

Serial arduino;
PrintWriter logFile;

// RADAR CONFIGURATION
final int MAX_RANGE = 150;
final int MIN_ANGLE = 15;
final int MAX_ANGLE = 165;
final float RADAR_RADIUS = 280;

// LIVE DATA
volatile float currentAngle = 15;
volatile float currentDistance = -1;
float nearestDistance = -1;

// TARGET MEMORY
float[] targetDistance = new float[181];
float[] filteredDistance = new float[181];
int[] targetTime = new int[181];

// SWEEP TRAIL
float[] sweepTrail = new float[14];

// SYSTEM STATUS
int detectionCount = 0;
boolean connected = false;
boolean proximityAlert = false;

// ALARM
volatile boolean alarmEnabled = false;
volatile boolean alarmPlaying = false;
volatile int alarmInterval = 800;
int lastAlarmTime = 0;

// LOGGING
int lastLogFlush = 0;

void setup() {
  size(1100, 780);
  smooth(8);

  surface.setTitle("SENTINEL V5 - COMMAND CENTRE");

  for (int i = 0; i <= 180; i++) {
    targetDistance[i] = -1;
    filteredDistance[i] = -1;
  }

  for (int i = 0; i < sweepTrail.length; i++) {
    sweepTrail[i] = 15;
  }

  try {
    logFile = createWriter("sentinel_data.csv");
    logFile.println("time_ms,angle,distance_cm");
  }
  catch (Exception e) {
    println("Logging unavailable: " + e);
  }

  try {
    arduino = new Serial(this, "COM10", 9600);
    arduino.bufferUntil('\n');
    connected = true;
    println("SENTINEL ONLINE");
  }
  catch (Exception e) {
    println("Arduino connection failed: " + e);
    connected = false;
  }
}

void draw() {
  background(2, 8, 10);

  drawBackgroundGrid();
  drawHeader();
  drawRadar();
  drawInformationPanels();
  drawFooter();
  drawScanlines();

  updateAlarm();

  if (logFile != null && millis() - lastLogFlush > 1000) {
    logFile.flush();
    lastLogFlush = millis();
  }
}

void drawBackgroundGrid() {
  stroke(0, 35, 30, 65);
  strokeWeight(1);

  for (int x = 0; x < width; x += 40) {
    line(x, 0, x, height);
  }

  for (int y = 0; y < height; y += 40) {
    line(0, y, width, y);
  }
}

void drawHeader() {
  fill(0, 255, 130);
  textAlign(LEFT);
  textSize(30);
  text("SENTINEL", 30, 43);

  fill(0, 170, 100);
  textSize(12);
  text("AUTONOMOUS ULTRASONIC SURVEILLANCE SYSTEM", 32, 65);

  stroke(0, 120, 75);
  line(25, 85, width - 25, 85);

  textAlign(RIGHT);
  textSize(13);

  fill(connected ? color(0, 255, 100) : color(255, 40, 40));
  text(connected ? "SYSTEM ONLINE" : "CONNECTION LOST",
       width - 30, 42);

  fill(0, 170, 100);
  text("COM10 / 9600 BAUD", width - 30, 64);
}

void drawRadar() {
  pushMatrix();
  translate(420, 680);

  // RANGE RINGS
  noFill();
  stroke(0, 110, 65);
  strokeWeight(1.5);

  for (int d = 50; d <= MAX_RANGE; d += 50) {
    float r = map(d, 0, MAX_RANGE, 0, RADAR_RADIUS);
    arc(0, 0, r * 2, r * 2, PI, TWO_PI);
  }

  // GRID LINES
  stroke(0, 85, 50);

  for (int a = 0; a <= 180; a += 30) {
    float x = RADAR_RADIUS * cos(radians(a));
    float y = -RADAR_RADIUS * sin(radians(a));
    line(0, 0, x, y);
  }

  // RANGE LABELS
  fill(0, 180, 100);
  textAlign(CENTER);
  textSize(11);
  text("50 CM", 0, -95);
  text("100 CM", 0, -190);
  text("150 CM", 0, -285);

  // SWEEP TRAIL
  for (int i = 0; i < sweepTrail.length; i++) {
    float a = sweepTrail[i];
    float alpha = map(i, 0, sweepTrail.length - 1, 5, 120);

    stroke(0, 255, 100, alpha);
    strokeWeight(map(i, 0, sweepTrail.length - 1, 1, 3));

    line(0, 0,
         RADAR_RADIUS * cos(radians(a)),
         -RADAR_RADIUS * sin(radians(a)));
  }

  // TARGET BLIPS
  detectionCount = 0;
  nearestDistance = -1;

  for (int a = MIN_ANGLE; a <= MAX_ANGLE; a++) {
    float d = targetDistance[a];

    if (d > 0 && d <= MAX_RANGE) {
      int age = millis() - targetTime[a];

      if (age < 4000) {
        detectionCount++;

        if (nearestDistance < 0 || d < nearestDistance) {
          nearestDistance = d;
        }

        float r = map(d, 0, MAX_RANGE, 0, RADAR_RADIUS);
        float x = r * cos(radians(a));
        float y = -r * sin(radians(a));

        float fade = map(age, 0, 4000, 255, 0);

        noStroke();
        fill(255, 0, 0, fade * 0.15);
        ellipse(x, y, 32, 32);

        fill(255, 15, 15, fade * 0.4);
        ellipse(x, y, 19, 19);

        fill(255, 40, 40, fade);
        ellipse(x, y, 8, 8);
      }
    }
  }

  // GREEN SWEEP
  stroke(0, 255, 110);
  strokeWeight(3);

  line(0, 0,
       RADAR_RADIUS * cos(radians(currentAngle)),
       -RADAR_RADIUS * sin(radians(currentAngle)));

  noStroke();
  fill(0, 255, 110);
  ellipse(0, 0, 9, 9);

  popMatrix();
}

void drawInformationPanels() {
  fill(4, 18, 18);
  stroke(0, 110, 70);
  rect(735, 125, 335, 490, 8);

  fill(0, 255, 130);
  textAlign(LEFT);
  textSize(17);
  text("SYSTEM TELEMETRY", 755, 158);

  stroke(0, 90, 60);
  line(755, 175, 1050, 175);

  fill(0, 180, 110);
  textSize(12);
  text("SERVO ANGLE", 755, 210);

  fill(0, 255, 130);
  textSize(27);
  text(nf(currentAngle, 0, 0) + " DEG", 755, 245);

  fill(0, 180, 110);
  textSize(12);
  text("CURRENT DISTANCE", 755, 290);

  fill(0, 255, 130);
  textSize(27);

  if (currentDistance > 0) {
    text(nf(currentDistance, 0, 1) + " CM", 755, 325);
  } else {
    text("NO ECHO", 755, 325);
  }

  stroke(0, 90, 60);
  line(755, 350, 1050, 350);

  fill(0, 180, 110);
  textSize(12);
  text("ACTIVE DETECTION ZONES", 755, 385);

  fill(255, 40, 40);
  textSize(30);
  text(detectionCount, 755, 425);

  fill(0, 180, 110);
  textSize(12);
  text("NEAREST TARGET", 755, 465);

  fill(255, 50, 50);
  textSize(22);

  if (nearestDistance > 0) {
    text(nf(nearestDistance, 0, 1) + " CM", 755, 500);
  } else {
    text("NONE", 755, 500);
  }

  stroke(0, 90, 60);
  line(755, 525, 1050, 525);

  if (proximityAlert) {
    fill(120, 0, 0);
    rect(755, 545, 295, 42, 5);

    fill(255, 60, 60);
    textSize(16);
    text("PROXIMITY WARNING", 770, 572);
  } else {
    fill(0, 180, 90);
    textSize(14);
    text("SCANNING NOMINAL", 755, 572);
  }

  fill(0, 180, 110);
  textSize(12);
  text("MAXIMUM RANGE: 150 CM", 755, 645);
}

void drawFooter() {
  stroke(0, 110, 70);
  line(25, 730, width - 25, 730);

  fill(0, 150, 90);
  textAlign(LEFT);
  textSize(11);
  text("SENTINEL V5 / AUTONOMOUS MODE", 30, 750);

  textAlign(RIGHT);
  text("LIVE SENSOR DATA / AUTO LOGGING",
       width - 30, 750);
}

void drawScanlines() {
  stroke(0, 0, 0, 25);

  for (int y = 0; y < height; y += 4) {
    line(0, y, width, y);
  }
}

// DRAMATIC SYNTHESISED ALARM
void updateAlarm() {
  if (!alarmEnabled || alarmPlaying) return;

  if (millis() - lastAlarmTime >= alarmInterval) {
    lastAlarmTime = millis();
    alarmPlaying = true;

    Thread alarmThread = new Thread(() -> {
      try {
        dramaticAlarm();
      }
      finally {
        alarmPlaying = false;
      }
    });

    alarmThread.start();
  }
}

void dramaticAlarm() {
  final int sampleRate = 44100;
  final int duration = 450;

  SourceDataLine line = null;

  try {
    AudioFormat format = new AudioFormat(
      sampleRate, 16, 1, true, false
    );

    line = AudioSystem.getSourceDataLine(format);
    line.open(format);
    line.start();

    byte[] audio = new byte[sampleRate * duration / 1000 * 2];
    int samples = audio.length / 2;

    for (int i = 0; i < samples; i++) {
      float t = (float)i / sampleRate;
      float progress = (float)i / samples;

      // Descending siren tone
      float frequency = 1050 - 450 * progress;

      double tone1 = Math.sin(2 * Math.PI * frequency * t);
      double tone2 = Math.sin(2 * Math.PI * 150 * t);

      // Electronic pulse
      double pulse = 0.65 + 0.35 *
        Math.sin(2 * Math.PI * 5 * t);

      double sound = (tone1 * 0.7 + tone2 * 0.3) * pulse;

      // Fade at beginning and end
      double envelope = Math.min(
        1.0,
        Math.min(progress * 12, (1 - progress) * 12)
      );

      short value = (short)(sound * envelope * 18000);

      audio[i * 2] = (byte)(value & 0xff);
      audio[i * 2 + 1] = (byte)((value >> 8) & 0xff);
    }

    line.write(audio, 0, audio.length);
    line.drain();

  }
  catch (Exception e) {
    println("Audio alarm error: " + e);
  }
  finally {
    if (line != null) {
      line.stop();
      line.close();
    }
  }
}

// SERIAL DATA
void serialEvent(Serial port) {
  String data = port.readStringUntil('\n');

  if (data == null) return;

  String[] values = split(trim(data), ',');

  if (values.length != 2) return;

  try {
    float angle = float(values[0]);
    float distance = float(values[1]);

    if (angle < MIN_ANGLE || angle > MAX_ANGLE) return;

    currentAngle = angle;
    currentDistance = distance;

    // UPDATE SWEEP TRAIL
    for (int i = 0; i < sweepTrail.length - 1; i++) {
      sweepTrail[i] = sweepTrail[i + 1];
    }

    sweepTrail[sweepTrail.length - 1] = angle;

    int index = round(angle);

    if (distance > 0 && distance <= 400) {

      if (filteredDistance[index] < 0) {
        filteredDistance[index] = distance;
      } else {
        filteredDistance[index] =
          0.65 * filteredDistance[index] + 0.35 * distance;
      }

      targetDistance[index] = filteredDistance[index];
      targetTime[index] = millis();

      proximityAlert = distance <= 20;

      // ALARM SPEED
      if (distance <= 10) {
        alarmInterval = 250;
      } else {
        alarmInterval = 800;
      }

      alarmEnabled = distance <= 20;

      // AUTOMATIC LOGGING
      if (logFile != null) {
        logFile.println(
          millis() + "," + angle + "," + distance
        );
      }

    } else {
      targetDistance[index] = -1;
      proximityAlert = false;
      alarmEnabled = false;
      currentDistance = -1;
    }
  }
  catch (Exception e) {
    println("Invalid sensor reading: " + data);
  }
}

// SAFE FILE CLOSURE
void exit() {
  if (logFile != null) {
    logFile.flush();
    logFile.close();
  }

  super.exit();
}
