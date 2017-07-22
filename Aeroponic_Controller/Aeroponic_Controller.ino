

/*
 *  Before loading program:
 *  
 *  Tools -> Board -> "Arduino/Genuino Uno"
 *  Tools -> Port -> "USB Port"
 * 
 */


/*

Copyright (c) 2012-2014 RedBearLab

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation 
files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, 
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software 
is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

/*
 *    Chat
 *
 *    Simple chat sketch, work with the Chat iOS/Android App.
 *    Type something from the Arduino serial monitor to send
 *    to the Chat App or vice verse.
 *
 */
#include <OneWire.h>
#include <DallasTemperature.h>

//"RBL_nRF8001.h/spi.h/boards.h" is needed in every new project
#include <SPI.h>
#include <boards.h>
#include "Utilities.h"
#include "RBL_nRF8001.h"






/*******************************************************************************************
 *   DEFINES
 *******************************************************************************************/
#define LOG_DEBUG 1
#define FAKE_DATA 0
 
#define seconds 1000
#define ten_seconds 10000
#define minutes 60000
#define hour 3600000
#define day 86400000
#define week 604800000

#define valve_1 4
#define reference_sensor 0
#define leaf_sensor 1
#define root_temp_sensor 2
#define air_temp_sensor 3
#define light_sensor 4




/*
  typedef struct settings_t {
    uint32_t default_connected_spray_interval; //seconds, should be in range of 60 to 1,200 seconds
    uint32_t default_disconnected_spray_interval; //seconds, should be in range of 60 to 1,200 seconds
    uint32_t spray_duration;  //seconds, should be small like 3 to 5 seconds
    uint32_t startup_spray_duration;  //seconds, should be bigger like 30 to 300 seconds
  //  char device_long_name[32] = {k_default_device_name};
  };
  settings_t settings;

DURATION:               settings.spray_duration
CONNECTED_INTERVAL:     ((settings.default_connected_spray_interval * minutes) - settings.spray_duration) 
DISCONNECTED_INTERVAL:  ((settings.default_disconnected_spray_interval * minutes) - settings.spray_duration)

*/






/*******************************************************************************************
 *   DEVICE SETTINGS
 *******************************************************************************************/
#include "Settings.h"



/*******************************************************************************************
 *   RUNNING SENSOR VALUES
 *******************************************************************************************/
float root_temp_sensor_value = 0;
float root_temp_sensor_value_sum = 0;
float root_temp_sensor_value_count = 0;

float air_temp_sensor_value = 0;
float air_temp_sensor_value_sum = 0;
float air_temp_sensor_value_count = 0;

float light_sensor_value = 0;
float light_sensor_value_sum = 0;
float light_sensor_value_count = 0;

float leaf_sensor_value = 0;
float leaf_sensor_value_sum = 0;
float leaf_sensor_value_count = 0;

float leaf_sensor_latch = 100;
float leaf_sensor_latch_sum = 0;
float leaf_sensor_latch_count = 0;

bool leaf_sensor_connected = true;
bool leaf_sensor_triggered = false;






/*******************************************************************************************
 *   SPRAY INTERVAL
 *******************************************************************************************/
unsigned long start_time = 0;
unsigned long intervalStart = 0;
unsigned long intervalValue = 0;  //current interval
unsigned long intervalSum = 0;
unsigned long intervalCount = 0;
bool updateInterval(void) {
  unsigned long t = millis();
  unsigned long i = t - intervalStart;
  intervalValue = i;
  unsigned long d = ((settings.default_connected_spray_interval * minutes) - settings.spray_duration);
  if( !leaf_sensor_connected ) { d = ((settings.default_disconnected_spray_interval * minutes) - settings.spray_duration); }
  if( i >= d ) {
    // we have exceeded our maximum interval
    intervalSum += i;
    intervalCount += 1;
    intervalStart = t;
    return true;
  }
  return false;
}
double intervalSeconds() {
  return 4.0*((double)intervalValue)/((double)minutes);
}




/*******************************************************************************************
 *   HISTORY LOGGING
 *******************************************************************************************/
#include "Logging.h"



