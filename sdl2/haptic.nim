#
# Simple DirectMedia Layer
# Copyright (C) 1997-2013 Sam Lantinga <slouken@libsdl.org>
#
# This software is provided 'as-is', without any express or implied
# warranty.  In no event will the authors be held liable for any damages
# arising from the use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source distribution.
#

#
# The SDL Haptic subsystem allows you to control haptic (force feedback) devices.
#
# The basic usage is as follows:
#   - Initialize the Subsystem (``INIT_HAPTIC``).
#   - Open a Haptic Device.
#   - hapticOpen() to open from index.
#   - hapticOpenFromJoystick() to open from an existing joystick.
#   - Create an effect (PHapticEffect).
#   - Upload the effect with hapticNewEffect().
#   - Run the effect with hapticRunEffect().
#   - (optional) Free the effect with hapticDestroyEffect().
#   - Close the haptic device with hapticClose().
#
# Simple rumble example:
#
# var
#   haptic: PHaptic
#
# # Open the device
# haptic = hapticOpen(0)
#
# if haptic == nil:
#   quit(QuitFailure)
#
# # Initialize simple rumble
# if hapticRumbleInit(haptic) != 0:
#   quit(QuitFailure)
#
# # Play effect at 50% strength for 2 seconds
# if hapticRumblePlay(haptic, 0.5, 2000) != 0:
#   quit(QuitFailure)
#
# delay(2000)
#
# # Clean up
# hapticClose(haptic)
#
#
# Complete example:
#
# proc test_haptic(joystick: PJoystick): int =
#   var
#     haptic: PHaptic
#     effect: PHapticEffect
#     effect_id: int
#
#   # Open the device
#   haptic = hapticOpenFromJoystick(joystick)
#   if haptic == nil:
#     quit(QuitFailure) # Most likely joystick isn't haptic
#
#   # See if it can do sine waves
#   if (hapticQuery(haptic) and HAPTIC_SINE) == 0:
#     hapticClose(haptic) # No sine effect
#     quit(QuitFailure)
#
#   # Create the effect
#   alloc0(effect) # 0 is safe default
#   effect.kind = HAPTIC_SINE
#   effect.periodic.direction.type = HAPTIC_POLAR # Polar coordinates
#   effect.periodic.direction.dir[0] = 18000 # Force comes from south
#   effect.periodic.period = 1000 # 1000 ms
#   effect.periodic.magnitude = 20000 # 20000/32767 strength
#   effect.periodic.length = 5000 # 5 seconds long
#   effect.periodic.attack_length = 1000 # Takes 1 second to get max strength
#   effect.periodic.fade_length = 1000 # Takes 1 second to fade away
#
#   # Upload the effect
#   effect_id = hapticNewEffect(haptic, effect)
#
#   # Test the effect
#   hapticRunEffect(haptic, effect_id, 1)
#   delay(5000) # Wait for the effect to finish
#
#   # We destroy the effect, although closing the device also does this
#   hapticDestroyEffect(haptic, effect_id)
#
#   # Close the device
#   hapticClose(haptic)
#
#   quit(QuitSuccess)
#
#
# You can also find out more information on my blog:
# http://bobbens.dyndns.org/journal/2010/sdl_haptic/
#
# Author: Edgar Simo Serra
#


type

  PHapticEffect* = ptr THapticEffect
  THapticEffect* = object
    ## The generic template for any haptic effect.
    ##
    ## All values max at 32767 (0x7FFF).  Signed values also can be negative.
    ## Time values unless specified otherwise are in milliseconds.
    ##
    ## You can also pass HAPTIC_INFINITY to length instead of a 0-32767
    ## value. Neither delay, interval, attack_length nor fade_length support
    ## HAPTIC_INFINITY.  Fade will also not be used since effect never ends.
    ##
    ## Additionally, the HAPTIC_RAMP effect does not support a duration of
    ## HAPTIC_INFINITY.
    ##
    ## Button triggers may not be supported on all devices, it is advised to not
    ## use them if possible.  Buttons start at index 1 instead of index 0 like
    ## the joystick.
    ##
    ## If both attack_length and fade_level are 0, the envelope is not used,
    ## otherwise both values are used.
    ##
    ##  Here we have an example of a constant effect evolution in time:
    ##
    ##
    #
    #    Strength
    #    ^
    #    |
    #    |    effect level -->  _________________
    #    |                     /                 \
    #    |                    /                   \
    #    |                   /                     \
    #    |                  /                       \
    #    | attack_level --> |                        \
    #    |                  |                        |  <---  fade_level
    #    |
    #    +--------------------------------------------------> Time
    #                      [--]                 [---]
    #                      attack_length        fade_length
    #
    #    [------------------][-----------------------]
    #    delay               length
    #
    ##
    ## Note either the attack_level or the fade_level may be above the actual
    ## effect level.
    ##
    ## See also: THapticConstant, 
    ## THapticPeriodic, 
    ## THapticCondition, 
    ## THapticRamp, 
    ## THapticCustom
    # Common for all force feedback effects
    kind*: Uint16 ## Effect type.
    data: array[0..65, byte]
  IHapticEffect* = object
    effect*: THapticEffect ## The current event
    hweffect*: pointer ## The hardware behind the event


  PHaptic* = ptr THaptic
  THaptic* = object
    ## The haptic structure used to identify an SDL haptic.
    ##
    ## See also: hapticOpen, 
    ## hapticOpenFromJoystick, 
    ## hapticClose
    index*: Uint8 ## Stores index it is attached to
    effects*: ptr IHapticEffect ## Allocated effects
    neffects*: int ## Maximum amount of effects
    nplaying*: int ## Maximum amount of effects to play at the same time
    supported*: uint ## Supported effects
    naxes*: int ## Number of axes on the device.
    hwdata*: pointer ## Driver dependent
    ref_count*: int ## Count for multiple opens
    rumble_id*: int ## ID of rumble effect for simple rumble API.
    rumble_effect*: THapticEffect ## Rumble effect.



