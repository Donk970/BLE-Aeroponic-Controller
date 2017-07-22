



#ifndef __Logging__
#define __Logging__

#include "Utilities.h"

#define k_flag_in_use_bit 0
#define k_flag_leaf_sensor_connected_bit 1
#define k_flag_leaf_sensor_triggered_bit 2

// just instantanious is a single "instantanious" reading sent back
// just log entry is the full "hourly" set of log entries
// both instantanious and log is the event entries
#define k_flag_instantanious_entry 3
#define k_flag_log_entry 4

/*
 * Full Sun:  > 96 
 * Part Shade: < 96 & > 70 
 * Shade: < 70
 * Dark: 0
 */

#define k_flag_light_day_bit 5
#define k_flag_light_part_cloudy_bit 6
#define k_flag_light_cloudy_bit 7
#define k_threshold_full_sun 96
#define k_threshold_part_shade 70

#define k_max_milliseconds 4294967295

//                         4,294,967,295
//                           521,141,873
//                            31,536,000
//  we should be able to log seconds for the next 119 years

unsigned long lastTMillis = 0;
double lastTSeconds = 0;
double currentTime(void) {
  // return current time in seconds
  unsigned long t = millis();
  double dt = 0;
  if( t < lastTMillis ) {
    // we rolled over
    dt = ((double)((k_max_milliseconds - lastTMillis) + t))/1000.0;
  } else {
    dt = ((double)(t - lastTMillis))/1000.0;
  }
  lastTMillis = t;
  lastTSeconds += dt;  //seconds from time program started
  return lastTSeconds;
}

double externalReferenceTime = 0; //this should get set by iOS app (or other) when we connect
double internalReferenceTime = 0; //this should get set to seconds from program start to when external ref is set
void setReferenceDate( double t ) {
  externalReferenceTime = t;
  internalReferenceTime = currentTime();
}

unsigned long timeStamp(void) {
  // difference in time between when time stamps are counted from and time from when we started running
  double dt = externalReferenceTime - internalReferenceTime;
  return currentTime() + dt;
}


typedef struct history_t {
    uint8_t flags;     //4 bits for lighting
    uint8_t interval;  //minutes - maybe use bottom 2 bits for seconds max 63 minutes, 15 second resolution
    uint16_t leaf_sensor_value;  // this is the leaf max thickness value from leaf sensor
    uint8_t root_temp;
    uint8_t leaf_temp;
    unsigned long time_stamp;
};

#if FAKE_DATA 
bool trigger = true;
#endif

uint8_t getFlags(void) {
  uint8_t f = 0;
  // set the various flags here
  bitSet( f, k_flag_in_use_bit );
  
//#if FAKE_DATA 
//  leaf_sensor_connected = true;
//  leaf_sensor_triggered = trigger;
//  if( trigger ) {
//    leaf_sensor_value_sum = 6; 
//    leaf_sensor_value_count = 1;
//    trigger = false;
//  } else {
//    leaf_sensor_value_sum = 5; 
//    leaf_sensor_value_count = 1;
//    trigger = true;
//  }
//#endif
  
  if( leaf_sensor_connected ) { bitSet( f, k_flag_leaf_sensor_connected_bit ); } else { bitClear( f, k_flag_leaf_sensor_connected_bit ); }
  if( leaf_sensor_triggered ) { bitSet( f, k_flag_leaf_sensor_triggered_bit ); } else { bitClear( f, k_flag_leaf_sensor_triggered_bit ); }
  if( light_sensor_value > 0 ) { 
    bitSet( f, k_flag_light_day_bit ); 
    if( light_sensor_value < k_threshold_full_sun ) { 
      bitSet( f, k_flag_light_cloudy_bit ); 
      if( light_sensor_value < k_threshold_part_shade ) { 
        bitSet( f, k_flag_light_cloudy_bit ); 
      } else { 
        bitClear( f, k_flag_light_cloudy_bit ); 
      }
    } else { 
      bitClear( f, k_flag_light_cloudy_bit ); 
    }
  } else { 
    bitClear( f, k_flag_light_day_bit );
    bitClear( f, k_flag_light_cloudy_bit ); 
    bitClear( f, k_flag_light_part_cloudy_bit ); 
  }
  return f;
}








/*
 * Short term logging.  Every time the spray is triggered we push the current set of sensor values
 * to the log.
 */
