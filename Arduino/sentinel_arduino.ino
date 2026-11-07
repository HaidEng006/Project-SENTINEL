#include <Servo.h>

// Pin assignments
const int trigPin = 10;
const int echoPin = 11;
const int servoPin = 9;

// Create servo object
Servo radarServo;

// Measure distance using ultrasonic sensor
float measureDistance() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);

  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);

  long duration = pulseIn(echoPin, HIGH, 30000);

  if (duration == 0) {
    return -1;
  }

  float distance = duration * 0.0343 / 2;

  return distance;
}

void setup() {
  Serial.begin(9600);

  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);

  radarServo.attach(servoPin);
}

// Main scanning loop
void loop() {

  // Sweep from left to right
  for (int angle = 15; angle <= 165; angle += 2) {
    radarServo.write(angle);
    delay(30);

    float distance = measureDistance();

    Serial.print(angle);
    Serial.print(",");
    Serial.println(distance);
  }

  // Sweep from right to left
  for (int angle = 165; angle >= 15; angle -= 2) {
    radarServo.write(angle);
    delay(30);

    float distance = measureDistance();

    Serial.print(angle);
    Serial.print(",");
    Serial.println(distance);
  }
}