#
# Haptic features
#
# Different haptic features a device can have.
#


const

  #
  # Haptic effects
  #

  HAPTIC_CONSTANT*: Uint16 = (1 shl 0) ## Constant effect supported. Constant haptic effect. See also: THapticCondition

  HAPTIC_SINE*: Uint16 = (1 shl 1) ## Sine wave effect supported. Periodic haptic effect that simulates sine waves. See also: THapticPeriodic

  HAPTIC_SQUARE*: Uint16 = (1 shl 2) ## Square wave effect supported. Periodic haptic effect that simulates square waves. See also: THapticPeriodic

  HAPTIC_TRIANGLE*: Uint16 = (1 shl 3) ## Triangle wave effect supported. Periodic haptic effect that simulates triangular waves. See also: THapticPeriodic

  HAPTIC_SAWTOOTHUP*: Uint16 = (1 shl 4) ## Sawtoothup wave effect supported. Periodic haptic effect that simulates saw tooth up waves. See also: THapticPeriodic

  HAPTIC_SAWTOOTHDOWN*: Uint16 = (1 shl 5) ## Sawtoothdown wave effect supported. Periodic haptic effect that simulates saw tooth down waves. See also: THapticPeriodic

  HAPTIC_RAMP*: Uint16 = (1 shl 6) ## Ramp effect supported. Ramp haptic effect. See also: THapticRamp

  HAPTIC_SPRING*: Uint16 = (1 shl 7) ## Spring effect supported - uses axes position. Condition haptic effect that simulates a spring. Effect is based on the axes position. See also: THapticCondition

  HAPTIC_DAMPER*: Uint16 = (1 shl 8) ## Damper effect supported - uses axes velocity. Condition haptic effect that simulates dampening. Effect is based on the axes velocity. See also: THapticCondition

  HAPTIC_INERTIA*: Uint16 = (1 shl 9) ## Inertia effect supported - uses axes acceleration. Condition haptic effect that simulates inertia. Effect is based on the axes acceleration. See also: THapticCondition

  HAPTIC_FRICTION*: Uint16 = (1 shl 10) ## Friction effect supported - uses axes movement. Condition haptic effect that simulates friction. Effect is based on the axes movement. See also: THapticCondition

  HAPTIC_CUSTOM*: Uint16 = (1 shl 11) ## Custom effect is supported. User defined custom haptic effect.


  #
  # These last few are features the device has, not effects
  #

  HAPTIC_GAIN* = (1 shl 12) ## Device can set global gain. Device supports setting the global gain. See also: hapticSetGain

  HAPTIC_AUTOCENTER* = (1 shl 13) ## Device can set autocenter. Device supports setting autocenter. See also: hapticSetAutocenter

  HAPTIC_STATUS* = (1 shl 14) ## Device can be queried for effect status. Device can be queried for effect status. See also: hapticGetEffectStatus

  HAPTIC_CAN_PAUSE* = (1 shl 15) ## Device can be paused. See also: hapticPause, hapticUnpause


  #
  # Direction encodings
  #

  HAPTIC_POLAR* = 0 ## Uses polar coordinates for the direction. See also: THapticDirection

  HAPTIC_CARTESIAN* = 1 ## Uses cartesian coordinates for the direction. See also: THapticDirection

  HAPTIC_SPHERICAL* = 2 ## Uses spherical coordinates for the direction. See also: THapticDirection


  #
  # Haptic features
  #


  #
  # Misc defines.
  #

  HAPTIC_INFINITY* = 4294967295 ## Used to play a device an infinite number of times. See also: hapticRunEffect