#define values_count 10  // roughly an hour of entries every time a spray is triggered
history_t values[values_count] = {0};
void pushValueEntry(struct history_t val) {
    //shift values up one and zero value 0
  for( int v = values_count - 2; v >= 0; v-- ) {
    values[v+1] = values[v];
  }
  memset( values, 0, sizeof(history_t) );
  values[0] = val;
  
#if LOG_DEBUG
  Serial.print(F("<interval: ")); Serial.print((val.interval/4)); Serial.print(F(" m>  "));
  Serial.print(F("<leaf: ")); Serial.print(val.leaf_sensor_value); Serial.print(F(" %>  "));
  Serial.print(F("<root: ")); Serial.print(val.root_temp); Serial.print(F(" C>  "));
  Serial.print(F("<air: ")); Serial.print(val.leaf_temp); Serial.print(F(" C>   "));
  Serial.print(F("<light: ")); Serial.print(val.flags); Serial.println(F(" V>   "));
  Serial.println(F(" "));
#endif

}


void logValues() {
  history_t entry;
  entry.flags = getFlags();
  bitSet( entry.flags, k_flag_instantanious_entry );
  bitSet( entry.flags, k_flag_log_entry );
  entry.time_stamp = timeStamp();

  // leaf sensor value - percent max
  float leaf = leaf_sensor_value_sum/leaf_sensor_value_count;
  leaf_sensor_value_sum = 0;
  leaf_sensor_value_count = 0;

  // leaf sensor latch value - percent max
  float latch = leaf_sensor_latch;  //leaf_sensor_latch_sum/leaf_sensor_latch_count;
  leaf_sensor_latch_sum = 0;
  leaf_sensor_latch_count = 0;

  // root temp value: freezing = 0, boiling = 100
  float root = root_temp_sensor_value_sum/root_temp_sensor_value_count;
  root_temp_sensor_value_sum = 0;
  root_temp_sensor_value_count = 0;

  // air temp value freezing = 0, boiling = 100
  float air = air_temp_sensor_value_sum/air_temp_sensor_value_count;
  air_temp_sensor_value_sum = 0;
  air_temp_sensor_value_count = 0;

  float light = light_sensor_value_sum/light_sensor_value_count;
  light_sensor_value_sum = 0;
  light_sensor_value_count = 0;

  // get the average interval in minutes
  double interval = intervalSeconds();
  if( interval > 200 ) { interval = 200; }
  intervalValue = 0;

  entry.leaf_sensor_value = percentToUInt16(leaf);
  entry.root_temp = percentToChar(root);
  entry.leaf_temp = percentToChar(air);
  entry.interval = (uint8_t)interval;

  leaf_sensor_connected = true;
  leaf_sensor_triggered = false;
 
  pushValueEntry(entry);
}













 
#define history_count 24  // 2 days at one entry per hour
history_t history[history_count] = {0};
void pushHistoryEntry(struct history_t val) {
    //shift values up one and zero value 0
  for( int h = history_count - 2; h >= 0; h-- ) {
    history[h+1] = history[h];
  }
  memset( history, 0, sizeof(history_t) );
  history[0] = val;
}


void updateHistory() {
  // leaf sensor value - percent max
  double leaf = 0;
  double latch = 0;
  double root = 0;
  double air = 0;
  double interval = 0;
  uint8_t flags = 0;

  for( int v = 0; v < values_count; v++ ) {
    leaf += charToPercent(values[v].leaf_sensor_value);
    root += charToPercent(values[v].root_temp);
    air += charToPercent(values[v].leaf_temp);
    interval += values[v].interval;
    flags |= values[v].flags;
  }
  bitClear( flags, k_flag_instantanious_entry );

  history_t entry;
  entry.leaf_sensor_value = percentToChar(leaf/values_count);
  entry.root_temp = percentToChar(root/values_count);
  entry.leaf_temp = percentToChar(air/values_count);
  entry.interval = (uint8_t)(interval/leaf/values_count);
  entry.flags = flags;
  entry.time_stamp = values[values_count-1].time_stamp;  //use last time stamp in values
  pushHistoryEntry(entry);
}

unsigned long log_timer = 0;
void incrimentLogTimer(void) {
  unsigned long t = millis();
  if( t > log_timer ) {
    updateHistory();
    log_timer = t + hour; //set next hour mark
  }
}











#if LOG_DEBUG && FAKE_DATA
void load_dummy_data(void) {
  for( int i = 0; i < history_count; i++ ) {
    tryTriggerValve();
    updateSensorValues();

    leaf_sensor_connected = true;
    if( random(0,2) == 1 ) {
      //didn't trigger on leaf sensor
      leaf_sensor_triggered = false;
      intervalSum = ((settings.default_connected_spray_interval * minutes) - settings.spray_duration);
      intervalCount = 1;
      if( random(0,2) == 1 ) {
        leaf_sensor_connected = false;
      }
    } else {
      //did trigger on leaf sensor
      leaf_sensor_triggered = true;
      intervalSum = random(((settings.default_disconnected_spray_interval * minutes) - settings.spray_duration),((settings.default_connected_spray_interval * minutes) - settings.spray_duration));
      intervalCount = 1;
    }

    updateHistory();
   }
}
#endif









#endif