/*******************************************************************************************
 *   VALVE OPEN/CLOSE
 *******************************************************************************************/
bool flushPipes = false;
void openValve( int d ) {
  // turn valve on
#if LOG_DEBUG
    unsigned long t0 = millis();
    Serial.print(F("SPRAY START: "));
#endif
  digitalWrite(valve_1, HIGH);
  
  // wait DURATION
  if( d > 0 ) {
    longDelay(d);
  } else {
    longDelay(settings.spray_duration*seconds);
  }
   
  // turn valve off
  digitalWrite(valve_1, LOW);
#if LOG_DEBUG
    unsigned long t1 = millis();
    Serial.print((t1-t0));
    Serial.println(F(" STOP"));
#endif
  
//  timer = 0;
  leaf_sensor_value = 0;
  leaf_sensor_latch = 100;
}





/*******************************************************************************************
 *   BLUETOOTH SHIELD INTERACTION
 *******************************************************************************************/
#include "Commands.h" 





/*******************************************************************************************
 *   SENSORS
 *******************************************************************************************/
// Data wire is plugged into pin 2 on the Arduino
#define ONE_WIRE_BUS 2
 
// Setup a oneWire instance to communicate with any OneWire devices 
// (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);
 
// Pass our oneWire reference to Dallas Temperature.
DallasTemperature sensors(&oneWire);


 
// return temp in degrees C ( 0 to 100 )
#define SUPPLY_VOLTAGE 5.0          // either 5.0 or 3.3
#define SUPPLY_VOLTAGE_OFFSET 0.5  // either 0.5 or 0.33
float getTempOnAnalogPin( int pin ) {
  //assuming the TMP 36 temperature sensor
  int reading = analogRead(pin);  
  // converting that reading to voltage, for 3.3v arduino use 3.3
  float voltage = (reading * SUPPLY_VOLTAGE)/k_max_analog_pin;
  float temperatureC = (voltage - SUPPLY_VOLTAGE_OFFSET) * 100 ;  //converting from 10 mv per degree wit 500 mV offset
  
#if LOG_DEBUG
//  Serial.print(voltage); Serial.print(" volts,   ");
//  Serial.print(temperatureC); Serial.print(" degrees C,   ");
//  Serial.print(temperatureF); Serial.println(" degrees F");
#endif

  return temperatureC;
}


float getLeafSensorValueOnPin( int pin ) {
  return analogPinToPercent(analogRead(pin));
}


float getTempAtIndex( int index ) {
  
}


float getLightValueOnAnalogPin( int pin ) {
  int reading = analogRead(pin);  
  // converting that reading to voltage, for 3.3v arduino use 3.3
  float voltage = (reading * SUPPLY_VOLTAGE)/k_max_analog_pin;
  float adjusted = (voltage - 4) * 100;
  if( adjusted < 0 ) { return 0; }
  return adjusted;  
}