type
  THapticDirection* = object
    ## Structure that represents a haptic direction.
    ##
    ## Directions can be specified by:
    ##
    ##   - HAPTIC_POLAR : Specified by polar coordinates.
    ##
    ##   - HAPTIC_CARTESIAN : Specified by cartesian coordinates.
    ##
    ##   - HAPTIC_SPHERICAL : Specified by spherical coordinates.
    ##
    ## Cardinal directions of the haptic device are relative to the positioning
    ## of the device.  North is considered to be away from the user.
    ##
    ##  The following diagram represents the cardinal directions:
    ##
    #
    #                .--.
    #                |__| .-------.
    #                |=.| |.-----.|
    #                |--| ||     ||
    #                |  | |'-----'|
    #                |__|~')_____('
    #                [ COMPUTER ]
    #
    #
    #                    North (0,-1)
    #                        ^
    #                        |
    #                        |
    #  (1,0)  West <----[ HAPTIC ]----> East (-1,0)
    #                        |
    #                        |
    #                        v
    #                    South (0,1)
    #  
    #  
    #                    [ USER ]
    #                      \|||/
    #                      (o o)
    #                ---ooO-(_)-Ooo---
    #
    ##
    ## If type is HAPTIC_POLAR, direction is encoded by hundredths of a
    ## degree starting north and turning clockwise. HAPTIC_POLAR only uses
    ## the first ``dir`` parameter.  The cardinal directions would be:
    ##
    ##   - North: 0 (0 degrees)
    ##
    ##   - East: 9000 (90 degrees)
    ##
    ##   - South: 18000 (180 degrees)
    ##
    ##   - West: 27000 (270 degrees)
    ##
    ## If type is HAPTIC_CARTESIAN, direction is encoded by three positions
    ## (X axis, Y axis and Z axis (with 3 axes)).  HAPTIC_CARTESIAN uses
    ## the first three ``dir`` parameters.  The cardinal directions would be:
    ##
    ##   - North:  0,-1, 0
    ##
    ##   - East:  -1, 0, 0
    ##
    ##   - South:  0, 1, 0
    ##
    ##   - West:   1, 0, 0
    ##
    ## The Z axis represents the height of the effect if supported, otherwise
    ## it's unused.  In cartesian encoding (1, 2) would be the same as (2, 4), you
    ## can use any multiple you want, only the direction matters.
    ##
    ## If type is HAPTIC_SPHERICAL, direction is encoded by two rotations.
    ## The first two ``dir`` parameters are used.  The ``dir`` parameters are as
    ## follows (all values are in hundredths of degrees):
    ##
    ##   - Degrees from (1, 0) rotated towards (0, 1).
    ##   - Degrees towards (0, 0, 1) (device needs at least 3 axes).
    ##
    ##
    ## Example of force coming from the south with all encodings (force coming
    ## from the south means the user will have to pull the stick to counteract):
    ##
    ##
    ## var direction: THapticDirection
    ##
    ## # Cartesian directions
    ##
    ## direction.type = HAPTIC_CARTESIAN # Using cartesian direction encoding.
    ##
    ## direction.dir[0] = 0 # X position
    ##
    ## direction.dir[1] = 1 # Y position
    ##
    ## # Assuming the device has 2 axes, we don't need to specify third parameter.
    ##
    ## # Polar directions
    ##
    ## direction.type = HAPTIC_POLAR # We'll be using polar direction encoding.
    ##
    ## direction.dir[0] = 18000 # Polar only uses first parameter
    ##
    ## # Spherical coordinates
    ##
    ## direction.type = HAPTIC_SPHERICAL # Spherical encoding
    ##
    ## direction.dir[0] = 9000 # Since we only have two axes we don't need more parameters.
    ##
    ##
    ## See aslo: HAPTIC_POLAR, 
    ## HAPTIC_CARTESIAN, 
    ## HAPTIC_SPHERICAL, 
    ## THapticEffect, 
    ## THapticNumAxes
    kind*: Uint8 ## The type of encoding.
    dir*: array[0..2, int32] ## The encoded direction.


  PHapticConstant* = ptr THapticConstant
  THapticConstant* = object
    ## A structure containing a template for a Constant effect.
    ##
    ## The struct is exclusive to the HAPTIC_CONSTANT effect.
    ##
    ## A constant effect applies a constant force in the specified direction
    ## to the joystick.
    ##
    ## See also: HAPTIC_CONSTANT, 
    ## THapticEffect
    kind*: Uint16 ## HAPTIC_CONSTANT
    direction*: THapticDirection ## Direction of the effect.
    length*: Uint32 ## Duration of the effect.
    delay*: Uint16 ## Delay before starting the effect.
    button*: Uint16 ## Button that triggers the effect.
    interval*: Uint16 ## How soon it can be triggered again after button.
    level*: int16 ## Strength of the constant effect.
    attack_length*: Uint16 ## Duration of the attack.
    attack_level*: Uint16 ## Level at the start of the attack.
    fade_length*: Uint16 ## Duration of the fade.
    fade_level*: Uint16 ## Level at the end of the fade.


  PHapticPeriodic* = ptr THapticPeriodic
  THapticPeriodic* = object
    ## A structure containing a template for a Periodic effect.
    ##
    ## The struct handles the following effects:
    ##
    ##   - HAPTIC_SINE
    ##
    ##   - HAPTIC_SQUARE
    ##
    ##   - HAPTIC_TRIANGLE
    ##
    ##   - HAPTIC_SAWTOOTHUP
    ##
    ##   - HAPTIC_SAWTOOTHDOWN
    ##
    ## A periodic effect consists in a wave-shaped effect that repeats itself
    ## over time. The type determines the shape of the wave and the parameters
    ## determine the dimensions of the wave.
    ##
    ## Phase is given by hundredth of a cycle meaning that giving the phase a value
    ## of 9000 will displace it 25% of its period.  Here are sample values:
    ##
    ##   -     0: No phase displacement.
    ##
    ##   -  9000: Displaced 25% of its period.
    ##
    ##   - 18000: Displaced 50% of its period.
    ##
    ##   - 27000: Displaced 75% of its period.
    ##
    ##   - 36000: Displaced 100% of its period, same as 0, but 0 is preferred.
    ##
    ## Examples:
    ##
    #
    #    HAPTIC_SINE
    #      __      __      __      __
    #     /  \    /  \    /  \    /
    #    /    \__/    \__/    \__/
    #
    #    HAPTIC_SQUARE
    #     __    __    __    __    __
    #    |  |  |  |  |  |  |  |  |  |
    #    |  |__|  |__|  |__|  |__|  |
    #
    #    HAPTIC_TRIANGLE
    #      /\    /\    /\    /\    /\
    #     /  \  /  \  /  \  /  \  /
    #    /    \/    \/    \/    \/
    #
    #    HAPTIC_SAWTOOTHUP
    #      /|  /|  /|  /|  /|  /|  /|
    #     / | / | / | / | / | / | / |
    #    /  |/  |/  |/  |/  |/  |/  |
    #
    #    HAPTIC_SAWTOOTHDOWN
    #    \  |\  |\  |\  |\  |\  |\  |
    #     \ | \ | \ | \ | \ | \ | \ |
    #      \|  \|  \|  \|  \|  \|  \|
    #
    ##
    ## See also: HAPTIC_SINE, 
    ## HAPTIC_SQUARE, 
    ## HAPTIC_TRIANGLE, 
    ## HAPTIC_SAWTOOTHUP,
    ## HAPTIC_SAWTOOTHDOWN,
    ## THapticEffect
    kind*: Uint16 ## HAPTIC_SINE, HAPTIC_SQUARE, HAPTIC_TRIANGLE, HAPTIC_SAWTOOTHUP or HAPTIC_SAWTOOTHDOWN
    direction*: THapticDirection ## Direction of the effect.
    length*: Uint32 ## Duration of the effect.
    delay*: Uint16 ## Delay before starting the effect.
    button*: Uint16 ## Button that triggers the effect.
    interval*: Uint16 ## How soon it can be triggered again after button.
    period*: Uint16 ## Period of the wave.
    magnitude*: int16 ## Peak value.
    offset*: int16 ## Mean value of the wave.
    phase*: Uint16 ## Horizontal shift given by hundredth of a cycle.
    attack_length*: Uint16 ## Duration of the attack.
    attack_level*: Uint16 ## Level at the start of the attack.
    fade_length*: Uint16 ## Duration of the fade.
    fade_level*: Uint16 ## Level at the end of the fade.


  PHapticCondition* = ptr THapticCondition
  THapticCondition* = object
    ## A structure containing a template for a Condition effect.
    ##
    ## The struct handles the following effects:
    ##
    ##   - HAPTIC_SPRING: Effect based on axes position.
    ##
    ##   - HAPTIC_DAMPER: Effect based on axes velocity.
    ##
    ##   - HAPTIC_INERTIA: Effect based on axes acceleration.
    ##
    ##   - HAPTIC_FRICTION: Effect based on axes movement.
    ##
    ## Direction is handled by condition internals instead of a direction member.
    ## The condition effect specific members have three parameters.  The first
    ## refers to the X axis, the second refers to the Y axis and the third
    ## refers to the Z axis.  The right terms refer to the positive side of the
    ## axis and the left terms refer to the negative side of the axis.  Please
    ## refer to the ::SDL_HapticDirection diagram for which side is positive and
    ## which is negative.
    ##
    ## See also: THapticDirection, 
    ## HAPTIC_SPRING, 
    ## HAPTIC_DAMPER,
    ## HAPTIC_INERTIA, 
    ## HAPTIC_FRICTION, 
    ## THapticEffect
    kind*: Uint16 ## HAPTIC_SPRING, HAPTIC_DAMPER, HAPTIC_INERTIA or HAPTIC_FRICTION
    direction*: THapticDirection ## Direction of the effect - Not used ATM.
    length*: Uint32 ## Duration of the effect.
    delay*: Uint16 ## Delay before starting the effect.
    button*: Uint16 ## Button that triggers the effect.
    interval*: Uint16 ## soon it can be triggered again after button.
    right_sat*: array[0..2, Uint16] ## Level when joystick is to the positive side.
    left_sat*: array[0..2, Uint16] ## Level when joystick is to the negative side.
    right_coeff*: array[0..2, int16] ## How fast to increase the force towards the positive side.
    left_coeff*: array[0..2, int16] ## How fast to increase the force towards the negative side.
    deadband*: array[0..2, Uint16] ## Size of the dead zone.
    center*: array[0..2, int16] ## Position of the dead zone.

  
  PHapticRamp* = ptr THapticRamp
  THapticRamp* = object
    ## A structure containing a template for a Ramp effect.
    ##
    ## This struct is exclusively for the HAPTIC_RAMP effect.
    ##
    ## The ramp effect starts at start strength and ends at end strength.
    ## It augments in linear fashion.  If you use attack and fade with a ramp
    ## the effects get added to the ramp effect making the effect become
    ## quadratic instead of linear.
    ##
    ## See also: HAPTIC_RAMP, 
    ## THapticEffect
    kind*: Uint16 ## HAPTIC_RAMP
    direction*: THapticDirection ## Direction of the effect.
    length*: Uint32 ## Duration of the effect.
    delay*: Uint16 ## Delay before starting the effect.
    button*: Uint16 ## Button that triggers the effect.
    interval*: Uint16 ## How soon it can be triggered again after button.
    start*: int16 ## Beginning strength level.
    ending*: int16 ## Ending strength level.
    attack_length*: Uint16 ## Duration of the attack.
    attack_level*: Uint16 ## Level at the start of the attack.
    fade_length*:Uint16 ## Duration of the fade.
    fade_level*: Uint16 ## Level at the end of the fade.


  PHapticCustom* = ptr THapticCustom
  THapticCustom* = object
    ## A structure containing a template for the HAPTIC_CUSTOM effect.
    ##
    ## A custom force feedback effect is much like a periodic effect, where the
    ## application can define its exact shape.  You will have to allocate the
    ## data yourself.  Data should consist of channels * samples Uint16 samples.
    ##
    ## If channels is one, the effect is rotated using the defined direction.
    ## Otherwise it uses the samples in data for the different axes.
    ##
    ## See also: HAPTIC_CUSTOM, 
    ## THapticEffect
    kind*: Uint16 ## HAPTIC_CUSTOM
    direction*: THapticDirection ## Direction of the effect.
    length*: Uint32 ## Duration of the effect.
    delay*: Uint16 ## Delay before starting the effect.
    button*: Uint16 ## Button that triggers the effect.
    interval*: Uint16 ## How soon it can be triggered again after button.
    channels*: Uint8 ## Axes to use, minimum of one.
    period*: Uint16 ## Sample periods.
    samples*: Uint16 ## Amount of samples.
    data*: ptr Uint16 ## Should contain channels*samples items.
    attack_length*: Uint16 ## Duration of the attack.
    attack_level*: Uint16 ## Level at the start of the attack.
    fade_length*: Uint16 ## Duration of the fade.
    fade_level*: Uint16 ## Level at the end of the fade.


