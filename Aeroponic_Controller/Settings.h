


#ifndef __Settings__ 
#define __Settings__

#include <EEPROM.h>

const char k_default_device_name[] PROGMEM  = {"Aeroponic Controller           "};
const uint16_t k_default_leaf_sensor_threshold PROGMEM = 3280; // 0.05 percent of max sensor reading expressed as uint16

typedef struct settings_t {
  uint16_t default_connected_spray_interval = 8; //minutes, should be in range of 1 to 20 minutes
  uint16_t default_disconnected_spray_interval = 3; //minutes, should be in range of 1 to 20 minutes
  uint16_t spray_duration = 3;  //seconds, should be small like 3 to 5 seconds
  uint16_t startup_spray_duration = 20;  //seconds, should be bigger like 30 to 300 seconds
  int8_t root_temperature_pin = 2;
  int8_t air_temperature_pin = 3;
  int8_t leaf_sensor_pin = 1;
  int8_t light_sensor_pin = 4;
};
settings_t settings;

typedef struct sensor_settings_t {
  uint16_t leaf_sensor_threshold = k_default_leaf_sensor_threshold;  //  (uint16_t)(0.1 * (float)k_max_uint16));
  int16_t root_temperature_intercept = 0;
  int16_t root_temperature_slope = 1;
  int16_t air_temperature_intercept = 0;
  int16_t air_temperature_slope = 1;
};
sensor_settings_t sensor_settings;


void writeSettingsToEEPROM(void) {
  int addr = 0; // address in EEPROM to write next byte to

  uint8_t *ptr = (uint8_t*) &settings;
  for( int i = 0; i < sizeof(settings_t); i++ ) {
    EEPROM.write(addr, *ptr);
    addr += 1;
    ptr +=1;
  }

  ptr = (uint8_t*) &sensor_settings;
  for( int i = 0; i < sizeof(sensor_settings_t); i++ ) {
    EEPROM.write(addr, *ptr);
    addr += 1;
    ptr +=1;
  }
}

void clearSettings() {
  int addr = 0;
  for( int i = 0; i < 256; i++ ) {
    EEPROM.write(addr, 0);
    addr += 1;
  }
  
  memset( &settings, 0, sizeof(settings) );
  settings.default_connected_spray_interval = 8;
  settings.default_disconnected_spray_interval = 3;
  settings.spray_duration = 3;
  settings.startup_spray_duration = 20;
  
  settings.root_temperature_pin = 2;
  settings.air_temperature_pin = 3;
  settings.leaf_sensor_pin = 1;
  settings.light_sensor_pin = 4;

  sensor_settings.leaf_sensor_threshold = k_default_leaf_sensor_threshold; 
  sensor_settings.root_temperature_intercept = 0;
  sensor_settings.root_temperature_slope = 1;
  sensor_settings.air_temperature_intercept = 0;
  sensor_settings.air_temperature_slope = 1;

  writeSettingsToEEPROM();
}

void readSettingsFromEEPROM(void) {
  int addr = 0; // address in EEPROM to read next byte from
  
  uint8_t *ptr = (uint8_t*) &settings;
  for( int i = 0; i < sizeof(settings_t); i++ ) {
    *ptr = EEPROM.read(addr);
    addr += 1;
    ptr +=1;
  }
  
  ptr = (uint8_t*) &sensor_settings;
  for( int i = 0; i < sizeof(sensor_settings); i++ ) {
    *ptr = EEPROM.read(addr);
    addr += 1;
    ptr +=1;
  }

  if( settings.default_connected_spray_interval == 0 ) {
    clearSettings();
  }
}


void setDefaultConnectedSprayInterval( uint32_t value ) {
  settings.default_connected_spray_interval = value;
  writeSettingsToEEPROM();
}

void setDefaultDisonnectedSprayInterval( uint32_t value ) {
  settings.default_disconnected_spray_interval = value;
  writeSettingsToEEPROM();
}

void setSprayDuration( uint32_t value ) {
  settings.spray_duration = value;
  writeSettingsToEEPROM();
}

void setStartupSprayDuration( uint32_t value ) {
  settings.startup_spray_duration = value;
  writeSettingsToEEPROM();
}

// relative to leaf sensor value which is a percent of max voltage on sensor
// default is 0.2%, max would be 100.0% and minimum is 0.1% which is smallest a 10 bit analog can resolve
float leafSensorTriggerThreshold() {
  float t = ((float)sensor_settings.leaf_sensor_threshold)/((float)k_max_uint16);
#if LOG_DEBUG
  Serial.print(F("THRESHOLD: ")); Serial.print(sensor_settings.leaf_sensor_threshold); Serial.print(F(" -> ")); Serial.println(t);
#endif
  return t;
}
void setLeafSensorThreshold( uint32_t value ) {
#if LOG_DEBUG
  Serial.print(F("\n\nOLD THRESHOLD: ")); Serial.print(sensor_settings.leaf_sensor_threshold); Serial.print(F("\n\n"));
#endif 
  // value is a percent (0 - 100) of the max 10 bit analog sensor value ( 0 - 1023 ) expressed as uint16 ( 0 - 65534 )
  uint32_t t = value > k_default_leaf_sensor_threshold ? value : k_default_leaf_sensor_threshold;  // the analog pin is good to about 0.1% of max signal voltage, 
  sensor_settings.leaf_sensor_threshold = value;
#if LOG_DEBUG
  Serial.print(F("NEW THRESHOLD: ")); Serial.println(value);
  Serial.print(F("THRESHOLD: ")); Serial.print(sensor_settings.leaf_sensor_threshold); Serial.print(F("\n\n"));
#endif 
  writeSettingsToEEPROM();
}

void setRootTemperaturePin( uint32_t value ) {
  settings.root_temperature_pin = value;
  writeSettingsToEEPROM();
}

void setAirTemperaturePin( uint32_t value ) {
  settings.air_temperature_pin = value;
  writeSettingsToEEPROM();
}

void setLeafSensorPin( uint32_t value ) {
  settings.leaf_sensor_pin = value;
  writeSettingsToEEPROM();
}

void setLightSensorPin( uint32_t value ) {
  settings.light_sensor_pin = value;
  writeSettingsToEEPROM();
}

/*
  uint16_t leaf_sensor_threshold = 100;  //seconds, should be bigger like 30 to 300 seconds
  int8_t root_temperature_pin = 2;
  int8_t air_temperature_pin = 3;
  int8_t leaf_sensor_pin = 1;
  int8_t light_sensor_pin = 4; */


void sendSettingsElement() {
  settings_t element = settings;
  //send it
  ble_write_bytes((unsigned char *)(&element), sizeof(settings_t));
 }




void sendSensorSettingsElement() {
  sensor_settings_t element = sensor_settings;
  #if LOG_DEBUG
    float v = leafSensorTriggerThreshold();
  #endif
  //send it
  ble_write_bytes((unsigned char *)(&element), sizeof(sensor_settings_t));
 }





#endif