#define SENSOR_TEST_COUNT 10
bool updateSensorValues() {  
// call sensors.requestTemperatures() to issue a global temperature
// request to all devices on the bus
  sensors.requestTemperatures(); // Send the command to get temperatures

  float root_temp_sensor_sum = 0;
  float air_temp_sensor_sum = 0;
  float light_sensor_sum = 0;
  float ref_sum = 0;
  float leaf_sensor_sum = 0;
  
  bool noConnection = false;
  for( int i = 0; i < SENSOR_TEST_COUNT; i++ ) {
    float lsv = getLeafSensorValueOnPin(settings.leaf_sensor_pin);
    leaf_sensor_sum += lsv;           //Read Leaf Sensor Pin A0

//    float root_temp_sensor_value = getTempOnAnalogPin(settings.root_temperature_pin);
//    root_temp_sensor_sum += root_temp_sensor_value;
//
//    float air_temp_sensor_value = getTempOnAnalogPin(settings.air_temperature_pin);
//    air_temp_sensor_sum += air_temp_sensor_value;

    float light_sensor_value = getLightValueOnAnalogPin(settings.light_sensor_pin);
    light_sensor_sum += light_sensor_value;
    
    delay(100);                 //Wait 0.1 second, then repeat
  }  

  float leaf_average = leaf_sensor_sum/SENSOR_TEST_COUNT; // percent of max value

  leaf_sensor_triggered = false;
  leaf_sensor_value = leaf_average;
  float leaf_trigger = leaf_sensor_latch + leafSensorTriggerThreshold();
  if( leaf_sensor_value == 0 ) { 
    // the leaf sensor signal should have a 10K pulldown resistor to bleed a disconnected
    // sensor pin to zero.  a leaf sensor value of zero means it's not connected
    leaf_sensor_connected = false; 
    leaf_sensor_latch = 100;
  } else {
    if( leaf_sensor_value < leaf_sensor_latch ) {
      // the leaf sensor value gets lower the thicker the leaf is
      // so we want to keep setting the latch to smaller values 
      leaf_sensor_latch = leaf_sensor_value;
    } else if( leaf_sensor_value >= leaf_trigger ) {
      // sensor value increases when leaf gets thinner
      // leaf has gotten thinner which means it's loosing turgor pressure and needs water
      leaf_sensor_triggered = true;
    }  
    leaf_sensor_value_sum += leaf_sensor_value;
    leaf_sensor_value_count += 1;
  }

  root_temp_sensor_value = sensors.getTempCByIndex(0);  //(root_temp_sensor_sum/SENSOR_TEST_COUNT) + 2.55;
  root_temp_sensor_value_sum += root_temp_sensor_value;
  root_temp_sensor_value_count += 1;
  
  air_temp_sensor_value = sensors.getTempCByIndex(1);  //(air_temp_sensor_sum/SENSOR_TEST_COUNT) + 1.28;
  air_temp_sensor_value_sum += air_temp_sensor_value;
  air_temp_sensor_value_count += 1;
  
  light_sensor_value = (light_sensor_sum/SENSOR_TEST_COUNT);
  light_sensor_value_sum += light_sensor_value;
  light_sensor_value_count += 1;
  
#if LOG_DEBUG
    Serial.print(F("    AIR: "));
    Serial.print( air_temp_sensor_value );
    Serial.print(F("    ROOT: "));
    Serial.print( root_temp_sensor_value );
    Serial.print(F("    LEAF: "));
    Serial.print( leaf_sensor_value );
    Serial.print(F("    TRIGGER: "));
    Serial.print( leaf_trigger );
    Serial.print(F("    TRIGGERED: "));
    Serial.println( leaf_sensor_triggered );
#endif

  return leaf_sensor_triggered;
}

bool tryTriggerValve(void) {
  // check to see if the leaf sensor should trigger a spray cycle
  bool triggered = updateSensorValues();

  if( updateInterval() ) {
    //-- we have exceeded our max interval so return true
    return true;
  }

  return triggered;
}






/*******************************************************************************************
 *   SETUP
 *******************************************************************************************/
void setup()
{  
  memset( history, 0, sizeof(history) );
  memset( values, 0, sizeof(values) );
//  clearSettings();
  readSettingsFromEEPROM();
  
  // Default pins set to 9 and 8 for REQN and RDYN
  // Set your REQN and RDYN here before ble_begin() if you need
  //ble_set_pins(3, 2);

  pinMode(valve_1, OUTPUT);

#if LOG_DEBUG
  Serial.begin(115200);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }
#endif

  // Set your BLE Shield name here, max. length 10
 // ble_set_name("Aero Controller");
  
  // Init. and start BLE library.
  ble_begin();

  // Start up the library
  sensors.begin();

  flushPipes = true;
}






/*******************************************************************************************
 *   MAIN LOOP
 *******************************************************************************************/
unsigned long d = 0;
void loop() {
  if( flushPipes ) {
    openValve(settings.startup_spray_duration*seconds);
    flushPipes = false;
  }

  unsigned long t = millis();
  if( (t - d) > 10000 ) {
    d = t;
    // do stuff that should be done once a second
    if( tryTriggerValve() ) {
      logValues();
      openValve(settings.spray_duration*seconds);
    }
    incrimentLogTimer();  //this will do the logging every hour
  }

  tryCommand();
}