template hapticconv(procName: expr, ptrName: typeDesc, assertions: seq[Uint16]): stmt {.immediate.} =
  template `procName`*(effect: PHapticEffect): ptrName =
    assert(contains(assertions, event.kind)); cast[ptrName](event)

hapticconv(HaptConstant, PHapticConstant, @[HAPTIC_CONSTANT])
hapticconv(HaptPeriodic, PHapticPeriodic, @[HAPTIC_SINE, HAPTIC_SQUARE, HAPTIC_TRIANGLE, HAPTIC_SAWTOOTHUP, HAPTIC_SAWTOOTHDOWN])
hapticconv(HaptCondition, PHapticCondition, @[HAPTIC_SPRING, HAPTIC_DAMPER, HAPTIC_INERTIA, HAPTIC_FRICTION])
hapticconv(HaptRamp, PHapticRamp, @[HAPTIC_RAMP])
hapticconv(HaptCustom, PHapticCustom, @[HAPTIC_CUSTOM])


#
# Function prototypes
#


proc numHaptics*(): int {.cdecl, importc: "SDL_NumHaptics", dynlib: LibName.}
  ## Count the number of haptic devices attached to the system.
  ##
  ## Return number of haptic devices detected on the system.


proc hapticName*(device_index: int): cstring {.cdecl, importc: "SDL_HapticName", dynlib: LibName.}
  ## Get the implementation dependent name of a Haptic device.
  ##
  ## This can be called before any joysticks are opened.
  ## If no name can be found, this function returns nil.
  ##
  ## ``device_index`` Index of the device to get its name.
  ##
  ## Return name of the device or nil on error.
  ##
  ## See also: numHaptics


