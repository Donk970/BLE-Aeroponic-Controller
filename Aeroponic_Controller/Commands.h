



#ifndef __Commands__
#define __Commands__






#define k_command_get_new_command 0
#define k_command_send_log_data 1
#define k_command_send_value_data 2
#define k_command_send_settings_data 3
#define k_command_send_sensor_settings_data 4

#define k_command_open_valve 10
#define k_set_connected_interval 11
#define k_set_disconnected_interval 12
#define k_set_spray_duration 13
#define k_set_startup_spray_duration 14
#define k_set_current_timestamp 15
#define k_set_leaf_sensor_threshold 16

#define k_set_leaf_sensor_pin 30
#define k_set_root_temp_pin 31
#define k_set_air_temp_pin 32
#define k_set_light_sensor_pin 33

#define k_command_load_dummy_data 100





#define command_stack_count 4
typedef struct command_t {
    byte command;
    byte count;
    byte data[20];
};
command_t command_stack[command_stack_count];
void pushCommand( command_t command ) {
  
}

uint32_t commandDataAsUInt32( struct command_t command ) {
  uint32_t value = 0;
  int c = command.count < 4 ? command.count : 4;
  for( int i = c-1; i >= 0; i-- ) {
    value = value << 8; 
    value += command.data[i];
  }
  return value;
}



command_t receivedCommand = {0, 0, 0};  //k_command_load_dummy_data;  // normally should be 0 but 2 causes us to load the dummy data into history
int sendLogCounter = 0;

command_t receiveCommand(void) {
  command_t cmd; 
  memset( &cmd, 0, sizeof(command_t) );
  if( ble_available() ) {
    while( ble_available() && cmd.count < 18 ) {
      // receive command
      byte value = ble_read();
      if( cmd.command == 0 ) {
        cmd.command = value;
      } else {
        cmd.data[cmd.count++] = value;
      }
    }
  }
  return cmd; //  word(cmdData[1], cmdData[0]);  //word(data, command)
}

bool sendLogDataElement() {
  history_t element;
  char f = 0;
  char inUse = false;

  if( sendLogCounter >= history_count ) {
    // at end of array goto done
    goto done;
  }
  
  element = history[sendLogCounter];
  f = element.flags;
  inUse = bitRead(f, k_flag_in_use_bit);
  if( !inUse ) {
    //if we've hit an empty element goto done
    goto done;
  }
  
  //send it
  ble_write_bytes((unsigned char *)(&element), sizeof(history_t));
  
  sendLogCounter += 1; // incriment send counter for next pass
  return true;

  done: 
    history_t done_marker;
    done_marker.flags = 0;
    ble_write_bytes((unsigned char *)(&done_marker), sizeof(history_t));
   
    sendLogCounter = 0;
    memset( &receivedCommand, 0, sizeof(command_t) );
    return false;
}

bool sendValueDataElement() {
  history_t element;

  if( sendLogCounter >= values_count ) {
    // at end of array goto done
    goto done;
  }
  
  element = values[sendLogCounter];
#if LOG_DEBUG
  Serial.print(F("ELEMENT: <flags: ")); 
  Serial.print(element.flags); 
  Serial.print(F(" interval: ")); 
  Serial.print(element.interval); 
  Serial.println(F(">"));
#endif
  //send it
  ble_write_bytes((unsigned char *)(&element), sizeof(history_t));
  
  sendLogCounter += 1; // incriment send counter for next pass
  return true;

  done: 
    history_t done_marker;
    done_marker.flags = 0;
    ble_write_bytes((unsigned char *)(&done_marker), sizeof(history_t));
   
    sendLogCounter = 0;
    memset( &receivedCommand, 0, sizeof(command_t) );
    return false;
}

void tryCommand(void) {

  if( receivedCommand.command != 0 ) {
     pushCommand( receivedCommand );
    
#if LOG_DEBUG
    Serial.print(F("    RECEIVED COMMAND: "));
    Serial.print( receivedCommand.command );
    Serial.print(F("    DATA: "));
    Serial.println( commandDataAsUInt32(receivedCommand) );
#endif
    
  }
  
  switch(receivedCommand.command) {
    case k_command_get_new_command: {
      receivedCommand = receiveCommand();
      break;
    }
    
    case k_command_send_log_data: {
      memset( &receivedCommand, 0, sizeof(command_t) );
      sendLogCounter = 0;
      while( sendLogDataElement() ) {
        ble_do_events();
      }
      break;
    }

    case k_command_send_value_data: {
      memset( &receivedCommand, 0, sizeof(command_t) );
      sendLogCounter = 0;
      while( sendValueDataElement() ) {
        ble_do_events();
      }
      break;
    }

    case k_command_send_settings_data: {
      memset( &receivedCommand, 0, sizeof(command_t) );
      sendLogCounter = 0;
      sendSettingsElement();
      break;
    }

    case k_command_send_sensor_settings_data: {
      memset( &receivedCommand, 0, sizeof(command_t) );
      sendLogCounter = 0;
      sendSensorSettingsElement();
      break;
    }

    case k_command_open_valve: {
      uint32_t t = commandDataAsUInt32(receivedCommand);
      memset( &receivedCommand, 0, sizeof(command_t) );
      openValve(t*seconds);
      break;
    }

    case k_set_current_timestamp: {
      uint32_t t = commandDataAsUInt32(receivedCommand);
      setReferenceDate( (double)t );
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }

    case k_set_connected_interval: {
      uint32_t t = commandDataAsUInt32(receivedCommand);
      setDefaultConnectedSprayInterval(t);
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }

    case k_set_disconnected_interval: {
      uint32_t t = commandDataAsUInt32(receivedCommand);
      setDefaultDisonnectedSprayInterval(t);
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }

    case k_set_spray_duration: {
      uint32_t t = commandDataAsUInt32(receivedCommand);
      setSprayDuration(t);
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }

    case k_set_startup_spray_duration: {
      uint32_t t = commandDataAsUInt32(receivedCommand);
      setStartupSprayDuration(t);
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }

    case k_set_leaf_sensor_threshold: {
      uint32_t t = commandDataAsUInt32(receivedCommand);
      setLeafSensorThreshold(t);
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }

    case k_set_leaf_sensor_pin: {
      uint32_t t = commandDataAsUInt32(receivedCommand);
      setLeafSensorPin(t);
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }

    case k_set_air_temp_pin: {
      uint32_t t = commandDataAsUInt32(receivedCommand);
      setAirTemperaturePin(t);
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }

    case k_set_root_temp_pin: {
      uint32_t t = commandDataAsUInt32(receivedCommand);
      setRootTemperaturePin(t);
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }

    case k_set_light_sensor_pin: {
      uint32_t t = commandDataAsUInt32(receivedCommand);
      setLightSensorPin(t);
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }


    case k_command_load_dummy_data: {
#if LOG_DEBUG && FAKE_DATA
      load_dummy_data();
#endif
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }

    default: {
      memset( &receivedCommand, 0, sizeof(command_t) );
      break;
    }
  }
  
  ble_do_events();

}







#endif






