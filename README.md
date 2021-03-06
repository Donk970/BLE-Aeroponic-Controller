# BLE-Aeroponic-Controller
A Bluetooth LE Enabled Aeroponic Controller and iOS App

    This is my initial implementation of an Arduino based controller for an aeroponic grow system.  What is aeroponics?  
    Glad you asked.  Aeroponics is a method of growing plants that is similar to hydroponics except that it periodically 
    mists the roots of the plants instead of submerging them in water.  
    Aeroponics was originally developed in the 1920’s as a method for studying the structure of plant roots that didn’t 
    involve tearing them out of the soil.  Aeroponics really didn’t get much attention as anything other than a research 
    tool until "The Land" pavilion at Disney's Epcot Center opened in 1982.  Even then aeroponics was not well known until 
    NASA began looking at it as a way of growing food in space in the 1990’s.
    The basic design of an aeroponic system is pretty simple.  You deliver water with nutrients from a reservoir to the 
    plants using a high pressure pump (100psi) to pump the nutrient solution through spray nozzles that can produce a 
    fine mist of droplets in the 50 micron range.  Since the misting only happens 3 to 5 seconds at a time ever 5 to 10 
    minutes you need a timer that can manage such precise timing intervals.  While there are expensive timers on the 
    market that will do this, a cheap little Arduino with a power supply and a relay to turn the spray on and off is 
    sufficient.
    This project goes a bit further and adds a capacitive leaf thickness sensor developed at 
    AgriHouse (http://www.agrihouse.com/leafsensors.php) to determine when the plant is beginning to dry out and 
    deliver a nutrient spray only when needed.  This project also adds a BLE shield from RedBear to allow an iOS app 
    to connect with it and gather some basic data logging and send commands to adjust default settings.