proc hapticOpen*(device_index: int): PHaptic {.cdecl, importc: "SDL_HapticOpen", dynlib: LibName.}
  ## Opens a Haptic device for usage.
  ##
  ## The index passed as an argument refers to the N'th Haptic device on this
  ## system.
  ##
  ## When opening a haptic device, its gain will be set to maximum and
  ## autocenter will be disabled.  To modify these values use
  ## hapticSetGain() and hapticSetAutocenter().
  ##
  ## ``device_index`` Index of the device to open.
  ##
  ## Return device identifier or nil on error.
  ##
  ## See also: hapticIndex, 
  ## hapticOpenFromMouse, 
  ## hapticOpenFromJoystick, 
  ## hapticClose, 
  ## hapticSetGain, 
  ## hapticSetAutocenter, 
  ## hapticPause, 
  ## hapticStopAll


proc hapticOpened*(device_index: int): int {.cdecl, importc: "SDL_HapticOpened", dynlib: LibName.}
  ## Checks if the haptic device at index has been opened.
  ##
  ## ``device_index`` Index to check to see if it has been opened.
  ##
  ## Return 1 if it has been opened or 0 if it hasn't.
  ##
  ## See also: hapticOpen, 
  ## hapticIndex


proc hapticIndex*(haptic: PHaptic): int {.cdecl, importc: "SDL_HapticIndex", dynlib: LibName.}
  ## Gets the index of a haptic device.
  ##
  ## ``haptic`` Haptic device to get the index of.
  ##
  ## Return the index of the haptic device or -1 on error.
  ##
  ## See also: hapticOpen, 
  ## hapticOpened


