# Project-SENTINEL
Arduino-based ultrasonic radar detection system
## 01 | Project Overview

**Project SENTINEL** is an Arduino-based ultrasonic radar detection system designed to scan its surroundings, measure object distances and visualise the results through a custom-built radar interface.

The system rotates an ultrasonic sensor across a defined angular range, collecting distance measurements and transmitting the data to a computer through serial communication.

## 02 | Hardware Components

| Component | Purpose |
|:---|:---|
| Arduino Uno-compatible board | Main microcontroller |
| HC-SR04 ultrasonic sensor | Distance measurement |
| SG90 servo motor | Sensor rotation |
| Jumper wires | Electrical connections |
| USB cable | Power and serial communication |
| Cardboard mounting structure | Physical sensor support |

## 03 | Software & Technologies

| Technology | Application |
|:---|:---|
| Arduino IDE (C++) | Hardware control and sensor measurements |
| Processing (Java) | Radar interface and visualisation |
| Serial communication | Transfers sensor data |
| CSV | Data logging |

## 04 | System Features

- **Ultrasonic detection:** Measures distances to nearby objects.
- **Automated scanning:** Servo motor rotates the sensor.
- **Live visualisation:** Displays measurements through a radar-style interface.
- **Proximity warnings:** Computer-based audio alerts.
- **Data logging:** Records measurements for further analysis.

## 05 | Repository Structure

```text
Project-SENTINEL/
├── Arduino/
│   └── sentinel_arduino.ino
├── Processing/
│   └── sentinel_processing.pde
├── Images/
├── Documentation/
└── README.md
