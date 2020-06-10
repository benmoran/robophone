// Use with https://makecode.microbit.org/#editor in script mode
// Download the resulting .hex file and flash it to the microbit


bluetooth.onBluetoothConnected(function () {
    basic.showIcon(IconNames.Happy)
})
bluetooth.onBluetoothDisconnected(function () {
    pins.analogWritePin(AnalogPin.P0, 0)
    pins.analogWritePin(AnalogPin.P1, 0)
    basic.showLeds(`
        # . . . #
        . # . # .
        . . # . .
        . # . # .
        # . . . #
        `)
})

bluetooth.startIOPinService()
bluetooth.startTemperatureService()
bluetooth.startMagnetometerService()
bluetooth.startAccelerometerService()
basic.showLeds(`
    # . # . #
    # . . . #
    . # # # .
    # . . . #
    # . # . #
    `)




// For testing
input.onButtonPressed(Button.A, function () {
    pins.analogWritePin(AnalogPin.P0, 0)
    pins.analogSetPeriod(AnalogPin.P0, 20000)
    for (let index = 0; index <= 103; index++) {
        pins.analogWritePin(AnalogPin.P0, index + 25)
        basic.pause(100)
    }
})
input.onButtonPressed(Button.B, function () {
    for (let index = 0; index <= 18; index++) {
        pins.servoWritePin(AnalogPin.P2, 10 * index)
        basic.pause(500)
    }
})