proc mouseIsHaptic*(): int {.cdecl, importc: "SDL_MouseIsHaptic", dynlib: LibName.}
  ## Gets whether or not the current mouse has haptic capabilities.
  ##
  ## Return TRUE if the mouse is haptic, FALSE if it isn't.
  ##
  ## See also: hapticOpenFromMouse


proc hapticOpenFromMouse*(): PHaptic {.cdecl, importc: "SDL_HapticOpenFromMouse", dynlib: LibName.}
  ## Tries to open a haptic device from the current mouse.
  ##
  ## Return The haptic device identifier or nil on error.
  ##
  ## See also: mouseIsHaptic, 
  ## hapticOpen


proc joystickIsHaptic*(joystick: PJoystick): int {.cdecl, importc: "SDL_JoystickIsHaptic", dynlib: LibName.}
  ## Checks to see if a joystick has haptic features.
  ##
  ## ``joystick`` Joystick to test for haptic capabilities.
  ##
  ## Return 1 if the joystick is haptic, 0 if it isn't
  ## or -1 if an error ocurred.
  ##
  ## See also: hapticOpenFromJoystick


proc hapticOpenFromJoystick*(joystick: PJoystick): PHaptic {.cdecl, importc: "SDL_HapticOpenFromJoystick", dynlib: LibName.}
  ## Opens a Haptic device for usage from a Joystick device.
  ##
  ## You must still close the haptic device seperately.  It will not be closed
  ## with the joystick.
  ##
  ## When opening from a joystick you should first close the haptic device
  ## before closing the joystick device.  If not, on some implementations the
  ## haptic device will also get unallocated and you'll be unable to use force
  ## feedback on that device.
  ##
  ## ``joystick`` Joystick to create a haptic device from.
  ##
  ## Return a valid haptic device identifier on success or nil on error.
  ##
  ## See also: hapticOpen, 
  ## hapticClose


proc hapticClose*(haptic: PHaptic) {.cdecl, importc: "SDL_HapticClose", dynlib: LibName.}
  ## Closes a Haptic device previously opened with hapticOpen().
  ##
  ## ``haptic`` Haptic device to close.
 

proc hapticNumEffects*(haptic: PHaptic): int {.cdecl, importc: "SDL_HapticNumEffects", dynlib: LibName.}
  ## Returns the number of effects a haptic device can store.
  ##
  ## On some platforms this isn't fully supported, and therefore is an
  ## approximation.  Always check to see if your created effect was actually
  ## created and do not rely solely on hapticNumEffects().
  ##
  ## ``haptic`` The haptic device to query effect max.
  ##
  ## Return the number of effects the haptic device can store or -1 on error.
  ##
  ## See also: hapticNumEffectsPlaying, 
  ## hapticQuery


proc hapticNumEffectsPlaying*(haptic: PHaptic): int {.cdecl, importc: "SDL_HapticNumEffectsPlaying", dynlib: LibName.}
  ## Returns the number of effects a haptic device can play at the same time.
  ##
  ## This is not supported on all platforms, but will always return a value.
  ## Added here for the sake of completeness.
  ##
  ## ``haptic`` The haptic device to query maximum playing effects.
  ##
  ## Return the number of effects the haptic device can play at the same time
  ## or -1 on error.
  ##
  ## See also: hapticNumEffects, 
  ## hapticQuery


