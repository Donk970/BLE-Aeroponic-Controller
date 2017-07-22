#ifndef Utilities_h
#define Utilities_h



const byte k_max_byte PROGMEM = 254;

const uint8_t k_max_uint8 PROGMEM = 254;
const int8_t k_min_int8 PROGMEM = -127;
const int8_t k_max_int8 PROGMEM = 126;

const uint8_t k_max_uchar PROGMEM = 254;
const int8_t k_min_char PROGMEM = -127;
const int8_t k_max_char PROGMEM = 126;

const uint16_t k_max_uint16 PROGMEM = 65534;
const int16_t k_min_int16 PROGMEM = -32767;
const int16_t k_max_int16 PROGMEM = 32766;

const uint32_t k_max_uint32 PROGMEM = 4294967294;
const int32_t k_min_int32 PROGMEM = -2147483647;
const int32_t k_max_int32 PROGMEM = 2147483646;

const float k_max_analog_pin PROGMEM = 1023.0;
const float k_analog_resolution PROGMEM = .001;
const float k_analog_resolution_percent PROGMEM = .1;


void longDelay( long d ) {
  long del = d;
  while( del > 0 ) {
    delay(1000);
    del -= 1000;
  }
}





float floatMap(float x, float in_min, float in_max, float out_min, float out_max) {
  float temp = (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
  temp = (int) (4*temp + .5);
  return (float) temp/4;
}


char percentToChar( float percent ) {
  float conversion = 255.0 * percent / 100.0;
  return (char) conversion;
}

float charToPercent( char c ) {
  return ((float)c) * 100.0 / 255.0;
}


float analogPinToPercent( uint16_t value ) {
  return ((float)value) * 100.0 / k_max_analog_pin;
}

uint16_t percentToUInt16( float percent ) {
  return (percent/100.0)*k_max_uint16;
}

float uint16ToPercent( uint16_t value ) {
  return 100.0*(value/k_max_uint16);
}









#endif