proc hapticQuery*(haptic: PHaptic): int {.cdecl, importc: "SDL_HapticQuery", dynlib: LibName.}
  ## Gets the haptic devices supported features in bitwise matter.
  ##
  ## Example:
  ##
  ##
  ## if hapticQueryEffects(haptic) and HAPTIC_CONSTANT:
  ##
  ##   echo("We have constant haptic effect!")
  ##
  ##
  ## ``haptic`` The haptic device to query.
  ##
  ## Return haptic features in bitwise manner (OR'd).
  ##
  ## See alsO: hapticNumEffects, 
  ## hapticEffectSupported


proc hapticNumAxes*(haptic: PHaptic): int {.cdecl, importc: "SDL_HapticNumAxes", dynlib: LibName.}
  ## Gets the number of haptic axes the device has.
  ##
  ## See also: THapticDirection


proc hapticEffectSupported*(haptic: PHaptic,
    effect: PHapticEffect): int {.cdecl, importc: "SDL_HapticEffectSupported", dynlib: LibName.}
  ## Checks to see if effect is supported by haptic.
  ##
  ## ``haptic`` Haptic device to check on.
  ##
  ## ``effect`` Effect to check to see if it is supported.
  ##
  ## Return TRUE if effect is supported, FALSE if it isn't or -1 on error.
  ##
  ## See also: hapticQuery, 
  ## hapticNewEffect


proc hapticNewEffect*(haptic: PHaptic,
    effect: PHapticEffect): int {.cdecl, importc: "SDL_HapticNewEffect", dynlib: LibName.}
  ## Creates a new haptic effect on the device.
  ##
  ## ``haptic`` Haptic device to create the effect on.
  ##
  ## ``effect`` Properties of the effect to create.
  ##
  ## Return The id of the effect on success or -1 on error.
  ##
  ## See also: hapticUpdateEffect, 
  ## hapticRunEffect, 
  ## hapticDestroyEffect


proc hapticUpdateEffect*(haptic: PHaptic,
    effect: int, data: PHapticEffect): int {.cdecl, importc: "SDL_HapticUpdateEffect", dynlib: LibName.}
  ## Updates the properties of an effect.
  ##
  ## Can be used dynamically, although behaviour when dynamically changing
  ## direction may be strange.  Specifically the effect may reupload itself
  ## and start playing from the start.  You cannot change the type either when
  ## running hapticUpdateEffect().
  ##
  ## ``haptic`` Haptic device that has the effect.
  ##
  ## ``effect`` Effect to update.
  ##
  ## ``data`` New effect properties to use.
  ##
  ## Return the id of the effect on success or -1 on error.
  ##
  ## See also: hapticNewEffect, 
  ## hapticRunEffect, 
  ## hapticDestroyEffect


proc hapticRunEffect*(haptic: PHaptic,
    effect: int, iterations: Uint32): int {.cdecl, importc: "SDL_HapticRunEffect", dynlib: LibName.}
  ## Runs the haptic effect on its associated haptic device.
  ##
  ## If iterations are HAPTIC_INFINITY, it'll run the effect over and over
  ## repeating the envelope (attack and fade) every time.  If you only want the
  ## effect to last forever, set HAPTIC_INFINITY in the effect's length
  ## parameter.
  ##
  ## ``haptic`` Haptic device to run the effect on.
  ##
  ## ``effect`` Identifier of the haptic effect to run.
  ##
  ## ``iterations`` Number of iterations to run the effect. Use
  ## HAPTIC_INFINITY for infinity.
  ##
  ## Return 0 on success or -1 on error.
  ##
  ## See also: hapticStopEffect, 
  ## hapticDestroyEffect, 
  ## hapticGetEffectStatus


proc hapticStopEffect*(haptic: PHaptic,
    effect: int): int {.cdecl, importc: "SDL_HapticStopEffect", dynlib: LibName.}
  ## Stops the haptic effect on its associated haptic device.
  ##
  ## ``haptic`` Haptic device to stop the effect on.
  ##
  ## ``effect`` Identifier of the effect to stop.
  ##
  ## Return 0 on success or -1 on error.
  ##
  ## See also: hapticRunEffect, 
  ## hapticDestroyEffect


proc hapticDestroyEffect*(haptic: PHaptic,
    effect: int) {.cdecl, importc: "SDL_HapticDestroyEffect", dynlib: LibName.}
  ## Destroys a haptic effect on the device.
  ##
  ## This will stop the effect if it's running.  Effects are automatically
  ## destroyed when the device is closed.
  ##
  ## ``haptic`` Device to destroy the effect on.
  ##
  ## ``effect`` Identifier of the effect to destroy.
  ##
  ## See also: hapticNewEffect

proc hapticGetEffectStatus*(haptic: PHaptic,
    effect: int): int {.cdecl, importc: "SDL_HapticGetEffectStatus", dynlib: LibName.}
  ## Gets the status of the current effect on the haptic device.
  ##
  ## Device must support the HAPTIC_STATUS feature.
  ##
  ## ``haptic`` Haptic device to query the effect status on.
  ##
  ## ``effect`` Identifier of the effect to query its status.
  ##
  ## Return 0 if it isn't playing, HAPTIC_PLAYING if it is playing
  ## or -1 on error.
  ##
  ## See also: hapticRunEffect, 
  ## hapticStopEffect


proc hapticSetGain*(haptic: PHaptic, gain: int): int {.cdecl, importc: "SDL_HapticSetGain", dynlib: LibName.}
  ## Sets the global gain of the device.
  ##
  ## Device must support the HAPTIC_GAIN feature.
  ##
  ## The user may specify the maximum gain by setting the environment variable
  ## HAPTIC_GAIN_MAX which should be between 0 and 100. All calls to
  ## hapticSetGain() will scale linearly using HAPTIC_GAIN_MAX as the maximum.
  ##
  ## ``haptic`` Haptic device to set the gain on.
  ##
  ## ``gain`` Value to set the gain to, should be between 0 and 100.
  ##
  ## Return 0 on success or -1 on error.
  ##
  ## See also: hapticQuery


proc hapticSetAutocenter*(haptic: PHaptic,
    autocenter: int): int {.cdecl, importc: "SDL_HapticSetAutocenter", dynlib: LibName.}
  ## Sets the global autocenter of the device.
  ##
  ## Autocenter should be between 0 and 100.  Setting it to 0 will disable
  ## autocentering.
  ##
  ## Device must support the HAPTIC_AUTOCENTER feature.
  ##
  ## ``haptic`` Haptic device to set autocentering on.
  ##
  ## ``autocenter`` Value to set autocenter to, 0 disables autocentering.
  ##
  ## Return 0 on success or -1 on error.
  ##
  ## See also: hapticQuery


proc hapticPause*(haptic: PHaptic): int {.cdecl, importc: "SDL_HapticPause", dynlib: LibName.}
  ## Pauses a haptic device.
  ##
  ## Device must support the HAPTIC_CAN_PAUSE feature. Call
  ## hapticUnpause() to resume playback.
  ##
  ## Do not modify the effects nor add new ones while the device is paused.
  ## That can cause all sorts of weird errors.
  ##
  ## ``haptic`` Haptic device to pause.
  ##
  ## Return 0 on success or -1 on error.
  ##
  ## See also: hapticUnpause


proc hapticUnpause*(haptic: PHaptic): int {.cdecl, importc: "SDL_HapticUnpause", dynlib: LibName.}
  ## Unpauses a haptic device.
  ##
  ## Call to unpause after hapticPause().
  ##
  ## ``haptic`` Haptic device to pause.
  ##
  ## Return 0 on success or -1 on error.
  ##
  ## See also: hapticPause


proc hapticStopAll*(haptic: PHaptic): int {.cdecl, importc: "SDL_HapticStopAll", dynlib: LibName.}
  ## Stops all the currently playing effects on a haptic device.
  ##
  ## ``haptic`` Haptic device to stop.
  ##
  ## Return 0 on success or -1 on error.


proc hapticRumbleSupported*(haptic: PHaptic): int {.cdecl, importc: "SDL_HapticRumbleSupported", dynlib: LibName.}
  ## Checks to see if rumble is supported on a haptic device..
  ##
  ## ``haptic`` Haptic device to check to see if it supports rumble.
  ## Return TRUE if effect is supported, FALSE if it isn't or -1 on error.
  ##
  ## See also: hapticRumbleInit, 
  ## hapticRumblePlay, 
  ## hapticRumbleStop


proc hapticRumbleInit*(haptic: PHaptic): int {.cdecl, importc: "SDL_HapticRumbleInit", dynlib: LibName.}
  ## Initializes the haptic device for simple rumble playback.
  ##
  ## ``haptic`` Haptic device to initialize for simple rumble playback.
  ##
  ## Return 0 on success or -1 on error.
  ##
  ## See also: hapticOpen, 
  ## hapticRumbleSupported, 
  ## hapticRumblePlay, 
  ## hapticRumbleStop


proc hapticRumblePlay*(haptic: PHaptic, strength: cfloat, length: Uint32): int {.cdecl, importc: "SDL_HapticRumblePlay", dynlib: LibName.}
  ## Runs simple rumble on a haptic device
  ##
  ## ``haptic`` Haptic device to play rumble effect on.
  ##
  ## ``strength`` Strength of the rumble to play as a 0-1 float value.
  ##
  ## ``length`` Length of the rumble to play in milliseconds.
  ##
  ## Return 0 on success or -1 on error.
  ##
  ## See also: hapticRumbleSupported, 
  ## hapticRumbleInit, 
  ## hapticRumbleStop


proc hapticRumbleStop*(haptic: PHaptic): int {.cdecl, importc: "SDL_HapticRumbleStop", dynlib: LibName.}
  ## Stops the simple rumble on a haptic device.
  ##
  ## ``haptic`` Haptic to stop the rumble on.
  ##
  ## Return 0 on success or -1 on error.
  ##
  ## See also: hapticRumbleSupported, 
  ## hapticRumbleInit, 
  ## hapticRumblePlay

